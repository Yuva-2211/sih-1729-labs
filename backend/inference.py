"""
inference.py — Model loading and inference logic.
Loads all four saved model variants + the preprocessing artifacts and exposes
a single `predict()` function used by the API routes.
"""

import logging
import os
import time
import io
import base64
from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import torch
import soundfile as sf

from models import ClassicalModel, build_hybrid_model
from feature_extraction import extract_all_features
from llm_recommendation import generate_llm_recommendation

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).parent
# Use v2 model artifacts exclusively as serving models (supports Docker / Cloud deployment)
_env_model_dir = os.environ.get("MODEL_DIR")
if _env_model_dir and Path(_env_model_dir).exists():
    MODEL_DIR = Path(_env_model_dir)
elif (BASE_DIR.parent / "model_v2" / "v2-model-training").exists():
    MODEL_DIR = BASE_DIR.parent / "model_v2" / "v2-model-training"
elif (BASE_DIR / "model_v2" / "v2-model-training").exists():
    MODEL_DIR = BASE_DIR / "model_v2" / "v2-model-training"
elif (BASE_DIR.parent / "model_v2" / "v2-model training").exists():
    MODEL_DIR = BASE_DIR.parent / "model_v2" / "v2-model training"
elif (BASE_DIR / "model_v2" / "v2-model training").exists():
    MODEL_DIR = BASE_DIR / "model_v2" / "v2-model training"
elif (BASE_DIR / "model").exists():
    MODEL_DIR = BASE_DIR / "model"
else:
    MODEL_DIR = BASE_DIR.parent / "model_v2" / "v2-model-training"

if not MODEL_DIR.exists():
    raise FileNotFoundError(f"V2 Serving model directory not found at: {MODEL_DIR}")

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
    try:
        engines = torch.backends.quantized.supported_engines
        if "onednn" in engines:
            torch.backends.quantized.engine = "onednn"
        elif "fbgemm" in engines:
            torch.backends.quantized.engine = "fbgemm"
        elif "qnnpack" in engines:
            torch.backends.quantized.engine = "qnnpack"
        elif engines:
            torch.backends.quantized.engine = engines[0]

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
        if _hybrid_fp32 is not None:
            _hybrid_fp32.load_state_dict(
                torch.load(MODEL_DIR / "hybrid_quantum_fp32.pt", map_location="cpu", weights_only=True)
            )
            _hybrid_fp32.eval()
            logger.info("Hybrid FP32 model loaded successfully.")
        else:
            logger.warning("Hybrid FP32 model skipped: PennyLane is not available.")
    except Exception as exc:
        logger.warning("Could not load hybrid FP32 model: %s", exc)
        _hybrid_fp32 = None

    # --- Hybrid INT8 ---
    try:
        engines = torch.backends.quantized.supported_engines
        if "onednn" in engines:
            torch.backends.quantized.engine = "onednn"
        elif "fbgemm" in engines:
            torch.backends.quantized.engine = "fbgemm"
        elif "qnnpack" in engines:
            torch.backends.quantized.engine = "qnnpack"
        elif engines:
            torch.backends.quantized.engine = engines[0]

        _hybrid_int8 = build_hybrid_model()
        if _hybrid_int8 is not None:
            _hybrid_int8 = torch.quantization.quantize_dynamic(
                _hybrid_int8, {torch.nn.Linear}, dtype=torch.qint8
            )
            _hybrid_int8.load_state_dict(
                torch.load(MODEL_DIR / "hybrid_quantum_quantized.pt", map_location="cpu", weights_only=True)
            )
            _hybrid_int8.eval()
            logger.info("Hybrid INT8 model loaded successfully.")
        else:
            logger.warning("Hybrid INT8 model skipped: PennyLane is not available.")
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

def _downsample(arr: np.ndarray, n: int = 200) -> list:
    """Downsample a 1-D array to n evenly-spaced points for transport."""
    if len(arr) == 0:
        return [0.0] * n
    indices = np.linspace(0, len(arr) - 1, n, dtype=int)
    return arr[indices].tolist()


class AudioQualityError(ValueError):
    """Raised when audio is pure noise, silence, or lacks sustained vocal phonation."""
    pass


