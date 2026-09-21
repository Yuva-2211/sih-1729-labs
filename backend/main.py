"""
main.py — FastAPI application entry point.
Parkinson's Disease Voice Analysis Backend — SIH1729 / SIH26139

Endpoints
---------
POST /api/v1/predict          Upload a WAV file → PD risk score
POST /api/v1/predict/features Send pre-extracted features as JSON
GET  /api/v1/models           List available model variants + status
GET  /api/v1/health           Liveness probe
GET  /docs                    Auto-generated Swagger UI
"""

import logging
import os
import shutil
import tempfile
import time
import uuid
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Literal, Optional

import numpy as np
import torch
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import inference

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan — eager model warm-up so the first request is not slow
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Warming up models ...")
    try:
        inference._load_models()
        logger.info("All models ready [OK]")
    except Exception as exc:
        logger.error("Model warm-up failed: %s", exc)
    yield
    logger.info("Server shutting down.")


# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------

app = FastAPI(
    title="NeuralVoice — PD Risk API",
    description=(
        "Parkinson's Disease early detection via smartphone voice analysis.\n\n"
        "**Architecture**: Hybrid Quantum-Classical ML (VQC + Classical baseline).\n"
        "**Problem Statement**: SIH26139 (PS3) — Smart India Hackathon 2026."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supported model variants
ModelVariant = Literal["classical_fp32", "classical_int8", "hybrid_fp32", "hybrid_int8"]


# ---------------------------------------------------------------------------
# Pydantic schemas
# ---------------------------------------------------------------------------

class PredictionResponse(BaseModel):
    request_id: str = Field(..., description="Unique ID for this inference request")
    probability: float = Field(..., ge=0.0, le=1.0, description="PD risk probability (0=healthy, 1=PD)")
    risk_level: Literal["low", "moderate", "high"]
    recommendation: str = Field(..., description="Rule-based clinical recommendation (always present)")
    llm_recommendation: str = Field(..., description="LLM-generated personalised recommendation (Groq Llama 3)")
    selected_features: dict[str, float] = Field(..., description="Feature values fed to the model")
    inference_latency_ms: float = Field(..., description="Model inference latency (excl. LLM) in ms")
    latency_ms: float = Field(..., description="Total end-to-end pipeline latency (incl. LLM) in ms")
    model_used: str
    raw_waveform: list[float] = Field(default_factory=list, description="200-pt raw audio amplitude snapshot")
    preprocessed_waveform: list[float] = Field(default_factory=list, description="200-pt VAD-trimmed normalised audio snapshot")
    raw_audio_b64: str = Field(default="", description="Base64-encoded raw WAV audio for client playback")
    preprocessed_audio_b64: str = Field(default="", description="Base64-encoded preprocessed WAV audio for client playback")
    patient_name: str = Field(default="Participant", description="Participant or patient name")



class FeaturePredictRequest(BaseModel):
    """
    Alternative input: send pre-computed feature dict from an on-device SDK
    instead of uploading raw audio.
    """
    features: dict[str, float] = Field(
        ...,
        example={
            "mfcc_mean_0": -15.3,
            "mfcc_mean_1": 22.1,
            "f0_mean": 115.4,
            "jitter_local": 0.0045,
            "shimmer_local": 0.032,
            "hnr": 18.7,
            "spec_centroid": 1250.0,
            "zcr": 0.08,
        },
    )
    model_variant: ModelVariant = "classical_fp32"


class FeaturePredictResponse(BaseModel):
    request_id: str
    probability: float
    risk_level: Literal["low", "moderate", "high"]
    recommendation: str
    latency_ms: float
    model_used: str


class ModelsStatusResponse(BaseModel):
    classical_fp32: bool
    classical_int8: bool
    hybrid_fp32: bool
    hybrid_int8: bool
    selected_features: Optional[list[str]]
    model_dir: str


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"]
    version: str
    models_loaded: bool


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _save_upload_to_temp(upload: UploadFile) -> str:
    """Persist the uploaded file to a temp path and return the path string."""
    suffix = Path(upload.filename or "audio.wav").suffix or ".wav"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    try:
        shutil.copyfileobj(upload.file, tmp)
    finally:
        tmp.close()
    return tmp.name


# ---------------------------------------------------------------------------
# Routes — System
# ---------------------------------------------------------------------------

@app.get(
    "/api/v1/health",
    response_model=HealthResponse,
    tags=["System"],
    summary="Liveness probe",
)
async def health():
    """Returns `ok` when at least one model variant is loaded and ready."""
    status = inference.get_models_status()
    models_loaded = status["classical_fp32"] or status["hybrid_fp32"]
    return HealthResponse(
        status="ok" if models_loaded else "degraded",
        version=app.version,
        models_loaded=models_loaded,
    )


@app.get(
    "/api/v1/models",
    response_model=ModelsStatusResponse,
    tags=["System"],
    summary="Model status",
)
async def list_models():
    """Returns which of the four trained model variants are currently loaded."""
    return inference.get_models_status()


# ---------------------------------------------------------------------------
# Routes — Prediction
# ---------------------------------------------------------------------------

@app.post(
    "/api/v1/predict",
    response_model=PredictionResponse,
    tags=["Prediction"],
    summary="Predict PD risk from raw audio",
)
def predict_audio(
    file: UploadFile = File(
        ...,
        description=(
            "Audio recording (WAV preferred). "
            "Sustained vowel /a/ (≥5 s) or short read passage (~30 s). "
            "Recorded at 16 kHz mono for best accuracy."
        ),
    ),
    model_variant: ModelVariant = Query(
        default="classical_fp32",
        description=(
            "Model variant to use:\n"
            "- `classical_fp32` — baseline neural net, FP32 (fastest)\n"
            "- `classical_int8` — INT8-quantized baseline (smaller)\n"
            "- `hybrid_fp32`   — Hybrid Quantum-Classical VQC (requires PennyLane)\n"
            "- `hybrid_int8`   — INT8-quantized hybrid VQC"
        ),
    ),
    use_llm: bool = Query(
        default=True,
        description="Enable Groq Llama 3 LLM recommendation (Stage 7). Set false for faster responses.",
    ),
    patient_name: str = Query(
        default="Participant",
        description="Participant or patient name for the clinical report.",
    ),
):
    """
    **Primary endpoint** — full Stage-1→4 pipeline:

    1. Load + resample audio to 16 kHz mono
    2. Trim silence (VAD), normalize amplitude
    3. Extract 50+ acoustic features (MFCCs, jitter, shimmer, HNR, F0, ZCR, spectral)
    4. Select top-8 features (matching training-time Random Forest selection)
    5. Normalize with saved StandardScaler
    6. Run inference with the chosen model variant
    7. Apply sigmoid + threshold to produce risk probability + recommendation

    **Latency (approx.)**: 200–800 ms classical · 2–8 s hybrid (CPU quantum simulator)
    """
    request_id = str(uuid.uuid4())
    tmp_path: Optional[str] = None

    try:
        tmp_path = _save_upload_to_temp(file)
        result = inference.predict(
            tmp_path,
            model_variant=model_variant,
            use_llm=use_llm,
            patient_name=patient_name,
        )
        return PredictionResponse(request_id=request_id, **result)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=f"Model artifact missing: {exc}")
    except Exception as exc:
        logger.exception("predict_audio failed [%s]", request_id)
        raise HTTPException(status_code=500, detail=f"Inference error: {exc}")
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)


