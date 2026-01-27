
import os
import json
import re
import google.generativeai as genai
from typing import Dict, Any

from Score import calculate_fairness_score

# =========================
# ENV + GEMINI CONFIG
# =========================

genai.configure(api_key="AIzaSyDp4riZaHmuWoDTH2a85UeZGaM04ePYiIQ")

model = genai.GenerativeModel("gemini-2.5-flash")


# =========================
# 1. SLA EXTRACTION
# =========================

def extract_sla_fields(ocr_text: str) -> Dict[str, Any]:

    prompt = f"""
You are an expert auto-loan contract analyst.

Extract SLA fields from the contract text below.

CONTRACT TEXT:
\"\"\"
{ocr_text}
\"\"\"

Return ONLY valid JSON in this EXACT format:

{{
  "interest_rate_apr": {{ "value": string|null, "confidence": number }},
  "late_fee_penalty": {{ "value": string|null, "confidence": number }},
  "termination_clause": {{ "value": string|null, "confidence": number }},
  "down_payment": {{ "value": string|null, "confidence": number }}
  "emi_amount": {{ "value": number|null, "confidence": number }},
  "insurance_mandatory": {{ "value": boolean|null, "confidence": number }},
  "processing_fees": {{ "value": string|null, "confidence": number }}

}}

Rules:
- confidence between 0 and 1
- if not found → value = null, confidence = 0.0
- no explanations
"""

    response = model.generate_content(prompt)
    return _safe_json(response.text)


# =========================
# 2. LLM CONTRACT ANALYSIS
# =========================

def llm_contract_analysis(sla_data: Dict[str, Any],
                          fairness_result: Dict[str, Any]) -> Dict[str, Any]:

    prompt = f"""
You are a loan contract risk analyst.

SLA DATA:
{json.dumps(sla_data, indent=2 , ensure_ascii=False)}

FAIRNESS SCORE:
Score: {fairness_result["fairness_score"]}
Level: {fairness_result["fairness_level"]}
Reasons:
{json.dumps(fairness_result["reasons"], indent=2)}

Tasks:
1. Explain the contract in simple language
2. Highlight risky clauses
3. Suggest negotiation points
4. Explain the fairness score

Return ONLY valid JSON with keys:
- summary
- risk_flags
- negotiation_points
- fairness_explanation
"""

    response = model.generate_content(prompt)
    return _safe_json(response.text)


# =========================
# 3. FULL PIPELINE
# =========================

def analyze_contract(ocr_text: str) -> Dict[str, Any]:
    """
    Entry point used by FastAPI
    """

    # Step 1: SLA extraction
    sla_data = extract_sla_fields(ocr_text)

    # Step 2: Fairness score (USING YOUR EXISTING LOGIC)
    fairness_result = calculate_fairness_score(sla_data)

    # Step 3: LLM explanation
    llm_analysis = llm_contract_analysis(sla_data, fairness_result)

    return {
        "sla_extraction": sla_data,
        "fairness_score": fairness_result,
        "contract_analysis": llm_analysis
    }


# =========================
# 4. SAFE JSON PARSER
# =========================

def _safe_json(text: str) -> Dict[str, Any]:
    try:
        cleaned = re.sub(r"```json|```", "", text).strip()
        return json.loads(cleaned)
    except Exception as e:
        return {
            "error": "Invalid JSON from Gemini",
            "raw_output": text
        }


# =========================
# LOCAL TEST
# =========================

if __name__ == "__main__":
    with open("test_output.txt", "r", encoding="utf-8") as f:
        ocr_text = f.read()

    result = analyze_contract(ocr_text)

    with open("llm_result.json", "w", encoding="utf-8") as f:
        json.dump(result, f, indent=4, ensure_ascii=False)

    print("SLA + Fairness + LLM analysis completed")

