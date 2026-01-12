
from pdf2image import convert_from_path
import pytesseract

def ocr_pdf(pdf_path):
    pages = convert_from_path(pdf_path, dpi=300)
    text = ""

    for page in pages:
        text += pytesseract.image_to_string(page)

    return text
pdf_path = 'business-finance-lease-agreement_used-vehicle.pdf'
ocr_pdf(pdf_path)