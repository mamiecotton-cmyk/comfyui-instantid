FROM runpod/worker-comfyui:5.4.0-base

ARG HF_TOKEN

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    cd ComfyUI_InstantID && \
    pip install -r requirements.txt

RUN mkdir -p /comfyui/models/instantid && \
    wget -q --show-progress \
    --header="Authorization: Bearer ${HF_TOKEN}" \
    -O /comfyui/models/instantid/ip-adapter.bin \
    "https://huggingface.co/InstantX/InstantID/resolve/main/ip-adapter.bin"

RUN printf '#!/bin/bash\n\
echo "Waiting for volume mount..."\n\
sleep 3\n\
for dir in checkpoints clip clip_vision configs controlnet embeddings insightface loras upscale_models vae unet diffusion_models text_encoders; do\n\
  if [ -d "/runpod-volume/models/$dir" ]; then\n\
    rm -rf /comfyui/models/$dir\n\
    ln -sf /runpod-volume/models/$dir /comfyui/models/$dir\n\
    echo "Linked: $dir"\n\
  fi\n\
done\n\
exec /start.sh' > /usr/local/bin/init.sh && chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["/bin/bash", "/usr/local/bin/init.sh"]