def validate_audio_quality(y: np.ndarray, sr: int = 16_000):
    """
    Lightweight audio validation — pure numpy, NO librosa STFT calls.

    On Render Free Tier (0.1 vCPU), each librosa STFT pass on 100K+ samples
    takes 10-30 seconds, making the full validation (4 STFT passes) take minutes.
    This stripped-down version checks RMS energy, duration, and basic periodicity
    using only numpy operations that complete in < 1 ms.
    """
    # 1. Duration check
    duration_s = len(y) / sr
    if duration_s < 0.3:
        raise AudioQualityError(
            f"Audio too short ({duration_s:.2f}s). "
            "Please record at least 3 seconds of sustained vowel 'aaah'."
        )

    # 2. RMS Energy — pure numpy, no librosa
    rms = float(np.sqrt(np.mean(y ** 2)))
    if rms < 0.001:
        raise AudioQualityError(
            f"Audio is too faint or silent (RMS energy: {rms:.4f} < 0.001). "
            "Please check your microphone and speak clearly."
        )

    # 3. Quick periodicity check via small autocorrelation on a 0.1s frame
    # This detects pure noise without any STFT overhead
    frame_len = min(int(0.1 * sr), len(y) // 2)
    if frame_len >= 200:
        mid = len(y) // 2
        frame = y[mid - frame_len // 2 : mid + frame_len // 2]
        corr = np.correlate(frame, frame, mode='full')
        corr = corr[len(corr) // 2:]
        if corr[0] > 0:
            norm_corr = corr / corr[0]
            # Check for any peak in human pitch range (65-450 Hz)
            lo = max(int(sr / 450), 1)
            hi = min(int(sr / 65), len(norm_corr))
            if hi > lo:
                pitch_peak = float(np.max(norm_corr[lo:hi]))
                if pitch_peak < 0.05:
                    raise AudioQualityError(
                        f"No vocal sound detected (periodicity: {pitch_peak:.3f}). "
                        "Please produce a clear, sustained vowel sound like 'aaah'."
                    )



def predict(
    wav_path: str,
    model_variant: str = "classical_fp32",
    use_llm: bool = True,
    patient_name: str = "Participant",
) -> dict:
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
    """
    _load_models()

    # --- Stage 1+2: Audio preprocessing + Feature extraction ---
    t0 = time.perf_counter()
    logger.info("[inference] Starting prediction for audio: %s (variant=%s, use_llm=%s)", wav_path, model_variant, use_llm)

    # Capture raw waveform BEFORE any processing (fast single read)
    try:
        _y_raw, _sr_raw = sf.read(wav_path, dtype='float32')
        if _sr_raw != 16_000:
            import librosa as _librosa
            _y_raw = _librosa.resample(_y_raw, orig_sr=_sr_raw, target_sr=16_000)
            _sr_raw = 16_000
    except Exception:
        import librosa as _librosa
        _y_raw, _sr_raw = _librosa.load(wav_path, sr=16_000, mono=True)

    if _y_raw.ndim > 1:
        _y_raw = np.mean(_y_raw, axis=1)

    dur_s = len(_y_raw) / _sr_raw
    logger.info("[inference] Stage 1: Loaded audio: duration=%.2fs, samples=%d", dur_s, len(_y_raw))

    # Validate audio quality to immediately reject random noise or silence
    validate_audio_quality(_y_raw, _sr_raw)
    logger.info("[inference] Stage 1: Quality check passed (valid sustained phonation)")

    raw_waveform = _downsample(_y_raw)

    # Encode raw audio as base64 WAV for client-side playback
    _raw_buf = io.BytesIO()
    sf.write(_raw_buf, _y_raw, 16_000, format='WAV', subtype='PCM_16')
    raw_audio_b64 = base64.b64encode(_raw_buf.getvalue()).decode('utf-8')

    # --- Truncate to max 3.0s for feature extraction ---
    # On Render Free Tier (0.1 vCPU), each librosa STFT pass scales with sample count.
    # Truncating from 6-8s (100K+ samples) to 3s (48K samples) halves ALL downstream costs.
    MAX_FEAT_SAMPLES = int(3.0 * _sr_raw)
    if len(_y_raw) > MAX_FEAT_SAMPLES:
        # Use the central stable segment for best feature accuracy
        mid = len(_y_raw) // 2
        half = MAX_FEAT_SAMPLES // 2
        _y_feat = _y_raw[mid - half : mid + half]
        logger.info("[inference] Stage 1: Truncated %d → %d samples (3.0s) for feature extraction", len(_y_raw), len(_y_feat))
    else:
        _y_feat = _y_raw

    t_feat_start = time.perf_counter()
    all_feats = extract_all_features(wav_path, y=_y_feat, sr=_sr_raw)
    logger.info("[inference] Stage 2: Feature extraction completed in %.1f ms", (time.perf_counter() - t_feat_start) * 1000)

    # Preprocessed waveform — simple numpy normalization (no librosa.effects.trim STFT)
    _y_proc = _y_feat / (np.max(np.abs(_y_feat)) + 1e-8)
    preprocessed_waveform = _downsample(_y_proc)

    # Encode preprocessed audio as base64 WAV for client-side playback
    _proc_buf = io.BytesIO()
    sf.write(_proc_buf, _y_proc.astype(np.float32), 16_000, format='WAV', subtype='PCM_16')
    preprocessed_audio_b64 = base64.b64encode(_proc_buf.getvalue()).decode('utf-8')

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

    t_infer_start = time.perf_counter()
    model.eval()
    with torch.no_grad():
        prob = float(model(x_tensor).squeeze())

    inference_latency_ms = (time.perf_counter() - t_infer_start) * 1000
    logger.info("[inference] Stage 5: %s inference completed in %.1f ms | raw_prob=%.4f", model_variant, inference_latency_ms, prob)

    # --- Stage 6: Post-processing → risk level ---
    risk_level, rule_recommendation = _interpret(prob)

    # --- Stage 7: LLM recommendation ---
    if use_llm:
        t_llm_start = time.perf_counter()
        llm_rec = generate_llm_recommendation(
            probability=prob,
            risk_level=risk_level,
            selected_features=feature_dict,
            model_used=model_variant,
            patient_name=patient_name,
        )
        logger.info("[inference] Stage 7: LLM finished in %.1f ms", (time.perf_counter() - t_llm_start) * 1000)
    else:
        llm_rec = rule_recommendation

    total_latency_ms = (time.perf_counter() - t0) * 1000
    logger.info("[inference] Pipeline complete in %.1f ms | risk=%s", total_latency_ms, risk_level)

    return {
        "probability":              round(prob, 4),
        "risk_level":               risk_level,
        "recommendation":           rule_recommendation,
        "llm_recommendation":       llm_rec,
        "selected_features":        feature_dict,
        "inference_latency_ms":     round(inference_latency_ms, 2),
        "latency_ms":               round(total_latency_ms, 2),
        "model_used":               model_variant,
        "raw_waveform":             raw_waveform,
        "preprocessed_waveform":    preprocessed_waveform,
        "raw_audio_b64":            raw_audio_b64,
        "preprocessed_audio_b64":   preprocessed_audio_b64,
        "patient_name":             patient_name,
    }


if __name__ == "__main__":
    import json
    import wave
    import struct
    import math
    import tempfile

    print("=" * 60)
    print(" NeuralVoice — PD Voice Analysis Inference Engine")
    print("=" * 60)

    print("\n1. Checking models status...")
    status = get_models_status()
    for k, v in status.items():
        print(f"  • {k}: {v}")

    print("\n2. Generating synthetic voice test sample (3.0s sine wave)...")
    sr = 16000
    duration_s = 3.0
    freq = 220.0
    n_samples = int(sr * duration_s)
    samples = [int(32767 * math.sin(2 * math.pi * freq * t / sr)) for t in range(n_samples)]

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
        tmp_path = tmp_file.name
        with wave.open(tmp_path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sr)
            wf.writeframes(struct.pack(f"<{n_samples}h", *samples))

    try:
        print(f"3. Running inference pipeline on {tmp_path}...")
        result = predict(tmp_path, model_variant="classical_fp32", use_llm=False)
        print("\n--- INFERENCE RESULT ---")
        print(json.dumps(result, indent=2))
        print("------------------------")

        if status.get("classical_int8"):
            print("\n4. Running quantized INT8 model inference...")
            res_int8 = predict(tmp_path, model_variant="classical_int8", use_llm=False)
            print(f"  • INT8 Probability : {res_int8['probability']}")
            print(f"  • INT8 Risk Level  : {res_int8['risk_level']}")
            print(f"  • INT8 Latency     : {res_int8['latency_ms']} ms")

        print("\nPipeline execution succeeded!")
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
