
from pdf2image import convert_from_path
import pytesseract
import re

def ocr_pdf(pdf_path):
    pages = convert_from_path(pdf_path, dpi=300)
    full_text = "-----AUTO LOAN CONTRACT-----\n\n"

    for i, page in enumerate(pages):
        page_text = pytesseract.image_to_string(page)

        page_text = re.sub(r'[_]{3,}', '[VALUE]', page_text)
        page_text = re.sub(r'\.\.\.+', '[VALUE]', page_text)

        page_text = re.sub(r'[ \t]+', " ", page_text)

        full_text += f"[Page {i+1}]\n{page_text}\n\n"

    return full_text

if __name__ == "__main__":
    pdf_path = "Sample_contract.pdf"  
    text = ocr_pdf(pdf_path)

    with open("test_output.txt", "w", encoding="utf-8") as f:
        f.write(text)

    print("OCR completed. Output saved as test_output.txt")
