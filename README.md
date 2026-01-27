🚗 Auto Loan Contract Analyzer & Fairness Assistant

An AI-powered system to analyze auto loan contracts, extract key SLA terms using OCR + LLMs, compute a contract fairness score, fetch vehicle details via VIN, and assist users with negotiation insights through an interactive frontend.

📌 Project Overview

Auto loan contracts are complex, lengthy, and difficult for borrowers to interpret.
This project aims to democratize contract understanding by automatically extracting important loan clauses, identifying risky terms, scoring contract fairness, and guiding users with AI-driven insights.

🎯 Key Objectives

Extract text from loan contracts using OCR

Identify and structure SLA parameters using LLMs

Compute a fairness score based on weighted rules

Fetch vehicle details using VIN lookup

Provide user-friendly frontend for interaction

Lay foundation for AI-based negotiation assistance

🧠 System Architecture
PDF Contract
     ↓
OCR Engine (Tesseract)
     ↓
LLM-based SLA Extraction (Gemini)
     ↓
Fairness Scoring Engine
     ↓
VIN Lookup (NHTSA API)
     ↓
FastAPI Backend
     ↓
Flutter Frontend

🛠️ Tech Stack
Backend

Python

FastAPI

Tesseract OCR

Google Gemini LLM

Regex + Rule-based Scoring

NHTSA VIN Decode API

Frontend

Flutter (Web)

HTTP API Integration

Material UI Components

📂 Project Structure
INFOSYS_CAR_LEASE_ASSISTANT/
│
├── backend/
│   ├── ocr.py
│   ├── llm_engine.py
│   ├── sla_extraction.py
│   ├── score.py
│   ├── vehicle_details.py
│   ├── main.py (FastAPI)
│
├── contract_frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│
├── sample_contract.pdf
├── README.md

🗓️ Week-wise Deliverables
✅ Week 1–2: Requirement Analysis & Design

Problem understanding

SLA identification from auto loan contracts

System architecture design

Scoring criteria definition

✅ Week 3: OCR & Text Extraction

Deliverables

PDF to image conversion

OCR-based text extraction

Noise cleanup and normalization

Output

Clean contract text extracted from PDF

✅ Week 4: SLA Extraction & Fairness Scoring (Backend Complete)

Tasks

LLM-based SLA extraction using Gemini

SLA fields:

[Interest rate

Loan amount

Tenure

Penalties

Termination clause

Down payment

Processing fees

Grace period]

Rule-based fairness score computation

VIN extraction and vehicle detail lookup

Backend API development using FastAPI

Endpoints

POST /ocr → Upload contract & extract text

GET /analyze → SLA, fairness score, vehicle details, LLM analysis

Output

Structured SLA JSON

Fairness score (0–100)

Contract risk explanation

Vehicle details

✅ Week 5: Frontend Development (Flutter)

Tasks

Flutter UI for contract upload

Progress indicator during OCR

Interactive cards for:

Vehicle details

SLA summary

Fairness score

LLM contract insights

Clean and responsive UI

Output

Working Flutter web app

User-friendly contract analyzer UI
