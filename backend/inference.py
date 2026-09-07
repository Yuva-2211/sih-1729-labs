"""
inference.py — Model loading and inference logic.
Loads all four saved model variants + the preprocessing artifacts and exposes
a single `predict()` function used by the API routes.
"""

import logging
import os
import time
from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import torch

from models import ClassicalModel, build_hybrid_model
from feature_extraction import extract_all_features
from llm_recommendation import generate_llm_recommendation

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).parent
MODEL_DIR = BASE_DIR.parent / "model_v1"   # ../model_v1 relative to backend/

N_QUBITS = 8
N_FEATURES = N_QUBITS  # after feature selection


# ---------------------------------------------------------------------------
# Lazy-loaded singletons
# ---------------------------------------------------------------------------

_classical_fp32: Optional[ClassicalModel] = None
_classical_int8: Optional[ClassicalModel] = None
_hybrid_fp32 = None
_hybrid_int8 = None
_scaler = None
_selected_features: Optional[list] = None


def _load_models():
    """Load all model variants and preprocessing artifacts once."""
    global _classical_fp32, _classical_int8, _hybrid_fp32, _hybrid_int8
    global _scaler, _selected_features

    if _scaler is not None:
        return  # already loaded

    logger.info("Loading models from %s", MODEL_DIR)

    # --- Preprocessing artifacts ---
    _scaler = joblib.load(MODEL_DIR / "feature_scaler.joblib")
    _selected_features = joblib.load(MODEL_DIR / "selected_features.joblib")
    logger.info("Selected features: %s", _selected_features)

    # --- Classical FP32 ---
    _classical_fp32 = ClassicalModel(n_features=N_FEATURES)
    _classical_fp32.load_state_dict(
        torch.load(MODEL_DIR / "classical_fp32.pt", map_location="cpu", weights_only=True)
    )
    _classical_fp32.eval()

    # --- Classical INT8 (quantized) ---
    # macOS requires qnnpack engine; fbgemm is Linux/Windows only.
    try:
        torch.backends.quantized.engine = "qnnpack"
        _classical_int8 = ClassicalModel(n_features=N_FEATURES)
        _classical_int8 = torch.quantization.quantize_dynamic(
            _classical_int8, {torch.nn.Linear}, dtype=torch.qint8
        )
        _classical_int8.load_state_dict(
            torch.load(MODEL_DIR / "classical_quantized_int8.pt", map_location="cpu", weights_only=True)
        )
        _classical_int8.eval()
        logger.info("Classical INT8 model loaded successfully.")
    except Exception as exc:
        logger.warning("Could not load classical INT8 model (using FP32 fallback): %s", exc)
        _classical_int8 = None

    # --- Hybrid FP32 ---
    try:
        _hybrid_fp32 = build_hybrid_model()
        _hybrid_fp32.load_state_dict(
            torch.load(MODEL_DIR / "hybrid_quantum_fp32.pt", map_location="cpu", weights_only=True)
        )
        _hybrid_fp32.eval()
        logger.info("Hybrid FP32 model loaded successfully.")
    except Exception as exc:
        logger.warning("Could not load hybrid FP32 model: %s", exc)
        _hybrid_fp32 = None

    # --- Hybrid INT8 ---
    try:
        torch.backends.quantized.engine = "qnnpack"
        _hybrid_int8 = build_hybrid_model()
        _hybrid_int8 = torch.quantization.quantize_dynamic(
            _hybrid_int8, {torch.nn.Linear}, dtype=torch.qint8
        )
        _hybrid_int8.load_state_dict(
            torch.load(MODEL_DIR / "hybrid_quantum_quantized.pt", map_location="cpu", weights_only=True)
        )
        _hybrid_int8.eval()
        logger.info("Hybrid INT8 model loaded successfully.")
    except Exception as exc:
        logger.warning("Could not load hybrid INT8 model: %s", exc)
        _hybrid_int8 = None

    logger.info("All models loaded.")


def get_models_status() -> dict:
    """Return which models are currently loaded."""
    _load_models()
    return {
        "classical_fp32": _classical_fp32 is not None,
        "classical_int8": _classical_int8 is not None,
        "hybrid_fp32": _hybrid_fp32 is not None,
        "hybrid_int8": _hybrid_int8 is not None,
        "selected_features": _selected_features,
        "model_dir": str(MODEL_DIR),
    }


