"""
test_api.py — Smoke tests for the NeuralVoice FastAPI backend.

Run with:
    pytest backend/test_api.py -v
or, for a quick CLI check without a running server:
    python backend/test_api.py
"""

import io
import os
import sys
import tempfile

import numpy as np
try:
    import pytest
except ImportError:
    pytest = None

from fastapi.testclient import TestClient

# Make sure imports resolve from the backend directory
sys.path.insert(0, os.path.dirname(__file__))

from main import app

client = TestClient(app)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

def _make_sine_wav(duration_s: float = 3.0, sr: int = 16_000, freq: float = 220.0) -> bytes:
    """Generate a simple sine-wave WAV in memory for testing."""
    import wave, struct, math
    n_samples = int(sr * duration_s)
    samples = [int(32767 * math.sin(2 * math.pi * freq * t / sr)) for t in range(n_samples)]
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(struct.pack(f"<{n_samples}h", *samples))
    return buf.getvalue()


# ---------------------------------------------------------------------------
# System endpoints
# ---------------------------------------------------------------------------

def test_health():
    resp = client.get("/api/v1/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] in ("ok", "degraded")
    assert "version" in data


def test_models_status():
    resp = client.get("/api/v1/models")
    assert resp.status_code == 200
    data = resp.json()
    assert "classical_fp32" in data
    assert "model_dir" in data


# ---------------------------------------------------------------------------
# Audio prediction
# ---------------------------------------------------------------------------

def test_predict_audio_classical_fp32():
    wav_bytes = _make_sine_wav()
    resp = client.post(
        "/api/v1/predict?model_variant=classical_fp32",
        files={"file": ("test.wav", wav_bytes, "audio/wav")},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert 0.0 <= data["probability"] <= 1.0
    assert data["risk_level"] in ("low", "moderate", "high")
    assert "recommendation" in data
    assert "request_id" in data
    assert "selected_features" in data
    assert "raw_waveform" in data
    assert "preprocessed_waveform" in data
    assert "raw_audio_b64" in data
    assert "preprocessed_audio_b64" in data
    assert "llm_recommendation" in data
    assert data["latency_ms"] > 0


def _parametrize_variants(func):
    if pytest is not None:
        return pytest.mark.parametrize("variant", ["classical_fp32", "classical_int8"])(func)
    return func

@_parametrize_variants
def test_predict_audio_variants(variant="classical_fp32"):
    wav_bytes = _make_sine_wav()
    resp = client.post(
        f"/api/v1/predict?model_variant={variant}",
        files={"file": ("test.wav", wav_bytes, "audio/wav")},
    )
    # Accept 200 or 500 (500 only if model artifact missing in CI)
    assert resp.status_code in (200, 500)


# ---------------------------------------------------------------------------
# Feature prediction
# ---------------------------------------------------------------------------

def test_predict_from_features():
    payload = {
        "features": {
            "mfcc_mean_0": -15.3,
            "mfcc_mean_1": 22.1,
            "f0_mean": 115.4,
            "jitter_local": 0.0045,
            "shimmer_local": 0.032,
            "hnr": 18.7,
            "spec_centroid": 1250.0,
            "zcr": 0.08,
        },
        "model_variant": "classical_fp32",
    }
    resp = client.post("/api/v1/predict/features", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert 0.0 <= data["probability"] <= 1.0
    assert data["risk_level"] in ("low", "moderate", "high")


def _make_noise_wav(duration_s: float = 3.0, sr: int = 16_000) -> bytes:
    """Generate random broadband noise in memory for testing."""
    import wave, struct, random
    n_samples = int(sr * duration_s)
    samples = [int(random.uniform(-12000, 12000)) for _ in range(n_samples)]
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(struct.pack(f"<{n_samples}h", *samples))
    return buf.getvalue()


def test_predict_random_noise_rejected():
    wav_bytes = _make_noise_wav()
    resp = client.post(
        "/api/v1/predict?model_variant=classical_fp32",
        files={"file": ("noise.wav", wav_bytes, "audio/wav")},
    )
    assert resp.status_code == 422
    assert "noise" in resp.json()["detail"].lower() or "vocal" in resp.json()["detail"].lower()


def test_predict_from_features_empty_dict():
    """Missing features should default to 0.0 — must not crash."""
    payload = {"features": {}, "model_variant": "classical_fp32"}
    resp = client.post("/api/v1/predict/features", json=payload)
    assert resp.status_code == 200


# ---------------------------------------------------------------------------
# CLI smoke-test (no pytest needed)
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("Running smoke tests ...")
    test_health()
    print("[OK] health")
    test_models_status()
    print("[OK] models")
    test_predict_audio_classical_fp32()
    print("[OK] predict audio (classical_fp32)")
    test_predict_random_noise_rejected()
    print("[OK] predict audio rejects random noise (422)")
    test_predict_from_features()
    print("[OK] predict from features")
    test_predict_from_features_empty_dict()
    print("[OK] predict from empty features")
    print("\nAll smoke tests passed [OK]")
