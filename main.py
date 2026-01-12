
from fastapi import FastAPI, UploadFile, File
import tempfile

from OCR import ocr_pdf
from SLA import extract_sla
from LLM_engine import analyze_contract

app = FastAPI(title="Auto Loan Contract Analysis")



@app.post("/extract-sla")
async def extract_sla_api(file: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
        tmp.write(await file.read())
        pdf_path = tmp.name

    text = ocr_pdf(pdf_path)
    sla_data = extract_sla(text)

    return {"sla_data": sla_data}



@app.post("/analyze-contract")
async def analyze_contract_api(sla_data: dict):
    analysis = analyze_contract(sla_data)
    return {"analysis": analysis}