# =============================================================================
# Modular ComfyUI - Slim Stable Base
# =============================================================================
# Base: NVIDIA CUDA 12.1 (Industry Standard Stability)
# =============================================================================

FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# Set non-interactive to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    ENABLE_FEATURES=""

# 1. Install System Essentials
# Added: ffmpeg (required for video models like Wan) and libgl1 (for OpenCV)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    git \
    curl \
    aria2 \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure python points to python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# 2. Install Python Core Dependencies
# We install Torch first to ensure it matches the CUDA version exactly
RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 3. Setup ComfyUI
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git runpod-slim/ComfyUI && \
    cd runpod-slim/ComfyUI && \
    pip install -r requirements.txt

# 4. Install Log Server Dependencies
RUN pip install --no-cache-dir --ignore-installed flask>=2.0.0

# 5. Application Assets
COPY setup_wan.sh setup_parallel.sh log_server.py entrypoint.sh /workspace/

# Standardize permissions and line endings (Crucial for execution stability)
RUN chmod +x /workspace/*.sh /workspace/*.py && \
    sed -i 's/\r$//' /workspace/*.sh

# Initial log setup
RUN touch /tmp/comfyui.log && chmod 666 /tmp/comfyui.log

# Ports
EXPOSE 8188 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

ENTRYPOINT ["/workspace/entrypoint.sh"]