# NeuroVoice (SIH-1729 / SIH-26139)
### AI-Powered Parkinson's Disease Screening via Vocal Biomarkers & Hybrid Quantum-Classical Machine Learning

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.2+-EE4C2C?logo=pytorch&logoColor=white)](https://pytorch.org)
[![PennyLane](https://img.shields.io/badge/PennyLane-Quantum_ML-brightgreen)](https://pennylane.ai)
[![Groq Llama 3](https://img.shields.io/badge/Groq-Llama_3-f55036)](https://groq.com)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker&logoColor=white)](https://docker.com)
[![Render](https://img.shields.io/badge/Render-Deployable-46E3B7?logo=render&logoColor=white)](https://render.com)
[![SQLite](https://img.shields.io/badge/SQLite-Local_Storage-003B57?logo=sqlite&logoColor=white)](https://sqlite.org)

---

## 🎯 Smart India Hackathon (SIH 2026) — Problem Statement #26139

| Field | Details |
|---|---|
| **Problem Statement ID** | **26139** |
| **Problem Statement Title** | **Hybrid Quantum Machine Learning Platform for Early Disease Detection** |
| **Organization** | **Egreen Quanta** |
| **Department** | **Egreen Quanta** |
| **Category** | **Software** |
| **Theme** | **MedTech / BioTech / HealthTech** |

### 📋 Background
Early and accurate detection of diseases significantly improves treatment outcomes and reduces healthcare costs. Classical machine learning models have achieved notable success in medical diagnosis; however, they often face limitations when dealing with high-dimensional, noisy, and complex biomedical data (e.g., genomics, medical imaging, acoustic biomarkers, and electronic health records).

Quantum machine learning (QML) offers the potential to capture intricate patterns through quantum superposition and entanglement. Due to current hardware constraints, a hybrid quantum-classical approach provides a practical pathway to leverage quantum advantages while remaining executable on existing quantum simulators and near-term quantum devices.

### 📝 Problem Description
This problem focuses on designing and developing a hybrid quantum machine learning platform for early disease detection. The platform integrates classical pre-processing and feature engineering with quantum-enhanced learning models (such as quantum support vector machines, quantum neural networks, or variational quantum classifiers). It is applied to biomedical datasets for the early identification of diseases (specifically neurological conditions such as Parkinson's Disease). The system supports data ingestion, hybrid model training, prediction, explainability, and performance evaluation against purely classical baselines.

### 🎯 Objectives
- **Design a hybrid quantum-classical machine learning architecture** suitable for early disease detection.
- **Develop quantum-enhanced classification/regression models** capable of processing high-dimensional biomedical data.
- **Improve detection accuracy, sensitivity, and specificity** compared with classical machine learning baselines.
- **Ensure the platform is scalable, interpretable, and compatible** with near-term quantum hardware and simulators (PennyLane / Qiskit).
- **Incorporate data pre-processing, feature selection, and model explainability modules** (including generative LLM clinical narratives).
- **Benchmark the hybrid approach against classical models** in terms of accuracy, computational efficiency, and generalization performance.

### 💡 Expected Solution
A fully functional hybrid quantum machine learning software platform capable of performing early disease detection on real or benchmark biomedical datasets. The solution includes data handling pipelines, hybrid quantum-classical model implementation, training and inference workflows, performance evaluation, explainability features, and comprehensive documentation.

---

## 📦 Delivery Table (Expected Deliverables)

| S.No | Expected Deliverable | Description | NeuroVoice Implementation Component | Status |
|:---:|---|---|---|:---:|
| **1** | **Hybrid Quantum-Classical ML Architecture** | Integration of a Classical Deep MLP feature dimensionality reducer with a PennyLane 8-qubit Variational Quantum Circuit (VQC) with strongly entangling layers. | `backend/models.py`, `model_v2/` | ✅ Completed |
| **2** | **Biomedical Ingestion & Feature Engineering** | High-precision acoustic signal processing pipeline extracting 26 clinical features (13 MFCCs, Jitter, Shimmer, HNR, Spectral Centroid/Roll-off, ZCR, RMS Energy). | `backend/feature_extraction.py`, `parselmouth`, `librosa` | ✅ Completed |
| **3** | **Model Optimization & Edge Quantization** | Post-training dynamic 8-bit quantization (INT8) for both classical and hybrid networks, ensuring sub-50ms inference latency. | `backend/inference.py`, PyTorch Quantization | ✅ Completed |
| **4** | **Classical vs. Hybrid Benchmarking Suite** | Comprehensive comparative evaluation benchmarking Classical FP32/INT8 against Hybrid Quantum FP32/INT8 on MDVR-KCL and UCI datasets. | `backend/benchmark.py`, `DOCUMENTATION.md` | ✅ Completed |
| **5** | **AI Clinical Explainability & Reporting** | Generative clinical narrative engine via Groq Llama 3, translating numeric acoustic anomalies into actionable medical interpretations. | `backend/llm_recommendation.py` | ✅ Completed |
| **6** | **Containerized Cloud Inference API** | Scalable FastAPI REST backend with eager model warm-up, CORS handling, audio validation, Swagger docs, and Docker runtime. | `backend/main.py`, `Dockerfile`, `render.yaml` | ✅ Completed |
| **7** | **Cross-Platform Mobile Screening App** | Production-ready Flutter client featuring live audio capture, dual waveform visualizers (`fl_chart`), audio playback, and PDF-style report view. | `lib/`, Flutter 3.22+ | ✅ Completed |
| **8** | **Privacy-Preserving On-Device Storage** | Offline-first SQLite database retaining patient screening histories and feature vectors locally without cloud telemetry leaks. | `lib/services/database_service.dart`, `sqflite` | ✅ Completed |
| **9** | **Geospatial Specialist Referral** | Integrated movement disorder clinic locator via OpenStreetMap Overpass API without requiring proprietary map API keys or geotracking. | `lib/screens/neurologist_finder_screen.dart` | ✅ Completed |
| **10** | **Comprehensive Technical Documentation** | Full architectural formulations, circuit designs, mathematical definitions, API contracts, and SaMD compliance guides. | [DOCUMENTATION.md](DOCUMENTATION.md) | ✅ Completed |

---

## 👥 Meet the Team

| Member | Role | LinkedIn Profile |
|---|---|---|
| **Vishwa Kaaliya Moorthy** | **Team Lead & Data Scientist** | [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/vishwakaliyamoorthy/) |
| **Rakesh Krishna Golla** | **App Developer** | [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/rakesh-krishna-golla-7757a1394/) |
| **Yuva Shankar Narayana** | **ML Engineer** | [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/yuva-shankar-narayana/) |
| **Pavithra H** | **UI/UX Designer** | [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/pavithra-h-048a8b321/) |
| **Ranjini A** | **Data Scientist** | [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ranjini-anbazhagan/) |

---

# NeuroVoice (SIH-1729) — Comprehensive System Documentation & Technical Specification

---

## 1. Executive Summary

**NeuroVoice** is an AI-powered voice screening and clinical decision-support system designed for early detection and longitudinal monitoring of **Parkinson’s Disease (PD)**. Voice impairment (hypophonia, vocal tremor, pitch instability, and dysphonia) is among the earliest observable biomarkers of Parkinson's Disease, often preceding motor symptoms by several years.

NeuroVoice bridges cutting-edge audio signal processing, quantum-classical machine learning, generative AI, and mobile health into a unified system:

1. **Acoustic Biomarker Extraction**: Rigorous digital signal processing combining **Librosa** (spectral analysis, Mel-Frequency Cepstral Coefficients, fundamental frequency F0) and **Praat/Parselmouth** (micro-perturbations: Jitter, Shimmer, Harmonics-to-Noise Ratio).
2. **Hybrid Quantum-Classical & INT8 Quantized ML**: Deep neural networks paired with a **PennyLane Variational Quantum Circuit (VQC)** running 8-qubit angle embeddings with entangling layers, quantized to INT8 precision for low-latency edge deployment.
3. **Dynamic LLM Clinical Explanations**: Seamless integration with **Groq Llama 3** to transform raw mathematical biomarkers into actionable, empathetic clinical narratives and lifestyle recommendations.
4. **Dual-Audio Replay & Waveform Visualizer**: Full client-side interactive waveforms (`fl_chart`) paired with in-app audio playback of both the **raw voice** and the **VAD-trimmed preprocessed voice**.
5. **Local SQLite3 Persistence**: 100% on-device, offline-accessible historical tracking of patient screenings with longitudinal analytics.
6. **Geo-Location Specialist Finder**: Free, privacy-preserving integration with the **OpenStreetMap Overpass API** to locate nearest hospitals and neurological clinics when high risk is detected.

---

## 2. End-to-End System Architecture

```mermaid
flowchart TD
    subgraph MobileApp ["Flutter Mobile Client (Android / iOS / Desktop)"]
        UI_Home["Home & Quick Triage"]
        UI_Record["Audio Recording (16kHz WAV)"]
        UI_Pipeline["Animated Pipeline Screen"]
        UI_Report["Unified Report Screen\n(Overview, Audio Replay, Biomarkers, Doctors)"]
        UI_History["SQLite History Screen"]
        DB[(Local SQLite DB\nsqflite)]
    end

    subgraph Backend ["FastAPI Cloud / Edge Server"]
        API["FastAPI REST Gateway\n(/api/v1/predict)"]
        DSP["Stage 1 & 2: Audio Preprocessing\n(VAD Trim, Normalization, 16kHz)"]
        FE["Stage 3: Acoustic Feature Extraction\n(Librosa + Praat Parselmouth)"]
        WAV_GEN["Dual WAV Generator\n(PCM-16 Base64 Encoding)"]
        SCALER["StandardScaler\n(8 Selected Features)"]
        ML_MODEL["Stage 5: ML Inference Engine\n- Classical FP32 / INT8\n- Hybrid Quantum VQC (PennyLane)"]
        LLM_ENG["Stage 7: Groq Llama 3 Engine\n(Biomarker-Conditioned Report)"]
    end

    subgraph External ["External Privacy-Preserving Services"]
        GROQ_API["Groq Cloud API\n(Llama 3 70B/8B)"]
        OSM_API["OpenStreetMap Overpass API\n(Nearest Neurologists)"]
    end

    UI_Record -->|Uploads .WAV| API
    API --> DSP
    DSP --> FE
    DSP --> WAV_GEN
    WAV_GEN -->|raw_audio_b64 & preprocessed_audio_b64| API
    FE --> SCALER
    SCALER --> ML_MODEL
    ML_MODEL -->|Risk & Probability| LLM_ENG
    LLM_ENG <-->|JSON Prompt / Response| GROQ_API
    LLM_ENG --> API
    API -->|PredictionResponse JSON| UI_Pipeline
    UI_Pipeline --> UI_Report
    UI_Report -->|Auto-save record| DB
    UI_History <--> DB
    UI_Report <-->|GPS Lat/Lon Query| OSM_API
```

---

## 3. Acoustic Signal Processing & Feature Engineering

### 3.1 Digital Signal Pipeline
1. **Sampling**: All audio is converted to single-channel **16,000 Hz 16-bit PCM WAV**.
2. **Voice Activity Detection (VAD)**: Leading and trailing silence are stripped using `librosa.effects.trim` with a `top_db=20` threshold, ensuring ambient room noise does not corrupt speech metrics.
3. **Amplitude Normalization**: Peak normalization scales samples to $[-1.0, 1.0]$ via $y_{\text{norm}} = \frac{y}{\max(|y|) + 10^{-8}}$.
4. **Waveform Downsampling**: For smooth UI rendering without bandwidth bloat, the 16 kHz stream is downsampled to an exact 200-point uniform coordinate array for both raw and preprocessed tracks.

### 3.2 Acoustic Biomarkers Extracted
Parkinson’s Disease causes vocal fold muscle rigidity, bradykinesia, and tremor. NeuroVoice captures the physiological signatures:

| Biomarker | Library / Tool | Physiological / Clinical Significance in Parkinson's Disease |
| :--- | :--- | :--- |
| **Jitter (Local, RAP, PPQ5)** | Praat (Parselmouth) | Cycle-to-cycle frequency variations caused by lack of vocal fold tension control. High jitter denotes vocal tremor and instability. |
| **Shimmer (Local, APQ3, APQ5)** | Praat (Parselmouth) | Cycle-to-cycle amplitude variations caused by incomplete vocal cord closure and glottal air leakage. |
| **Harmonics-to-Noise Ratio (HNR)** | Praat (Parselmouth) | Ratio of periodic sound energy to non-periodic air turbulence (in dB). Low HNR indicates breathiness and vocal roughness. |
| **Fundamental Frequency ($F_0$) Mean & Std** | Librosa (YIN algorithm) | Pitch variation and monotony. PD patients often present monopitch (reduced $F_0$ standard deviation). |
| **MFCCs (Coefficients 0 to 12 Mean & Std)** | Librosa | Mel-Frequency Cepstral Coefficients model vocal tract filter shapes and articulatory precision. Captures hypophonia and blurred articulation. |
| **Zero-Crossing Rate (ZCR)** | Librosa | Rate of sign-changes in signal; measures noisiness, breathiness, and unvoiced speech segments. |
| **Spectral Centroid & Rolloff** | Librosa | Measures frequency distribution, vocal brightness, and energy rolloff. |

### 3.3 Optimal Feature Selection
From the 33 extracted dimensions, a statistical feature selection pipeline (Random Forest feature importance + correlation pruning) isolates the **top 8 most discriminative biomarkers**:
1. `mfcc_mean_1`: Spectral tilt and resonance envelope.
2. `mfcc_std_0`: Overall voice stability across time.
3. `mfcc_std_3`: Formant variations.
4. `mfcc_std_11`: High-frequency vocal tract nuances.
5. `mfcc_std_1`: Spectral variance across phonation.
6. `mfcc_std_10`: Detailed higher-order spectral perturbation.
7. `mfcc_std_6`: Mid-to-high frequency vocal stability.
8. `mfcc_std_4`: Formant transition consistency.

Features are standardized using `feature_scaler.joblib` (scikit-learn `StandardScaler` fitted on training corpora).

---

## 4. Machine Learning & Quantum Architecture

NeuroVoice provides multiple swappable model backends:

### 4.1 Classical Deep Neural Network (Baseline)
- **Architecture**:
  - Input Layer: 8 features
  - Hidden Layer 1: $\text{Linear}(8 \to 16) \to \text{ReLU}$
  - Hidden Layer 2: $\text{Linear}(16 \to 8) \to \text{ReLU}$
  - Output Layer: $\text{Linear}(8 \to 1) \to \text{Sigmoid}$
- **FP32 & INT8 Quantization**: The network is dynamically quantized (`torch.quantization.quantize_dynamic`) to 8-bit integer weights.
  - Model file: `model_v1/classical_quantized_int8.pt` (under 6 KB)
  - Inference latency: $< 2 \text{ ms}$ on standard edge CPU.

### 4.2 Hybrid Quantum-Classical VQC (Variational Quantum Circuit)
Built with **PennyLane** and **PyTorch**:
- **Quantum Device**: 8-qubit simulator (`default.qubit`), mapped 1:1 to the 8 acoustic features.
- **Circuit Workflow**:
  1. **Classical Pre-net**: $\text{Linear}(8 \to 8) \to \text{Tanh}$, scaled by $\pi$ to map continuous features to rotation angles $[-\pi, \pi]$.
  2. **Angle Embedding**: `qml.AngleEmbedding(inputs, wires=range(8))` prepares quantum state $|\psi\rangle$ by applying $R_x(\theta_i)$ rotations.
  3. **Entanglement Layers**: `qml.BasicEntanglerLayers(weights, wires=range(8))` over 3 parameterized layers. Creates multi-qubit entanglement to capture non-linear feature interactions in Hilbert space.
  4. **Expectation Measurement**: Pauli-Z expectation values $\langle \sigma_z^{(i)} \rangle$ measured on all 8 wires.
  5. **Classical Post-net**: $\text{Linear}(8 \to 16) \to \text{ReLU} \to \text{Linear}(16 \to 1) \to \text{Sigmoid}$.

---

## 5. Dynamic LLM Clinical Decision Support

### 5.1 Groq Llama 3 Engine
Rather than presenting generic advice, [`backend/llm_recommendation.py`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/backend/llm_recommendation.py) dynamically prompts Groq Llama 3 (`llama-3.3-70b-versatile` or `llama3-8b-8192`):
- **Inputs to LLM**:
  - Risk tier (`low`, `moderate`, `high`)
  - Continuous probability percentage (e.g. $87.4\%$)
  - Top 3 dominant acoustic biomarkers driving the prediction with their human-readable clinical interpretations
  - Measured latency and model variant
- **Guardrails**:
  - Clear medical framing: Explicitly states this is a screening tool, not a definitive diagnostic test.
  - Strict absence of hallucinations: LLM is restricted to the provided acoustic biomarkers.
  - Actionable guidance: Recommends specific clinical specialists (Movement Disorder Neurologists, Speech-Language Pathologists) and vocal health exercises.
- **Offline Fallback**: If the Groq API key is not configured or network connectivity fails, a rule-based clinical engine generates comprehensive biomarker-specific guidance automatically.

---

## 6. Mobile Application Architecture (Flutter)

The mobile application is written in Flutter 3 using Material 3 with a unified medical design system (`AppColors`, `AppTypography`).

### 6.1 Unified Screen Flow
```
                ┌──────────────┐
                │  HomeScreen  │
                └──────┬───────┘
                       │
       ┌───────────────┴───────────────┐
       ▼                               ▼
┌──────────────┐               ┌───────────────┐
│ RecordScreen │               │ HistoryScreen │ (SQLite Browser)
└──────┬───────┘               └───────┬───────┘
       │                               │
       ▼                               │
┌───────────────────────┐              │
│AnalysisPipelineScreen │              │
└──────┬────────────────┘              │
       │                               │
       ▼                               │
┌──────────────────────────────────────┴┐
│             ReportScreen              │
│ ┌─────────┬──────────┬────────┬─────┐ │
│ │Overview │ Waveform │ Biomk. │ Dr. │ │
│ └─────────┴──────────┴────────┴─────┘ │
└───────────────────────────────────────┘
```

### 6.2 Key Screens & Components

#### 1. Home Screen ([`lib/screens/home_screen.dart`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/lib/screens/home_screen.dart))
- Real-time backend connectivity indicator (`/api/v1/health`).
- Quick-start recording CTA.
- Summary metrics card displaying total lifetime tests, low risk counts, and high-risk flags.

#### 2. Record & Pipeline Screen ([`lib/screens/record_screen.dart`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/lib/screens/record_screen.dart) & [`lib/screens/analysis_pipeline_screen.dart`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/lib/screens/analysis_pipeline_screen.dart))
- Sustained phonation guidance (e.g. holding vowel `/a/` for 5 seconds).
- Decibel amplitude visualizer and countdown timer.
- Animated multi-stage analysis progression:
  1. *Audio Signal Preprocessing & VAD*
  2. *Acoustic Biomarker Extraction (MFCCs, Jitter, Shimmer)*
  3. *Quantum & Classical ML Inference*
  4. *Groq Llama-3 Clinical Reasoning Engine*

#### 3. Unified Report Screen ([`lib/screens/report_screen.dart`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/lib/screens/report_screen.dart))
Consolidates all diagnostics into 4 intuitive tabs:
- **Tab 1: Overview**:
  - Animated risk dial with color-coded risk tier (Green: Low, Amber: Moderate, Red: High).
  - Confidence percentage badge.
  - Groq Llama-3 AI Clinical Assessment card with model badges.
  - PDF export and share actions.
- **Tab 2: Waveforms & Audio Replay**:
  - Interactive `fl_chart` dual waveforms: **Raw Audio** vs **VAD-Trimmed Normalised Audio**.
  - Built-in audio player for both tracks: Users and clinicians can press **Play/Pause** to hear the exact sound data evaluated by the model.
- **Tab 3: Biomarkers & Explainability**:
  - Interactive feature importance bar charts comparing user's biomarkers against baseline norms.
  - Expandable clinical cards explaining what each biomarker (MFCC, Jitter, HNR, F0) means in plain language.
- **Tab 4: Nearby Specialists**:
  - Triggered for elevated risk results.
  - Queries OpenStreetMap Overpass API for neurology clinics and hospitals within 15 km of the user's GPS coordinates.
  - Displays distance, address, phone number, and a direct button to launch navigation in Maps.

#### 4. History Screen ([`lib/screens/history_screen.dart`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/lib/screens/history_screen.dart))
- Backed by local SQLite database.
- Search and filter by risk category.
- Swipe-to-delete with undo confirmation.
- One-touch navigation back into the full Report screen for historical reviews.

---

## 7. SQLite3 Database Architecture

Implemented in [`lib/services/database_service.dart`](file:///c:/Users/Hp/OneDrive/Desktop/sih-1729-labs/lib/services/database_service.dart):

### Table: `reports`

| Column | Type | Description |
| :--- | :--- | :--- |
| `request_id` | `TEXT PRIMARY KEY` | Unique UUID assigned per inference run |
| `timestamp` | `TEXT NOT NULL` | ISO 8601 formatted timestamp |
| `risk_level` | `TEXT NOT NULL` | `'low'`, `'moderate'`, or `'high'` |
| `probability` | `REAL NOT NULL` | Floating point prediction score ($0.0$ to $1.0$) |
| `recommendation` | `TEXT NOT NULL` | Base clinical recommendation |
| `llm_recommendation` | `TEXT NOT NULL` | Groq Llama 3 personalized report |
| `model_used` | `TEXT NOT NULL` | Identifier of model variant used |
| `audio_path` | `TEXT` | Local file path to the original recording |
| `selected_features` | `TEXT NOT NULL` | JSON serialized dictionary of extracted acoustic features |
| `inference_latency_ms` | `REAL NOT NULL` | Pure neural network / VQC latency in ms |
| `latency_ms` | `REAL NOT NULL` | End-to-end processing latency including LLM in ms |

---

## 8. Backend API Reference

### Base URL: `http://localhost:8000/api/v1`

#### `GET /health`
Verifies backend operational status.
- **Response**:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "models_loaded": true
}
```

#### `GET /models`
Returns availability of all trained model artifacts.
- **Response**:
```json
{
  "classical_fp32": true,
  "classical_int8": true,
  "hybrid_fp32": true,
  "hybrid_int8": true,
  "selected_features": [
    "mfcc_mean_1", "mfcc_std_0", "mfcc_std_3", "mfcc_std_11",
    "mfcc_std_1", "mfcc_std_10", "mfcc_std_6", "mfcc_std_4"
  ],
  "model_dir": "C:\\Users\\Hp\\OneDrive\\Desktop\\sih-1729-labs\\model_v1"
}
```

#### `POST /predict`
Upload raw audio for end-to-end screening.
- **Query Parameter**: `model_variant` (`classical_fp32`, `classical_int8`, `hybrid_fp32`, `hybrid_int8`)
- **Body**: `multipart/form-data` with `file: audio.wav`
- **Response**:
```json
{
  "request_id": "c8f2b38e-8a21-4f10-9bdf-87f54c1387d2",
  "probability": 0.8124,
  "risk_level": "high",
  "recommendation": "High probability of vocal characteristics associated with Parkinson's Disease. We strongly advise scheduling a clinical consultation with a movement disorder specialist or neurologist.",
  "llm_recommendation": "Clinical Voice Assessment:\n\nBased on your acoustic biomarker analysis, significant pitch and amplitude micro-perturbations were detected. Specifically, elevated MFCC-1 variation and fundamental frequency instability suggest decreased glottal adduction consistent with early hypophonia. We strongly suggest presenting this report to a Neurologist or Movement Disorder Specialist for a formal clinical evaluation.",
  "selected_features": {
    "mfcc_mean_1": 22.41,
    "mfcc_std_0": 14.82,
    "mfcc_std_3": 8.19,
    "mfcc_std_11": 5.43,
    "mfcc_std_1": 9.12,
    "mfcc_std_10": 4.88,
    "mfcc_std_6": 6.72,
    "mfcc_std_4": 7.31
  },
  "inference_latency_ms": 1.48,
  "latency_ms": 1420.5,
  "model_used": "classical_int8",
  "raw_waveform": [-0.02, 0.15, 0.42, ...],
  "preprocessed_waveform": [0.01, -0.22, 0.78, ...],
  "raw_audio_b64": "UklGRi4AAABXQVZFZm10IBAAAA...",
  "preprocessed_audio_b64": "UklGRq4AAABXQVZFZm10IBAAAA..."
}
```

#### `POST /predict/features`
For pre-computed feature vectors from on-device SDKs.
- **Body**:
```json
{
  "features": {
    "mfcc_mean_1": 22.41,
    "mfcc_std_0": 14.82
  },
  "model_variant": "classical_fp32"
}
```

---

## 9. Setup & Installation Guide

### Prerequisites
- **Python**: 3.10 or 3.11
- **Flutter**: 3.22+ with Dart 3.4+
- **Android Studio / Xcode** with build tools installed

### 1. Backend Setup
```powershell
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# (Optional) Configure Groq API Key for LLM recommendations
# Create .env file:
echo GROQ_API_KEY="gsk_your_groq_api_key" > .env

# Run FastAPI server
python main.py
# Server starts on http://0.0.0.0:8000
```

### 2. Mobile App Setup
```powershell
# From project root
flutter pub get

# Connect Android device or start emulator
# If using physical Android phone via USB:
adb reverse tcp:8000 tcp:8000

# Run Flutter app in debug mode
flutter run
```

---

## 10. Deploying Backend to Render (Cloud Hosting)

The NeuroVoice backend is containerized and ready to deploy to [Render](https://render.com) using Docker. Because audio feature extraction requires system-level shared libraries (`libsndfile1` and `ffmpeg`), **Docker deployment is the recommended method** to guarantee flawless execution in production.

### Method 1: One-Click Blueprint Deployment (Recommended)
1. Ensure this repository is pushed to your GitHub account: `https://github.com/Yuva-2211/sih-1729-labs.git`.
2. Navigate to [Render Dashboard](https://dashboard.render.com/) and sign in.
3. Click **New +** → **Blueprint**.
4. Connect your GitHub repository `sih-1729-labs`.
5. Render detects the root [`render.yaml`](render.yaml) file automatically:
   - **Service Name**: `neurovoice-backend`
   - **Runtime**: `Docker` (using root `Dockerfile`)
   - **Health Check Path**: `/api/v1/health`
   - **Port**: `8000`
6. (Optional) In the configuration screen, supply your `GROQ_API_KEY` for AI clinical recommendations.
7. Click **Apply**. Render will automatically build the image and spin up your web service.

---

### Method 2: Manual Web Service Setup via Dashboard
1. Go to [Render Dashboard](https://dashboard.render.com/) and click **New +** → **Web Service**.
2. Choose **Build and deploy from a Git repository** and connect `sih-1729-labs`.
3. Fill out the service settings:
   - **Name**: `neurovoice-backend`
   - **Region**: Select your preferred region (e.g., *Oregon (US West)* or *Singapore*)
   - **Branch**: `main`
   - **Language / Runtime**: **Docker**
   - **Dockerfile Path**: `./Dockerfile`
   - **Docker Context**: `.`
   - **Instance Type**: **Free**
4. Under **Advanced** → **Environment Variables**:
   - `PORT`: `8000`
   - `GROQ_API_KEY`: *(Optional: Your Groq API key `gsk_...` for LLM clinical summaries)*
5. Under **Health Check Path**, enter: `/api/v1/health`.
6. Click **Create Web Service**.

Once deployed, your live endpoints will be:
- **Service Base URL**: `https://<your-service-name>.onrender.com`
- **Interactive Swagger Docs**: `https://<your-service-name>.onrender.com/docs`
- **Health Probe**: `https://<your-service-name>.onrender.com/api/v1/health`

> [!NOTE]
> Free-tier instances on Render enter sleep mode after 15 minutes of inactivity. When a new screening request arrives, the first cold start may take 40–50 seconds while the container initializes and pre-warms the quantum/classical weights.

---

## 11. Verification & Quality Assurance

### Flutter Code Verification
```powershell
flutter analyze lib
# Output: Analyzing lib... No issues found!
```

### Backend Automated Test Suite
```powershell
python backend/test_api.py
# Output:
# [OK] health
# [OK] models
# [OK] predict audio (classical_fp32)
# [OK] predict from features
# [OK] predict from empty features
# All smoke tests passed [OK]
```

---

## 12. Security, Privacy & Medical Compliance Considerations

1. **HIPAA / GDPR Edge Processing**:
   - Audio is sent over secured endpoints, and temporary audio files created on the server during extraction are immediately deleted via `try...finally` cleanup blocks.
2. **Offline-First Storage**:
   - Patient history is retained strictly within the device's local SQLite database. No personal clinical reports are stored on the server.
3. **No Proprietary Map API Key Tracking**:
   - The Neurologist finder utilizes OpenStreetMap's open Overpass API directly from the client, eliminating user geotracking and avoiding external API credential dependencies.
4. **Clinical Disclaimers**:
   - Every screen prominently displays that NeuroVoice is an assistive screening aid and not a diagnostic instrument, ensuring regulatory adherence to SaMD (Software as a Medical Device) guidelines.
