"""
Simple Price Estimation Engine
Automatically uses contract vehicle details
"""

import random


# Indian car base prices (2026)
BRAND_PRICES = {
    "maruti": 450000, "suzuki": 450000,
    "hyundai": 700000, "tata": 600000,
    "mahindra": 900000, "honda": 1000000,
    "toyota": 1100000, "kia": 800000,
    "renault": 500000, "nissan": 700000,
    "ford": 700000, "volkswagen": 1500000,
    "skoda": 1500000, "mg": 2000000,
    "default": 700000
}


def calculate_price(make: str, year: int) -> dict:
    """Calculate vehicle price based on make and year"""
    
    # Handle empty/invalid inputs
    if not make or year <= 0:
        print(f"⚠️ Invalid input: make='{make}', year={year}")
        return {
            "vehicle_price": 0,
            "min_price": 0,
            "max_price": 0
        }
    
    # Get base price for brand
    base_price = BRAND_PRICES.get(make.lower().strip(), BRAND_PRICES["default"])
    
    # Apply depreciation (15% per year)
    current_year = 2026
    age = current_year - year
    
    # Validate year (not too old, not future)
    if age < 0:
        age = 0  # Future car, no depreciation
    elif age > 15:
        age = 15  # Cap depreciation at 15 years
    
    # Apply depreciation
    for _ in range(age):
        base_price = int(base_price * 0.85)
    
    # Add random market variation (±5%)
    base_price = int(base_price * random.uniform(0.95, 1.05))
    
    # Ensure minimum price
    if base_price < 100000:
        base_price = 100000
    
    print(f"💰 Price for {make} {year}: ₹{base_price:,}")
    
    return {
        "vehicle_price": base_price,
        "min_price": int(base_price * 0.9),
        "max_price": int(base_price * 1.1)
    }


def calculate_emi(price: int) -> int:
    """Calculate monthly EMI (20% down, 36 months, 8.5% interest)"""
    
    if price <= 0:
        return 0
    
    principal = price * 0.8  # 80% loan amount
    months = 36
    rate = 8.5 / (12 * 100)  # Monthly interest rate
    
    # EMI formula
    emi = principal * rate * ((1 + rate) ** months) / (((1 + rate) ** months) - 1)
    
    return int(emi)


def get_source_1(make: str, model: str, year: int) -> dict:
    """Source 1: Indian Market Data"""
    
    pricing = calculate_price(make, year)
    monthly = calculate_emi(pricing["vehicle_price"])
    
    print(f"📊 Source 1 (Market): {make} {model} {year} → ₹{monthly:,}/month")
    
    return {
        "source": "Indian Market Data",
        "monthly_emi": monthly,
        "min_emi": calculate_emi(pricing["min_price"]),
        "max_emi": calculate_emi(pricing["max_price"])
    }


def get_source_2(make: str, model: str, year: int) -> dict:
    """Source 2: Dealer Network (5% higher)"""
    
    pricing = calculate_price(make, year)
    dealer_price = int(pricing["vehicle_price"] * 1.05)
    monthly = calculate_emi(dealer_price)
    
    print(f"📊 Source 2 (Dealer): {make} {model} {year} → ₹{monthly:,}/month")
    
    return {
        "source": "Dealer Network",
        "monthly_emi": monthly,
        "min_emi": calculate_emi(int(pricing["min_price"] * 1.05)),
        "max_emi": calculate_emi(int(pricing["max_price"] * 1.05))
    }


def get_recommendation(source1_emi: int, source2_emi: int, contract_emi: int) -> dict:
    """Generate price recommendation"""
    
    # Handle zero values
    if source1_emi == 0 and source2_emi == 0:
        return {
            "verdict": "ERROR",
            "market_average": 0,
            "recommended_emi": contract_emi,
            "your_contract": contract_emi,
            "potential_savings": 0,
            "message": "Unable to calculate market prices"
        }
    
    # Calculate market average
    market_avg = int((source1_emi + source2_emi) / 2)
    
    # Determine verdict
    if contract_emi > market_avg * 1.15:
        verdict = "HIGH"
        target = market_avg
        message = f"Your contract is {int((contract_emi/market_avg - 1)*100)}% above market. Negotiate for better terms!"
    elif contract_emi > market_avg * 1.05:
        verdict = "NEGOTIATE"
        target = market_avg
        message = "Your contract is slightly above market. Try negotiating down."
    elif contract_emi < market_avg * 0.85:
        verdict = "EXCELLENT"
        target = contract_emi
        message = f"Excellent! You're getting {int((1 - contract_emi/market_avg)*100)}% below market rate."
    else:
        verdict = "FAIR"
        target = contract_emi
        message = "Fair deal. Your monthly payment is within normal market range."
    
    savings = contract_emi - target
    
    print(f"✅ Verdict: {verdict} | Market: ₹{market_avg:,} | Contract: ₹{contract_emi:,} | Savings: ₹{savings:,}")
    
    return {
        "verdict": verdict,
        "market_average": market_avg,
        "recommended_emi": target,
        "your_contract": contract_emi,
        "potential_savings": savings,
        "message": message
    }