# ---------------------------------------------------------------------------
# Risk interpretation helpers
# ---------------------------------------------------------------------------

RISK_THRESHOLDS = {
    "low":      (0.0,  0.35),
    "moderate": (0.35, 0.65),
    "high":     (0.65, 1.01),
}

REFERRAL_MAP = {
    "low":      "No immediate referral needed. Monitor voice quality periodically.",
    "moderate": "Borderline risk detected. Consider follow-up with a neurologist.",
    "high":     "High PD risk detected. Immediate referral to a neurologist recommended.",
}


def _interpret(prob: float) -> tuple[str, str]:
    for level, (lo, hi) in RISK_THRESHOLDS.items():
        if lo <= prob < hi:
            return level, REFERRAL_MAP[level]
    return "high", REFERRAL_MAP["high"]


# ---------------------------------------------------------------------------
# Core predict function
# ---------------------------------------------------------------------------

def predict(wav_path: str, model_variant: str = "classical_fp32", use_llm: bool = True) -> dict:
    """
    Full pipeline: audio → features → scaling → model → risk score → LLM recommendation.

    Stages
    ------
    1. Audio preprocessing (resample, VAD trim, normalise)
    2. Feature extraction  (MFCCs, F0, ZCR, spectral, jitter, shimmer, HNR)
    3. Feature selection   (top-8 loaded from training artifact)
    4. Quantum encoding    (StandardScaler → AngleEmbedding inside PennyLane)
    5. Model inference     (classical_fp32 | classical_int8 | hybrid_fp32 | hybrid_int8)
    6. Post-processing     (sigmoid → risk probability + threshold → risk level)
    7. LLM recommendation  (Groq Llama 3 — falls back to rule-based if key absent)

    Parameters
    ----------
    wav_path      : Path to the uploaded audio file.
    model_variant : One of "classical_fp32", "classical_int8",
                    "hybrid_fp32", "hybrid_int8".
    use_llm       : Whether to call the LLM for Stage 7 (default True).

    Returns
    -------
    dict with keys: probability, risk_level, recommendation, llm_recommendation,
                    selected_features, latency_ms, model_used.
    """
    _load_models()

    # --- Stage 1+2: Audio preprocessing + Feature extraction ---
    t0 = time.perf_counter()
    all_feats = extract_all_features(wav_path)

    # --- Stage 3: Feature selection ---
    feature_vector = np.array(
        [all_feats.get(f, 0.0) for f in _selected_features], dtype=np.float32
    ).reshape(1, -1)
    feature_dict = dict(zip(_selected_features, feature_vector.flatten().tolist()))

    # --- Stage 4: Scaling (feeds into angle encoding inside the quantum model) ---
    feature_scaled = _scaler.transform(feature_vector)
    x_tensor = torch.tensor(feature_scaled, dtype=torch.float32)

    # --- Stage 5: Model inference ---
    model_map = {
        "classical_fp32": _classical_fp32,
        "classical_int8": _classical_int8,
        "hybrid_fp32":    _hybrid_fp32,
        "hybrid_int8":    _hybrid_int8,
    }
    model = model_map.get(model_variant)
    if model is None:
        model = _classical_fp32
        model_variant = "classical_fp32 (fallback)"

    model.eval()
    with torch.no_grad():
        prob = float(model(x_tensor).squeeze())

    # --- Stage 6: Post-processing → risk level ---
    risk_level, rule_recommendation = _interpret(prob)

    inference_latency_ms = (time.perf_counter() - t0) * 1000

    # --- Stage 7: LLM recommendation ---
    if use_llm:
        llm_rec = generate_llm_recommendation(
            probability=prob,
            risk_level=risk_level,
            selected_features=feature_dict,
            model_used=model_variant,
        )
    else:
        llm_rec = rule_recommendation

    total_latency_ms = (time.perf_counter() - t0) * 1000

    return {
        "probability":       round(prob, 4),
        "risk_level":        risk_level,
        "recommendation":    rule_recommendation,      # fast rule-based (always present)
        "llm_recommendation": llm_rec,                 # LLM-generated (Stage 7)
        "selected_features": feature_dict,
        "inference_latency_ms": round(inference_latency_ms, 2),
        "latency_ms":        round(total_latency_ms, 2),
        "model_used":        model_variant,
    }
