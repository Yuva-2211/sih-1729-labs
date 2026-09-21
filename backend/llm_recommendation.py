"""
llm_recommendation.py — LLM-powered clinical recommendation (Stage 7).

Uses Groq's Llama 3 model to generate a personalised, clinically-framed
recommendation based on the screening result and the top voice features
that drove the prediction.

Setup
-----
Set GROQ_API_KEY in your environment (free at https://console.groq.com):
    export GROQ_API_KEY="gsk_..."

Falls back to a rule-based recommendation if the key is not set.
"""

import logging
import os
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Feature-name human labels (for readable LLM prompts)
# ---------------------------------------------------------------------------

FEATURE_LABELS = {
    "mfcc_mean_0":  "MFCC-1 mean (vocal tract shape / spectral envelope)",
    "mfcc_mean_1":  "MFCC-2 mean (spectral tilt)",
    "mfcc_mean_2":  "MFCC-3 mean (spectral detail)",
    "mfcc_std_0":   "MFCC-1 std deviation (voice stability across time)",
    "mfcc_std_1":   "MFCC-2 std deviation (spectral variability)",
    "mfcc_std_2":   "MFCC-3 std deviation (formant bandwidth & resonance fluctuation)",
    "mfcc_std_3":   "MFCC-4 std deviation (formant variation)",
    "mfcc_std_4":   "MFCC-5 std deviation (fine spectral variation)",
    "mfcc_std_6":   "MFCC-7 std deviation (high-freq spectral variation)",
    "mfcc_std_10":  "MFCC-11 std deviation (detailed spectral energy variation)",
    "mfcc_std_11":  "MFCC-12 std deviation (subtle spectral variation)",
    "f0_mean":      "Mean fundamental frequency / pitch (F0)",
    "f0_std":       "Pitch variability (F0 std deviation)",
    "jitter_local": "Jitter – cycle-to-cycle pitch period irregularity",
    "jitter_rap":   "RAP Jitter – smoothed pitch irregularity",
    "jitter_ppq5":  "PPQ5 Jitter – 5-point smoothed pitch irregularity",
    "shimmer_local":"Shimmer – cycle-to-cycle amplitude irregularity",
    "shimmer_apq3": "APQ3 Shimmer – 3-point amplitude perturbation",
    "shimmer_apq5": "APQ5 Shimmer – 5-point amplitude perturbation",
    "hnr":          "Harmonics-to-Noise Ratio (voice clarity vs breathiness)",
    "zcr":          "Zero-crossing rate (voice noisiness / breathiness)",
    "spec_centroid":"Spectral centroid (brightness of the voice)",
    "spec_rolloff": "Spectral rolloff (energy distribution across frequencies)",
}

RISK_CONTEXT = {
    "low": (
        "The screening result is LOW RISK. "
        "The voice biomarkers are within normal range. "
        "No immediate clinical concern for Parkinson's Disease is indicated."
    ),
    "moderate": (
        "The screening result is MODERATE RISK. "
        "Some voice biomarkers show mild deviations that may warrant clinical attention. "
        "This is not a diagnosis — it is a screening signal."
    ),
    "high": (
        "The screening result is HIGH RISK. "
        "Multiple voice biomarkers show significant deviations consistent with "
        "dysphonia patterns associated with Parkinson's Disease. "
        "This is NOT a diagnosis — it is a screening signal requiring professional evaluation."
    ),
}


# ---------------------------------------------------------------------------
# Prompt builder
# ---------------------------------------------------------------------------

def _build_prompt(
    probability: float,
    risk_level: str,
    selected_features: dict[str, float],
    model_used: str,
    patient_name: str = "Participant",
) -> str:
    """Build a clinically-framed prompt for the LLM."""

    # Top 3 features by absolute value (most influential for this prediction)
    sorted_feats = sorted(selected_features.items(), key=lambda x: abs(x[1]), reverse=True)[:3]
    feat_lines = "\n".join(
        f"  • {FEATURE_LABELS.get(k, k)}: {v:.4f}"
        for k, v in sorted_feats
    )

    risk_ctx = RISK_CONTEXT.get(risk_level, RISK_CONTEXT["moderate"])

    prompt = f"""You are a clinical voice analysis assistant for a Parkinson's Disease early-screening application (SIH26139). 
You help patients and caregivers understand a non-invasive voice screening result.

PATIENT / PARTICIPANT: {patient_name}

SCREENING RESULT:
- Risk Level: {risk_level.upper()}
- PD Risk Probability: {probability * 100:.1f}%
- Model: Hybrid Quantum-Classical ML ({model_used})
- Context: {risk_ctx}

KEY VOICE BIOMARKERS (top contributors to this result):
{feat_lines}

IMPORTANT DISCLAIMERS TO INCLUDE:
- This is a screening tool, NOT a diagnostic device.
- Only a qualified neurologist can diagnose Parkinson's Disease.
- Voice biomarkers can be affected by other conditions (vocal infections, aging, stress).

YOUR TASK:
Write a clear, compassionate, and medically responsible recommendation for {patient_name} in 3–4 short paragraphs:
1. Summarise what the screening found for {patient_name} in plain language (no jargon).
2. Explain what the key voice features mean in simple terms and how they relate to Parkinsonian voice changes.
3. Give a concrete next-step recommendation based on the risk level.
4. End with a reassuring note emphasising the importance of professional evaluation.

Keep the tone warm and human — the reader may be a worried patient or caregiver.
Do NOT use bullet points. Write in flowing paragraphs. Maximum 200 words.
"""
    return prompt


