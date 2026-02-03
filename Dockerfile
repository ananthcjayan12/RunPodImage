# Use a base that ALREADY has Torch and CUDA. This saves ~15 minutes of build time.
FROM pytorch/pytorch:2.2.1-cuda12.1-cudnn8-devel

# 1. System dependencies (Ordered by least likely to change)
RUN apt-get update && apt-get install -y --no-install-recommends \
    aria2 git curl ffmpeg libgl1 procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 2. Install ComfyUI dependencies (Cached unless requirements.txt changes)
# We clone and install BEFORE copying your custom scripts to keep this layer cached.
RUN git clone https://github.com/comfyanonymous/ComfyUI.git runpod-slim/ComfyUI && \
    pip install --no-cache-dir -r runpod-slim/ComfyUI/requirements.txt && \
    pip install --no-cache-dir flask>=2.0.0

# 3. Application Assets (These change often, so they go at the bottom)
# This way, editing a script only takes 2 seconds to rebuild.
COPY setup_wan.sh setup_parallel.sh log_server.py entrypoint.sh ./

RUN chmod +x *.sh && sed -i 's/\r$//' *.sh
RUN touch /tmp/comfyui.log && chmod 666 /tmp/comfyui.log

EXPOSE 8188 8001
ENTRYPOINT ["/bin/bash", "/workspace/entrypoint.sh"]