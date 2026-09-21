import sys
import os
from pathlib import Path

# Add backend directory to Python path
ROOT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT_DIR / "backend"))

import gradio as gr

try:
    import spaces
except ImportError:
    class spaces:
        @staticmethod
        def GPU(fn=None, duration=60):
            def decorator(f):
                return f
            return decorator if fn is None else fn

from backend.main import app
import inference

@spaces.GPU
def analyze_voice_demo(audio_file):
    if not audio_file:
        return "Please upload or record an audio file."
    try:
        res = inference.predict_from_audio_file(audio_file, model_variant="classical_fp32")
        return (
            f"### Result:\n"
            f"- **Diagnosis**: {res.get('prediction', 'Unknown')}\n"
            f"- **Risk Level**: {res.get('risk_level', 'Unknown')}\n"
            f"- **Confidence**: {res.get('confidence', 0.0) * 100:.1f}%\n"
            f"- **Inference Time**: {res.get('inference_time_ms', 0):.1f} ms"
        )
    except Exception as e:
        return f"Error analyzing audio: {str(e)}"

with gr.Blocks(title="NeuroVoice API") as demo:
    gr.Markdown("# 🧠 NeuroVoice Clinical AI Backend")
    gr.Markdown("FastAPI service powered by v2 acoustic neural models & ZeroGPU acceleration.")
    
    with gr.Row():
        audio_input = gr.Audio(sources=["upload", "microphone"], type="filepath", label="Patient Voice Sample (/a/ phonation)")
        output_text = gr.Markdown(label="Analysis Result")
    
    btn = gr.Button("Analyze Voice with NeuroVoice AI", variant="primary")
    btn.click(fn=analyze_voice_demo, inputs=audio_input, outputs=output_text)
    
    gr.Markdown("---")
    gr.Markdown("### 🔗 Developer & Mobile API Links:")
    gr.Markdown("- **Interactive Swagger Docs**: [Open Swagger UI](/docs)")
    gr.Markdown("- **Health Status**: [Check /api/v1/health](/api/v1/health)")
    gr.Markdown("- **Active Models**: [View /api/v1/models](/api/v1/models)")

# Mount Gradio onto the existing FastAPI app at root /
app = gr.mount_gradio_app(app, demo, path="/")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