# ---------------------------------------------------------------------------
# Groq LLM call
# ---------------------------------------------------------------------------

def generate_llm_recommendation(
    probability: float,
    risk_level: str,
    selected_features: dict[str, float],
    model_used: str,
    patient_name: str = "Participant",
    groq_api_key: Optional[str] = None,
) -> str:
    """
    Generate an LLM-powered recommendation using Groq Llama 3.

    Returns the recommendation string.
    Falls back to a rule-based recommendation if Groq is unavailable.
    """
    api_key = groq_api_key or os.environ.get("GROQ_API_KEY", "")

    if not api_key:
        logger.warning("GROQ_API_KEY not set — using rule-based recommendation fallback.")
        return _fallback_recommendation(probability, risk_level)

    try:
        from groq import Groq

        # Add strict timeout (3.5s) and max_retries (1) so LLM never stalls mobile response
        client = Groq(api_key=api_key, timeout=3.5, max_retries=1)

        prompt = _build_prompt(probability, risk_level, selected_features, model_used, patient_name=patient_name)

        # Use fast, robust Groq models: llama-3.1-8b-instant provides sub-second clinical summaries
        try:
            model_name = "llama-3.1-8b-instant"
            response = client.chat.completions.create(
                model=model_name,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are a concise, compassionate clinical assistant "
                            "helping patients understand a non-diagnostic voice screening result. "
                            "Always remind users to consult a neurologist."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                temperature=0.3,
                max_tokens=250,
            )
        except Exception:
            # Fallback to llama-3.3-70b-versatile if 8b is unavailable
            response = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a concise clinical voice screening assistant. Remind users to consult a neurologist.",
                    },
                    {"role": "user", "content": prompt},
                ],
                temperature=0.3,
                max_tokens=250,
            )

        recommendation = response.choices[0].message.content.strip()
        logger.info("LLM recommendation generated (%d chars).", len(recommendation))
        return recommendation

    except Exception as exc:
        logger.warning("Groq LLM call timed out or failed: %s — using rule fallback.", exc)
        return _fallback_recommendation(probability, risk_level, patient_name=patient_name)


# ---------------------------------------------------------------------------
# Rule-based fallback (no API key needed)
# ---------------------------------------------------------------------------

_FALLBACK_TEMPLATES = {
    "low": (
        "Clinical voice screening for {name} indicates a LOW likelihood of Parkinson's Disease-related acoustic changes. "
        "The voice biomarkers analysed — including fundamental pitch stability, amplitude consistency, and spectral envelope "
        "— fall within normal physiological ranges.\n\n"
        "While this is an encouraging result, remember that this is a non-invasive screening tool, "
        "not a clinical diagnosis. If you or {name} experience tremors, stiffness, or speech fatigue, "
        "please consult a neurologist regardless of this score.\n\n"
        "We recommend repeating this screening periodically to track vocal biomarker stability over time."
    ),
    "moderate": (
        "Clinical voice screening for {name} shows a MODERATE likelihood of vocal biomarker deviations. "
        "Certain acoustic features — such as pitch micro-variations or spectral tilt — exhibit mild irregularities "
        "compared to baseline healthy phonation. This is not a diagnosis of Parkinson's Disease.\n\n"
        "Moderate variations can also stem from temporary vocal fatigue, respiratory conditions, "
        "reflux, or stress. However, an evaluation with a neurologist or speech specialist is recommended "
        "to ensure comprehensive monitoring.\n\n"
        "Please schedule a consultation with a specialist and present this report for reference."
    ),
    "high": (
        "Clinical voice screening for {name} indicates an ELEVATED / HIGH likelihood of voice patterns associated with Parkinson's Disease. "
        "Multiple acoustic biomarkers — including cycle-to-cycle frequency perturbations (jitter), amplitude variation "
        "(shimmer), and spectral energy dispersion — show significant deviations characteristic of hypophonia and dysphonia.\n\n"
        "This is NOT a medical diagnosis. Only a licensed neurologist or movement disorder specialist can diagnose Parkinson's Disease "
        "through comprehensive clinical examination. Several treatable conditions can also cause vocal instability.\n\n"
        "We strongly advise booking a neurological consultation promptly. Please share this detailed biomarker report with your physician."
    ),
}


def _fallback_recommendation(probability: float, risk_level: str, patient_name: str = "Participant") -> str:
    tmpl = _FALLBACK_TEMPLATES.get(risk_level, _FALLBACK_TEMPLATES["moderate"])
    return tmpl.format(name=patient_name)