@app.post(
    "/api/v1/predict/features",
    response_model=FeaturePredictResponse,
    tags=["Prediction"],
    summary="Predict PD risk from pre-extracted features",
)
async def predict_from_features(body: FeaturePredictRequest):
    """
    Alternative endpoint for mobile clients that perform on-device feature extraction.

    Send the feature dict as JSON — only the `selected_features` (the same 8 features
    used during training) are consumed; any extra keys are silently ignored.
    Missing features default to **0.0**.
    """
    inference._load_models()
    selected = inference._selected_features
    scaler = inference._scaler

    request_id = str(uuid.uuid4())
    t0 = time.perf_counter()

    vec = np.array(
        [body.features.get(f, 0.0) for f in selected], dtype=np.float32
    ).reshape(1, -1)

    scaled = scaler.transform(vec)
    x = torch.tensor(scaled, dtype=torch.float32)

    model_map = {
        "classical_fp32": inference._classical_fp32,
        "classical_int8": inference._classical_int8,
        "hybrid_fp32":    inference._hybrid_fp32,
        "hybrid_int8":    inference._hybrid_int8,
    }
    model = model_map.get(body.model_variant) or inference._classical_fp32
    model.eval()
    with torch.no_grad():
        prob = float(model(x).squeeze())

    latency_ms = (time.perf_counter() - t0) * 1000
    risk_level, recommendation = inference._interpret(prob)

    return FeaturePredictResponse(
        request_id=request_id,
        probability=round(prob, 4),
        risk_level=risk_level,
        recommendation=recommendation,
        latency_ms=round(latency_ms, 2),
        model_used=body.model_variant,
    )


# ---------------------------------------------------------------------------
# Dev entry-point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
