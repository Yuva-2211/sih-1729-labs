# NeuroVoice (SIH-1729)
### AI-Powered Parkinson's Disease Screening via Vocal Biomarkers & Quantum-Classical Machine Learning

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.2+-EE4C2C?logo=pytorch&logoColor=white)](https://pytorch.org)
[![PennyLane](https://img.shields.io/badge/PennyLane-Quantum_ML-brightgreen)](https://pennylane.ai)
[![Groq Llama 3](https://img.shields.io/badge/Groq-Llama_3-f55036)](https://groq.com)
[![SQLite](https://img.shields.io/badge/SQLite-Local_Storage-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)

---

## 📌 Overview

**NeuroVoice** is an end-to-end voice screening and decision-support mobile platform for the early detection of **Parkinson's Disease (PD)**. By analyzing voice acoustic micro-perturbations (hypophonia, vocal tremor, jitter, shimmer, HNR, and MFCCs), NeuroVoice provides early non-invasive screening, dynamic AI clinical assessments, dual-track audio replay, offline SQLite tracking, and specialist geolocation.

👉 **For the complete architectural guide, mathematical formulations, and API specifications, read [DOCUMENTATION.md](DOCUMENTATION.md).**

---

## 🚀 Key Features

- 🎙️ **Vocal Biomarker Extraction**: Librosa (MFCCs, $F_0$, ZCR, Spectral) + Praat/Parselmouth (Jitter, Shimmer, HNR).
- ⚛️ **Hybrid Quantum-Classical & INT8 ML**: PyTorch Deep MLP + PennyLane Variational Quantum Circuit (VQC) with dynamic 8-bit quantization.
- 🤖 **Dynamic Clinical Reports (Groq Llama 3)**: Tailored AI clinical narratives based directly on the patient's individual acoustic biomarkers (no static text).
- 🔊 **Dual Waveform Visualizer & Audio Replay**: Interactive `fl_chart` waveforms and in-app playback for both **raw** and **preprocessed** audio samples.
- 📱 **De-Cluttered Modern Flutter Flow**: Streamlined 3-tier architecture with an all-in-one unified tabbed `ReportScreen`.
- 💾 **Local SQLite3 History**: On-device persistent storage of all tests, feature vectors, and trends with search & swipe-delete.
- 🗺️ **Free Neurologist Geolocation**: Integrated with OpenStreetMap Overpass API (no API key needed) to navigate to nearby movement disorder clinics.

---

## 🛠️ Quick Start

### 1. Run the Backend Server
```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt

# (Optional) Add your Groq API key for Llama 3 reports
# In .env: GROQ_API_KEY="gsk_..."

python main.py
```
Backend runs at: `http://localhost:8000` (Swagger docs at `http://localhost:8000/docs`)

### 2. Run the Mobile App
```powershell
flutter pub get

# If running on physical Android device over USB:
adb reverse tcp:8000 tcp:8000

flutter run
```

### 3. Run Automated Tests
```powershell
# Backend smoke tests
python backend/test_api.py

# Flutter static analysis
flutter analyze lib
```

---

## 📖 Complete Documentation

See **[DOCUMENTATION.md](DOCUMENTATION.md)** for:
- End-to-end architecture diagrams
- Detailed clinical biomarker explanations (Jitter, Shimmer, HNR, MFCCs)
- PennyLane 8-qubit quantum circuit details
- Complete FastAPI endpoints & JSON payloads
- SQLite schema specifications
- Medical compliance and privacy guidelines
