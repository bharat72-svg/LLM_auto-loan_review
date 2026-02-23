
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import json
import uuid
import google.generativeai as genai
from functools import lru_cache
import asyncio
from typing import Optional

from price_engine import  get_source_1, get_source_2, get_recommendation

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

GEMINI_API_KEY = "AIzaSyCBBQmebhKnCHODW6ZXMtjiEbf0PK811y8"  # Get from https://aistudio.google.com/app/apikey
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
    return extract_vin_and_vehicle_details(f"VIN: {vin}")


@app.post("/dealer/message")
async def simulate_dealer_response(request: DealerMessageRequest):
    """Simulate intelligent dealer responses using REAL contract data"""
    try:
        user_msg = request.user_message.lower()
        contract_ctx = request.contract_context
        neg_ctx = request.negotiation_context
        
        # ✅ EXTRACT REAL CONTRACT VALUES
        monthly_payment = _extract_numeric(contract_ctx.get('monthly_payment', '25000'))
        interest_rate = _extract_numeric(contract_ctx.get('interest_rate', '8.5'))
        down_payment = _extract_numeric(contract_ctx.get('down_payment', '100000'))
        processing_fees = _extract_numeric(contract_ctx.get('processing_fees', '12000'))
        lease_term = _extract_numeric(contract_ctx.get('lease_term', '36'))
        
        vehicle_name = f"{contract_ctx.get('vehicle_make', 'the vehicle')} {contract_ctx.get('vehicle_model', '')}"
        
        # Get negotiation state
        original_monthly = neg_ctx.get('originalMonthly', monthly_payment)
        current_monthly = neg_ctx.get('currentMonthly', monthly_payment)
        round_num = neg_ctx.get('negotiationRound', 0)
        
        # ============================================
        # DEALER AI LOGIC (uses contract values)
        # ============================================
        
        if 'reduce' in user_msg or 'lower' in user_msg or 'discount' in user_msg:
            # User wants reduction
            if round_num == 0:
                # First negotiation - offer 5% reduction
                new_offer = current_monthly * 0.95
                response = f"I understand you'd like a better rate on the {vehicle_name}. Looking at your profile, I can reduce the monthly payment from ₹{current_monthly:.0f} to ₹{new_offer:.0f}. This is already a competitive rate for this vehicle."
            elif round_num == 1:
                # Second round - smaller reduction (3%)
                new_offer = current_monthly * 0.97
                response = f"I spoke with my manager. We can go down to ₹{new_offer:.0f} per month, but that's really pushing our margins on the {vehicle_name}."
            else:
                # Final offer - firm stance
                response = f"₹{current_monthly:.0f} per month is truly our best offer for the {vehicle_name}. At this rate, you're getting an excellent deal considering the {lease_term}-month term and included benefits."
        
        elif 'interest' in user_msg or 'rate' in user_msg or 'apr' in user_msg:
            response = f"The current interest rate on this {vehicle_name} is {interest_rate}% APR. For customers with excellent credit scores (750+), we can consider reducing it to {interest_rate - 0.5}%. What's your credit score range?"
        
        elif 'fee' in user_msg or 'processing' in user_msg:
            waived_amount = processing_fees * 0.3  # Waive 30%
            response = f"The processing fee of ₹{processing_fees:.0f} covers documentation and registration. However, if you commit today, I can waive ₹{waived_amount:.0f}, bringing it down to ₹{processing_fees - waived_amount:.0f}."
        
        elif 'down payment' in user_msg or 'advance' in user_msg:
            reduced_down = down_payment * 0.8  # 20% reduction
            response = f"The current down payment is ₹{down_payment:.0f}. If that's too high, we can reduce it to ₹{reduced_down:.0f}, but the monthly payment would increase to ₹{monthly_payment * 1.15:.0f}. Would you prefer that?"
        
        elif 'term' in user_msg or 'month' in user_msg or 'period' in user_msg:
            shorter_term = int(lease_term * 0.75)
            longer_term = int(lease_term * 1.25)
            response = f"The contract term is {int(lease_term)} months. We can offer {shorter_term} months (higher monthly payment of ₹{monthly_payment * 1.2:.0f}) or {longer_term} months (lower monthly payment of ₹{monthly_payment * 0.85:.0f}). Which works better?"
        
        elif any(word in user_msg for word in ['accept', 'agree', 'deal', 'yes', 'ok']):
            response = f"Excellent! I'm thrilled we could work this out for the {vehicle_name}. I'll prepare the updated contract with:\n\n• Monthly Payment: ₹{current_monthly:.0f}\n• Interest Rate: {interest_rate}%\n• Term: {int(lease_term)} months\n\nYou'll receive the documents within 24 hours. Welcome to our family!"
        
        elif any(word in user_msg for word in ['no', 'reject', 'expensive', 'high']):
            response = f"I understand your concerns. The {vehicle_name} is a quality vehicle, and our terms are competitive. What specific aspect would make this work for your budget? Monthly payment, down payment, or lease term?"
        
        else:
            # Use AI for complex queries with contract context
            prompt = f"""You are a professional car lease dealer negotiating for a {vehicle_name}.

Contract details:
- Monthly Payment: ₹{monthly_payment}
- Interest Rate: {interest_rate}%
- Down Payment: ₹{down_payment}
- Lease Term: {lease_term} months
- Negotiation Round: {round_num}

Customer said: "{request.user_message}"

Respond professionally in 40 words or less. Show willingness to negotiate within 5-10% range. Reference the specific vehicle and terms."""
            
            ai_response = gemini_model.generate_content(prompt)
            response = ai_response.text.strip()
        
        return {
            "dealer_response": response,
            "negotiation_round": round_num + 1
        }
    
    except Exception as e:
        return {
            "dealer_response": "Thank you for your message. Let me review the contract details and get back to you shortly with the best possible terms.",
            "error": str(e)
        }

