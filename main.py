
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
import json
import uuid

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
def analyze_contract_from_ocr():

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
        "sla_analysis": sla_analysis
    }

