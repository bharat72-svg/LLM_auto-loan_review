
import re

SLA_FIELDS = {
    "interest_rate_apr": ["interest rate", "apr"],
    "loan_term_months": ["loan term", "term", "duration"],
    "monthly_payment": ["monthly payment"],
    "down_payment": ["down payment"],
    "late_fee_penalty": ["late fee", "penalty"],
    "early_termination": ["early termination"],
    "mileage_limit": ["mileage", "miles per year"],
    "purchase_option": ["purchase option", "buyout"],
    "maintenance_responsibility": ["maintenance"],
    "warranty_insurance": ["warranty", "insurance"]
}

def extract_sla(text):
    sla_output = {}

    for field, keywords in SLA_FIELDS.items():
        found_value = None
        confidence = 0.0

        for kw in keywords:
            pattern = rf"{kw}.{{0,50}}"
            match = re.search(pattern, text, re.IGNORECASE)

            if match:
                found_value = match.group().strip()
                confidence = 0.9
                break

        if not found_value:
            for kw in keywords:
                if kw.lower() in text.lower():
                    found_value = "Mentioned but value unclear"
                    confidence = 0.6
                    break

        sla_output[field] = {
            "value": found_value,
            "confidence_score": confidence
        }

    return sla_output

