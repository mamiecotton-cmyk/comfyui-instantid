FROM registry.runpod.net/runpod-workers-worker-comfyui-main-dockerfile:d2a557235

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    cd ComfyUI_InstantID && \
    pip install -r requirements.txt
