
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import json
import uuid
import google.generativeai as genai
from functools import lru_cache

# ===== YOUR EXISTING MODULES =====
from OCR import ocr_pdf
from llm_engine import analyze_contract
from vehicle_details import extract_vin_and_vehicle_details

app = FastAPI(title="Auto Loan Contract Analyzer")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== STORAGE =====
BASE_DIR = "runtime_data"
OCR_TEXT_FILE = os.path.join(BASE_DIR, "latest_ocr.txt")

os.makedirs(BASE_DIR, exist_ok=True)

GEMINI_API_KEY = "AIzaSyBMmtdRoLfb80ITwrwWLvdRj9NBvibgmAA"  # Get from https://aistudio.google.com/app/apikey
genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel('gemini-2.5-flash')

# Request models
class DealerMessageRequest(BaseModel):
    conversation_id: str
    user_message: str
    contract_context: dict
    negotiation_context: dict

class NegotiationGuidanceRequest(BaseModel):
    user_message: str
    dealer_response: str
    contract_context: dict
    negotiation_context: dict


class AnalyzeRequest(BaseModel):
    text: str
    vin: str = ""

class ChatRequest(BaseModel):
    user_message: str
    contract_context: str

@lru_cache(maxsize=100)
def cached_vehicle_lookup(vin: str):
    """Cache VIN lookups to avoid repeated API calls"""
    return extract_vin_and_vehicle_details(f"VIN: {vin}")


@app.post("/dealer/message")
async def simulate_dealer_response(request: DealerMessageRequest):
    """Simulate intelligent dealer responses"""
    try:
        user_msg = request.user_message.lower()
        neg_ctx = request.negotiation_context
        
        # Extract negotiation state
        original_monthly = neg_ctx.get('originalMonthly', 50000)
        current_monthly = neg_ctx.get('currentMonthly', original_monthly)
        round_num = neg_ctx.get('negotiationRound', 0)
        
        # Dealer AI logic
        if 'reduce' in user_msg or 'lower' in user_msg or 'discount' in user_msg:
            # User wants reduction
            if round_num == 0:
                # First negotiation - offer small reduction
                new_offer = current_monthly * 0.95  # 5% reduction
                response = f"I appreciate your interest. I can reduce the monthly payment to ₹{new_offer:.0f}. This is a competitive rate considering the vehicle condition and market value."
            elif round_num == 1:
                # Second round - smaller reduction
                new_offer = current_monthly * 0.97  # 3% more reduction
                response = f"Let me check with my manager... I can go down to ₹{new_offer:.0f}, but that's my best offer."
            else:
                # Final offer
                response = f"₹{current_monthly:.0f} is truly our final offer. This is below market rate already. Shall we proceed with this?"
        
        elif 'interest' in user_msg or 'rate' in user_msg:
            response = "Our standard interest rate is 8.5% APR. For customers with excellent credit (750+), we can offer 7.5%. What's your credit score range?"
        
        elif 'fee' in user_msg or 'charge' in user_msg:
            response = "The processing fee of ₹12,000 covers documentation and registration. I can waive ₹3,000 if you commit today."
        
        elif 'term' in user_msg or 'month' in user_msg or 'period' in user_msg:
            response = "We offer 24, 36, and 48-month lease terms. Longer terms mean lower monthly payments. Which works better for your budget?"
        
        elif any(word in user_msg for word in ['accept', 'agree', 'deal', 'yes']):
            response = "Excellent! I'll prepare the updated contract with our agreed terms. I'll email you the documents within 24 hours. Is there anything else you'd like to clarify?"
        
        elif any(word in user_msg for word in ['no', 'reject', 'not interested']):
            response = "I understand. If you change your mind, this offer is valid for 7 days. Feel free to reach out if you have questions."
        
        else:
            # Generic/AI-powered response
            prompt = f"""You are a professional car lease dealer negotiating with a customer.

Customer said: "{request.user_message}"

Contract context: Monthly payment ₹{current_monthly}, Round {round_num}

Respond professionally, showing willingness to negotiate within 5-10% range. Be realistic and helpful. Keep response under 50 words."""
            
            ai_response = gemini_model.generate_content(prompt)
            response = ai_response.text
        
        return {
            "dealer_response": response,
            "negotiation_round": round_num + 1
        }
    
    except Exception as e:
        return {
            "dealer_response": "Thank you for your message. Let me review the details and get back to you shortly.",
            "error": str(e)
        }

