"""
feature_extraction.py — Audio feature extraction pipeline.
Mirrors Section 3 from exported_models/v2-sih.ipynb exactly.
"""

import warnings
warnings.filterwarnings("ignore")

from pathlib import Path
import numpy as np
import librosa

# ---------------------------------------------------------------------------
# Configuration (mirrors v2-sih.ipynb)
# ---------------------------------------------------------------------------

SAMPLE_RATE = 16_000
N_MFCC = 13


def extract_librosa_features(y: np.ndarray, sr: int = SAMPLE_RATE) -> dict:
    """MFCCs, F0, ZCR, spectral features — classical acoustic features."""
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=N_MFCC)
    mfcc_mean = mfcc.mean(axis=1)
    mfcc_std = mfcc.std(axis=1)

    f0 = librosa.yin(y, fmin=50, fmax=500, sr=sr)
    f0 = f0[~np.isnan(f0)]
    f0_mean = float(np.mean(f0)) if len(f0) else 0.0
    f0_std = float(np.std(f0)) if len(f0) else 0.0

    zcr = float(librosa.feature.zero_crossing_rate(y).mean())
    spec_centroid = float(librosa.feature.spectral_centroid(y=y, sr=sr).mean())
    spec_rolloff = float(librosa.feature.spectral_rolloff(y=y, sr=sr).mean())

    feats = {}
    for i, v in enumerate(mfcc_mean):
        feats[f"mfcc_mean_{i}"] = float(v)
    for i, v in enumerate(mfcc_std):
        feats[f"mfcc_std_{i}"] = float(v)
    feats.update({
        "f0_mean": f0_mean,
        "f0_std": f0_std,
        "zcr": zcr,
        "spec_centroid": spec_centroid,
        "spec_rolloff": spec_rolloff,
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

        def _val(x):
            return 0.0 if (x is None or np.isnan(x)) else float(x)

        return {
            "jitter_local": _val(jitter_local),
            "jitter_rap":   _val(jitter_rap),
            "jitter_ppq5":  _val(jitter_ppq5),
            "shimmer_local": _val(shimmer_local),
            "shimmer_apq3":  _val(shimmer_apq3),
            "shimmer_apq5":  _val(shimmer_apq5),
            "hnr":           _val(hnr),
        }
    except Exception:
        # Return zeros if parselmouth is not installed or fails on this file
        return {
            "jitter_local": 0.0, "jitter_rap": 0.0, "jitter_ppq5": 0.0,
            "shimmer_local": 0.0, "shimmer_apq3": 0.0, "shimmer_apq5": 0.0,
            "hnr": 0.0,
        }


# ---------------------------------------------------------------------------
# Combined extraction (mirrors v2-sih.ipynb extract_all_features exactly)
# ---------------------------------------------------------------------------

def extract_all_features(
    wav_path: str,
    y: np.ndarray = None,
    sr: int = SAMPLE_RATE,
) -> dict:
    """
    Exact feature extraction pipeline matching v2-sih.ipynb:
      1. y, sr = librosa.load(wav_path, sr=16000, mono=True)
      2. y, _ = librosa.effects.trim(y, top_db=25)
      3. feats = extract_librosa_features(y, sr)
      4. feats.update(extract_praat_features(wav_path))
    """
    if y is None:
        y, sr = librosa.load(wav_path, sr=SAMPLE_RATE, mono=True)
    elif sr != SAMPLE_RATE:
        y = librosa.resample(y, orig_sr=sr, target_sr=SAMPLE_RATE)
        sr = SAMPLE_RATE

    if y.ndim > 1:
        y = np.mean(y, axis=1)

    # Trim silence with top_db=25 exactly as in v2-sih.ipynb
    y_trimmed, _ = librosa.effects.trim(y, top_db=25)
    if len(y_trimmed) == 0:
        y_trimmed = y

    feats = extract_librosa_features(y_trimmed, sr)
    feats.update(extract_praat_features(wav_path))
    return feats
