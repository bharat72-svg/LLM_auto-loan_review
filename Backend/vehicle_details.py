
import re
import requests
import json

# =========================
# VIN EXTRACTION
# =========================

VIN_REGEX = r"\b[A-HJ-NPR-Z0-9]{17}\b"

def extract_vin(contract_text: str):
    """
    Extract VIN from OCR-extracted contract text
    """
    if not contract_text:
        return None

    matches = re.findall(VIN_REGEX, contract_text.upper())
    return matches[0] if matches else None


# =========================
# VEHICLE DETAILS
# =========================

def get_vehicle_details(vin: str):
    """
    Fetch vehicle details using NHTSA VIN API
    """
    if not vin:
        return None

    url = f"https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/{vin}?format=json"
    response = requests.get(url, timeout=10)

    if response.status_code != 200:
        return None

    data = response.json()

    required_fields = [
        "Make",
        "Model",
        "Model Year",
        "Body Class",
        "Fuel Type - Primary",
        "Manufacturer Name"
    ]

    vehicle_info = {}
    for item in data.get("Results", []):
        if item["Variable"] in required_fields and item["Value"]:
            vehicle_info[item["Variable"]] = item["Value"]

    return vehicle_info


# =========================
# MAIN FUNCTION (JSON OUTPUT)
# =========================

def extract_vin_and_vehicle_details(contract_text: str):
    """
    Extract VIN and vehicle details from contract text
    """
    vin = extract_vin(contract_text)
    vehicle_details = get_vehicle_details(vin)

    return {
        "vin": vin,
        "vehicle_details": vehicle_details
    }


# =========================
# TEST RUN (OPTIONAL)
# =========================
if __name__ == "__main__":
    with open("test_output.txt", "r", encoding="utf-8") as f:
        text = f.read()

    result = extract_vin_and_vehicle_details(text)

    with open("vehicle_details.json", "w", encoding="utf-8") as f:
        json.dump(result, f, indent=4)
        
print('vehicle-details saved')

    
