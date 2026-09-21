import sys
import os
from pathlib import Path

# Add backend directory to Python path
ROOT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT_DIR / "backend"))

import gradio as gr
from backend.main import app

with gr.Blocks(title="NeuroVoice API") as demo:
    gr.Markdown("# 🧠 NeuroVoice Clinical AI Backend")
    gr.Markdown("FastAPI service powered by v2 acoustic neural models.")
    gr.Markdown("### 🔗 Quick Links:")
    gr.Markdown("- **Interactive Swagger Docs**: [Open Swagger UI](/docs)")
    gr.Markdown("- **Health Status**: [Check /api/v1/health](/api/v1/health)")
    gr.Markdown("- **Active Models**: [View /api/v1/models](/api/v1/models)")

# Mount Gradio onto the existing FastAPI app at /gradio
# This leaves all FastAPI /api/v1/* routes completely untouched at root!
app = gr.mount_gradio_app(app, demo, path="/gradio")

@app.get("/")
def root_redirect():
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/docs")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