@app.post("/negotiation/guidance")
async def get_negotiation_guidance(request: NegotiationGuidanceRequest):
    """Real-time AI negotiation coaching"""
    try:
        prompt = f"""You are an expert car lease negotiation coach. Analyze this conversation and provide BRIEF tactical guidance (max 30 words).

USER SAID: "{request.user_message}"
DEALER RESPONDED: "{request.dealer_response}"

Provide ONE specific action the user should take next. Be concise and tactical."""

        response = gemini_model.generate_content(prompt)
        guidance = response.text.strip()
        
        # Add emoji based on sentiment
        if any(word in request.dealer_response.lower() for word in ['reduce', 'lower', 'can offer']):
            guidance = f" {guidance}"
        elif any(word in request.dealer_response.lower() for word in ['final', 'best', 'cannot']):
            guidance = f" {guidance}"
        else:
            guidance = f" {guidance}"
        
        return {"ai_guidance": guidance}
    
    except Exception as e:
        # Fallback guidance
        return {
            "ai_guidance": "💬 Keep negotiating. Ask what flexibility they have on terms."
        }


# ======================================================
# 1️⃣ OCR ENDPOINT – UPLOAD ONCE, RETURN TEXT
# ======================================================
@app.post("/ocr")
async def extract_ocr_text(file: UploadFile = File(...)):

    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files allowed")

    temp_pdf = f"temp_{uuid.uuid4().hex}.pdf"

    # Save uploaded PDF
    with open(temp_pdf, "wb") as f:
        f.write(await file.read())

    try:
        ocr_text = ocr_pdf(temp_pdf)
    finally:
        os.remove(temp_pdf)

    # Persist OCR text for next endpoint
    with open(OCR_TEXT_FILE, "w", encoding="utf-8") as f:
        f.write(ocr_text)

    return {
        "message": "OCR completed successfully",
        "ocr_text": ocr_text
    }


# ======================================================
# 2️⃣ ANALYSIS ENDPOINT – NO INPUT
# ======================================================
@app.get("/analyze")
async def analyze_contract_from_ocr():

    if not os.path.exists(OCR_TEXT_FILE):
        raise HTTPException(
            status_code=400,
            detail="OCR not performed yet. Call /ocr first."
        )

    with open(OCR_TEXT_FILE, "r", encoding="utf-8") as f:
        contract_text = f.read()

    # ---- SLA + LLM + FAIRNESS SCORE ----
    sla_analysis = analyze_contract(contract_text)

    # ---- VIN + VEHICLE DETAILS ----
    vehicle_info = extract_vin_and_vehicle_details(contract_text)

    return {
        "vehicle_details": vehicle_info,
        "sla_analysis": sla_analysis,
        "fairness_score": sla_analysis.get("fairness_score", "N/A")
    }

@app.post("/chat")
async def ai_chatbot(request: ChatRequest):
    """
    AI-powered negotiation assistant
    """
    try:
        # Parse contract context
        contract_data = json.loads(request.contract_context)
        
        # Build context-aware prompt
        prompt = f"""You are a professional car lease negotiation assistant. 

CONTRACT ANALYSIS:
- Fairness Score: {contract_data.get('fairness_score', 'N/A')}
- Key Terms: {json.dumps(contract_data.get('sla_analysis', {}), indent=2)}

USER QUERY: {request.user_message}

Provide specific, actionable negotiation advice based on the contract details above.
Be concise (max 200 words), friendly, and focus on practical strategies.
Use bullet points when listing multiple items.
"""
        
        # Call Gemini API
        response = gemini_model.generate_content(prompt)
        
        return {
            "response": response.text,
            "model": "gemini-2.5-flash"
        }
    
    except Exception as e:
        # Fallback response if AI fails
        return {
            "response": f"I can help with:\n• Interest rate negotiation\n• Fee reductions\n• Contract clause clarifications\n• Early termination options\n\nPlease rephrase your question.",
            "error": str(e)
        }

# Health check
@app.get("/")
async def root():
    return {"message": "Car Lease Analyzer API", "status": "running"}

