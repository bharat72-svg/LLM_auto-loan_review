
import google.generativeai as genai
import json
import os


genai.configure(api_key="AIzaSyCyNy94CYMw5EydEZNDsEPh6ZAO_bGTFH4")

model = genai.GenerativeModel("gemini-2.5-flash")

def analyze_contract(sla_data):
    prompt = f"""
You are an auto loan and lease contract analysis assistant.

Given the extracted SLA terms below (in JSON format):

{json.dumps(sla_data, indent=3)}

Tasks:
1. Explain the contract in simple language.
2. Identify risky or unfavorable clauses.
3. Suggest negotiation points.
4. List the SLA terms.
5. Provide an overall contract fairness score (0–100).

If any field has confidence < 0.7, flag it for manual review.

Return ONLY valid JSON with keys:
- summary
- risk_flags
- negotiation_points
- fairness_score
"""

    response = model.generate_content(prompt)
    return response.text
