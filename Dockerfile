FROM runpod/worker-comfyui:5.4.0-base

# Create symlinks from internal paths to network volume
RUN echo '#!/bin/bash\n\
for dir in checkpoints clip clip_vision configs controlnet embeddings instantid insightface loras upscale_models vae unet; do\n\
  if [ -d "/runpod-volume/models/$dir" ]; then\n\
    ln -sf /runpod-volume/models/$dir /comfyui/models/$dir\n\
  fi\n\
done\n\
if [ -d "/runpod-volume/custom_nodes" ]; then\n\
  for node in /runpod-volume/custom_nodes/*/; do\n\
    ln -sf $node /comfyui/custom_nodes/$(basename $node)\n\
  done\n\
fi\n\
exec "$@"' > /usr/local/bin/link-volume.sh && chmod +x /usr/local/bin/link-volume.sh

RUN cd /comfyui/custom_nodes && \
    git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    cd ComfyUI_InstantID && \
    pip install -r requirements.txt

ENTRYPOINT ["/usr/local/bin/link-volume.sh"]
CMD ["/start.sh"]
