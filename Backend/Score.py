
import re

def extract_number(text):
    if not text or "Not specified" in text:
        return None
    match = re.search(r"\d+(\.\d+)?", text)
    return float(match.group()) if match else None


def calculate_fairness_score(sla_data):
    score = 0
    reasons = []

    # Interest Rate (30)
    apr = extract_number(sla_data.get("interest_rate_apr", {}).get("value"))
    if apr is None:
        score += 10
        reasons.append("Interest rate not specified")
    elif apr <= 7:
        score += 30
        reasons.append("Low interest rate")
    elif apr <= 10:
        score += 25
        reasons.append("Moderate interest rate")
    elif apr <= 14:
        score += 15
        reasons.append("High interest rate")
    else:
        score += 5
        reasons.append("Very high interest rate")

    # Penalties (20)
    penalty = sla_data.get("late_fee_penalty", {}).get("value")
    if not penalty or "Not specified" in penalty:
        score += 8
        reasons.append("Penalty terms not specified")
    elif "______" in penalty:
        score += 12
        reasons.append("Penalty unclear")
    else:
        score += 20
        reasons.append("Penalty clearly defined")

    # Flexibility (20)
    termination = sla_data.get("termination_clause", {}).get("value")
    if not termination or "Not specified" in termination:
        score += 8
        reasons.append("Termination terms not specified")
    elif "allowed" in termination.lower():
        score += 20
        reasons.append("Early termination allowed")
    else:
        score += 12
        reasons.append("Restricted termination")

    # Transparency (15)
    unclear = sum(
        1 for v in sla_data.values()
        if v.get("value") in [None, "Not specified"] or "______" in str(v.get("value"))
    )

    if unclear == 0:
        score += 15
        reasons.append("High transparency")
    elif unclear <= 2:
        score += 8
        reasons.append("Moderate transparency")
    else:
        score += 4
        reasons.append("Low transparency")

    # Down Payment (15)
    dp = extract_number(sla_data.get("down_payment", {}).get("value"))
    if dp is None:
        score += 8
        reasons.append("Down payment not specified")
    elif dp <= 20:
        score += 15
        reasons.append("Low down payment")
    elif dp <= 40:
        score += 10
        reasons.append("Moderate down payment")
    else:
        score += 5
        reasons.append("High down payment")

    score = min(score, 100)

    level = (
        "Fair" if score >= 80 else
        "Acceptable" if score >= 60 else
        "Risky" if score >= 40 else
        "Unfair"
    )

    return {
        "fairness_score": score,
        "fairness_level": level,
        "reasons": reasons
    }

