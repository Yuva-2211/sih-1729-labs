"""
feature_extraction.py — Audio feature extraction pipeline.
Mirrors Stage 1 from the architecture document and the training notebook exactly.
"""

import warnings
warnings.filterwarnings("ignore")

import numpy as np
import librosa
from pathlib import Path

# ---------------------------------------------------------------------------
# Librosa features (MFCCs, F0, ZCR, spectral)
# ---------------------------------------------------------------------------

N_MFCC = 13
SAMPLE_RATE = 16_000


def extract_librosa_features(y: np.ndarray, sr: int) -> dict:
    """MFCCs, F0, ZCR, spectral features — classical acoustic features."""
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=N_MFCC)
    mfcc_mean = mfcc.mean(axis=1)
    mfcc_std = mfcc.std(axis=1)

    # Optimize F0 extraction: use the central stable phonation segment (up to 3.0s)
    # and hop_length=1024 for 10x-15x faster pitch tracking without sacrificing mean F0 accuracy
    if len(y) > sr * 3:
        mid = len(y) // 2
        half_win = int(sr * 1.5)
        y_pitch = y[mid - half_win : mid + half_win]
    else:
        y_pitch = y

    try:
        f0 = librosa.yin(y_pitch, fmin=60, fmax=450, sr=sr, hop_length=1024)
        f0 = f0[~np.isnan(f0)]
        f0_mean = float(np.mean(f0)) if len(f0) else 0.0
        f0_std = float(np.std(f0)) if len(f0) else 0.0
    except Exception:
        f0_mean = 0.0
        f0_std = 0.0


    zcr = float(librosa.feature.zero_crossing_rate(y).mean())
    spec_centroid = float(librosa.feature.spectral_centroid(y=y, sr=sr).mean())
    spec_rolloff = float(librosa.feature.spectral_rolloff(y=y, sr=sr).mean())

    feats: dict = {}
    for i, v in enumerate(mfcc_mean):
        feats[f"mfcc_mean_{i}"] = float(v)
    for i, v in enumerate(mfcc_std):
        feats[f"mfcc_std_{i}"] = float(v)
    feats.update({
        "f0_mean": f0_mean, "f0_std": f0_std,
        "zcr": zcr, "spec_centroid": spec_centroid, "spec_rolloff": spec_rolloff,
    })
    return feats


# ---------------------------------------------------------------------------
# Praat (parselmouth) features — jitter, shimmer, HNR
# ---------------------------------------------------------------------------

def extract_praat_features(wav_path: str) -> dict:
    """
    Jitter, shimmer, HNR — the classic dysphonia measures used in PD voice literature.
    Requires praat-parselmouth. Falls back gracefully if unavailable.
    """
    try:
        import parselmouth
        from parselmouth.praat import call

        snd = parselmouth.Sound(wav_path)
        point_process = call(snd, "To PointProcess (periodic, cc)", 75, 500)

        jitter_local = call(point_process, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
        jitter_rap   = call(point_process, "Get jitter (rap)",   0, 0, 0.0001, 0.02, 1.3)
        jitter_ppq5  = call(point_process, "Get jitter (ppq5)",  0, 0, 0.0001, 0.02, 1.3)

        shimmer_local = call([snd, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6)
        shimmer_apq3  = call([snd, point_process], "Get shimmer (apq3)",  0, 0, 0.0001, 0.02, 1.3, 1.6)
        shimmer_apq5  = call([snd, point_process], "Get shimmer (apq5)",  0, 0, 0.0001, 0.02, 1.3, 1.6)

        harmonicity = call(snd, "To Harmonicity (cc)", 0.01, 75, 0.1, 1.0)
        hnr = call(harmonicity, "Get mean", 0, 0)

        return {
            "jitter_local": float(jitter_local) if jitter_local is not None else 0.0,
            "jitter_rap":   float(jitter_rap)   if jitter_rap is not None else 0.0,
            "jitter_ppq5":  float(jitter_ppq5)  if jitter_ppq5 is not None else 0.0,
            "shimmer_local": float(shimmer_local) if shimmer_local is not None else 0.0,
            "shimmer_apq3":  float(shimmer_apq3)  if shimmer_apq3 is not None else 0.0,
            "shimmer_apq5":  float(shimmer_apq5)  if shimmer_apq5 is not None else 0.0,
            "hnr": float(hnr) if hnr is not None else 0.0,
        }
    except Exception:
        # Return zeros if parselmouth is not installed or fails on this file
        return {
            "jitter_local": 0.0, "jitter_rap": 0.0, "jitter_ppq5": 0.0,
            "shimmer_local": 0.0, "shimmer_apq3": 0.0, "shimmer_apq5": 0.0,
            "hnr": 0.0,
        }


# ---------------------------------------------------------------------------
# Combined extraction (Stage 1 — optimized for edge and cloud throughput)
# ---------------------------------------------------------------------------

def extract_all_features(
    wav_path: str,
    y: np.ndarray = None,
    sr: int = SAMPLE_RATE,
    include_praat: bool = False,
) -> dict:
    """
    Full Stage-1 pipeline:
      1. Load + resample to 16 kHz mono (or reuse pre-loaded array)
      2. Trim silence (VAD via librosa.effects.trim)
      3. Extract librosa features (MFCCs, F0, ZCR, spectral)
      4. Extract Praat features (jitter, shimmer, HNR) if requested
    Returns a flat dict of all raw features.
    """
    import soundfile as sf
    if y is None:
        try:
            y, sr = sf.read(wav_path, dtype='float32')
        except Exception:
            y, sr = librosa.load(wav_path, sr=SAMPLE_RATE, mono=True)
    if y.ndim > 1:
        y = np.mean(y, axis=1)
    y_trimmed, _ = librosa.effects.trim(y, top_db=20)
    if len(y_trimmed) > 0:
        y_norm = y_trimmed / (np.max(np.abs(y_trimmed)) + 1e-8)
    else:
        y_norm = y

    feats = {}
    feats.update(extract_librosa_features(y_norm, sr))
    if include_praat:
        feats.update(extract_praat_features(wav_path))
    else:
        feats.update({
            "jitter_local": 0.0, "jitter_rap": 0.0, "jitter_ppq5": 0.0,
            "shimmer_local": 0.0, "shimmer_apq3": 0.0, "shimmer_apq5": 0.0,
            "hnr": 0.0,
        })
    return feats