# ============================================
# HELPER FUNCTION
# ============================================

def _extract_numeric(value: str) -> float:
    """Extract numeric value from string like '₹3,00,000' or '8.5% per annum'"""
    if isinstance(value, (int, float)):
        return float(value)
    
    # Remove currency symbols, commas, and text
    cleaned = str(value).replace('₹', '').replace(',', '').replace('%', '').replace('per annum', '').strip()
    
    # Extract first number
    import re
    match = re.search(r'[\d.]+', cleaned)
    if match:
        return float(match.group(0))
    
    return 0.0


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



class PriceRequest(BaseModel):
    make: str
    model: str
    year: int
    contract_monthly: int  # Current monthly payment in contract

@app.post("/api/price-compare")
async def compare_price(req: PriceRequest):
    """
    Simple price comparison endpoint
    Compares contract price with 2 market sources
    """
    try:
        print("\n" + "="*50)
        print(f" PRICE COMPARISON REQUEST")
        print(f"Vehicle: {req.year} {req.make} {req.model}")
        print(f"Contract Monthly: ₹{req.contract_monthly:,}")
        print("="*50)
        
        # Validate inputs
        if not req.make or not req.make.strip():
            raise HTTPException(
                status_code=400, 
                detail="Vehicle make is required"
            )
        
        if req.year <= 0 or req.year > 2026:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid year: {req.year}. Must be between 1990-2026"
            )
        
        if req.contract_monthly <= 0:
            raise HTTPException(
                status_code=400, 
                detail="Contract monthly amount must be greater than 0"
            )
        
        # Get prices from 2 sources
        source1 = get_source_1(req.make, req.model, req.year)
        source2 = get_source_2(req.make, req.model, req.year)
        
        # Get recommendation
        recommendation = get_recommendation(
            source1["monthly_emi"],
            source2["monthly_emi"],
            req.contract_monthly
        )
        
        response = {
            "vehicle": {
                "make": req.make,
                "model": req.model,
                "year": req.year
            },
            "sources": [source1, source2],
            "recommendation": recommendation
        }
        
        print(f" Response generated successfully\n")
        return response
    
    except HTTPException as he:
        print(f" Validation Error: {he.detail}")
        raise he
    
    except Exception as e:
        print(f" Server Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to calculate price: {str(e)}"
        )



# Health check
@app.get("/")
async def root():
    return {"message": "Car Lease Analyzer API", "status": "running"}

