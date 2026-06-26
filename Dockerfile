FROM runpod/worker-comfyui:5.4.0-base

ARG HF_TOKEN

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    cd ComfyUI_InstantID && \
    pip install -r requirements.txt

# --- PuLID-Flux (face lock for Flux generations) ---
RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll.git && \
    cd ComfyUI_PuLID_Flux_ll && \
    pip install -r requirements.txt && \
    pip install facenet-pytorch --no-deps

# Patch PuLID for ComfyUI's timestep_zero_index arg
RUN sed -i 's/    attn_mask: Tensor = None,/    attn_mask: Tensor = None,\n    timestep_zero_index=None,/' \
    /comfyui/custom_nodes/ComfyUI_PuLID_Flux_ll/PulidFluxHook.py || true

RUN mkdir -p /comfyui/models/instantid && \
    wget -q --show-progress \
    --header="Authorization: Bearer ${HF_TOKEN}" \
    -O /comfyui/models/instantid/ip-adapter.bin \
    "https://huggingface.co/InstantX/InstantID/resolve/main/ip-adapter.bin"

RUN printf '#!/bin/bash\n\
echo "Waiting for volume mount..."\n\
sleep 3\n\
for dir in checkpoints clip clip_vision configs controlnet embeddings insightface loras upscale_models vae unet diffusion_models text_encoders pulid; do\n\
  if [ -d "/runpod-volume/models/$dir" ]; then\n\
    rm -rf /comfyui/models/$dir\n\
    ln -sf /runpod-volume/models/$dir /comfyui/models/$dir\n\
    echo "Linked: $dir"\n\
  fi\n\
done\n\
mkdir -p /comfyui/input\n\
if [ -d /runpod-volume/pulid_refs ]; then\n\
  cp /runpod-volume/pulid_refs/* /comfyui/input/ 2>/dev/null\n\
  echo "Copied PuLID references"\n\
fi\n\
exec /start.sh' > /usr/local/bin/init.sh && chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["/bin/bash", "/usr/local/bin/init.sh"]
