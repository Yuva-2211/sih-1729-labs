# NeuralVoice Backend

FastAPI backend for Parkinson's Disease early detection via smartphone voice analysis.  
**SIH26139 (PS3) — Smart India Hackathon 2026**

---

## Architecture

```
Audio Upload (WAV/MP3/OGG)
        │
        ▼
Stage 1 — Feature Extraction (librosa + parselmouth)
        │  MFCCs · F0 · ZCR · Spectral · Jitter · Shimmer · HNR
        ▼
Stage 2 — Feature Selection (top-8, matching training-time RF selection)
        │  + StandardScaler normalization (saved scaler artifact)
        ▼
Stage 3 — Model Inference
        │  classical_fp32 | classical_int8 | hybrid_fp32 | hybrid_int8
        ▼
Stage 4 — Risk Score + Recommendation
        │  sigmoid → probability → low / moderate / high
        ▼
JSON Response
```

---

## Quick Start

```bash
cd backend/

# 1. Install dependencies
pip install -r requirements.txt

# 2. (Optional) Install quantum + Praat extras
pip install pennylane praat-parselmouth

# 3. Run the server
python main.py
# or
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Open **http://localhost:8000/docs** for the interactive Swagger UI.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/predict` | Upload audio → PD risk score |
| `POST` | `/api/v1/predict/features` | Send pre-extracted features as JSON |
| `GET`  | `/api/v1/models` | Model variant status |
| `GET`  | `/api/v1/health` | Liveness probe |
| `GET`  | `/docs` | Swagger UI |

### `POST /api/v1/predict`

```bash
curl -X POST http://localhost:8000/api/v1/predict \
  -F "file=@voice_sample.wav" \
  -F "model_variant=classical_fp32"
```

**Response:**
```json
{
  "request_id": "c3f7...",
  "probability": 0.7812,
  "risk_level": "high",
  "recommendation": "High PD risk detected. Immediate referral to a neurologist recommended.",
  "selected_features": {
    "mfcc_mean_0": -12.4,
    "f0_mean": 98.2,
    ...
  },
  "latency_ms": 342.1,
  "model_used": "classical_fp32"
}
```

### `POST /api/v1/predict/features`

For mobile clients doing on-device feature extraction:

```bash
curl -X POST http://localhost:8000/api/v1/predict/features \
  -H "Content-Type: application/json" \
  -d '{
    "features": {
      "mfcc_mean_0": -15.3,
      "f0_mean": 115.4,
      "jitter_local": 0.0045,
      "shimmer_local": 0.032,
      "hnr": 18.7,
      "spec_centroid": 1250.0,
      "zcr": 0.08
    },
    "model_variant": "classical_fp32"
  }'
```

---

## Model Variants

| Variant | Description | Latency (est.) |
|---------|-------------|----------------|
| `classical_fp32` | 3-layer MLP baseline, FP32 | ~200 ms |
| `classical_int8` | INT8-quantized MLP baseline | ~150 ms |
| `hybrid_fp32` | Hybrid VQC (PennyLane, 8-qubit, 3-layer ansatz) | ~2–8 s |
| `hybrid_int8` | INT8-quantized hybrid VQC | ~2–6 s |

> The hybrid model requires `pennylane` to be installed. If not present, the server
> falls back to `classical_fp32` automatically.

---

## File Structure

```
backend/
├── main.py               ← FastAPI app + routes
├── inference.py          ← Model loading + predict() pipeline
├── feature_extraction.py ← Stage-1 audio → feature dict
├── models.py             ← Model class definitions (mirrors notebook)
├── requirements.txt      ← Python dependencies
├── .env.example          ← Config template
└── test_api.py           ← Pytest / standalone smoke tests
```

---

## Running Tests

```bash
# Loads trained model artifacts from model_v2/v2-model training (fallback to model_v1)
pytest backend/test_api.py -v

# Or standalone (no pytest)
python backend/test_api.py
```

---

## Risk Thresholds

| Score Range | Level | Action |
|-------------|-------|--------|
| 0.00 – 0.35 | 🟢 Low | No immediate referral needed |
| 0.35 – 0.65 | 🟡 Moderate | Consider neurologist follow-up |
| 0.65 – 1.00 | 🔴 High | Immediate neurologist referral |

> Thresholds are tuned for **high sensitivity** (prefer over-referral to missing a case),
> consistent with the SIH26139 clinical requirement.
