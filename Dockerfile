FROM runpod/worker-comfyui:5.4.0-base

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    cd ComfyUI_InstantID && \
    pip install -r requirements.txt

# Add startup script that runs before the worker
RUN echo '#!/bin/bash\n\
echo "Linking network volume models..."\n\
for dir in checkpoints clip clip_vision configs controlnet embeddings instantid insightface loras upscale_models vae unet; do\n\
  if [ -d "/runpod-volume/models/$dir" ]; then\n\
    rm -rf /comfyui/models/$dir\n\
    ln -sf /runpod-volume/models/$dir /comfyui/models/$dir\n\
    echo "Linked $dir"\n\
  fi\n\
done\n\
if [ -d "/runpod-volume/custom_nodes" ]; then\n\
  for node in /runpod-volume/custom_nodes/*/; do\n\
    bn=$(basename $node)\n\
    if [ ! -d "/comfyui/custom_nodes/$bn" ]; then\n\
      ln -sf $node /comfyui/custom_nodes/$bn\n\
      echo "Linked custom node $bn"\n\
    fi\n\
  done\n\
fi\n\
exec /start.sh' > /usr/local/bin/init.sh && chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["/bin/bash", "/usr/local/bin/init.sh"]
