# =============================================================================
# Modular ComfyUI Docker Image
# =============================================================================
# Base: runpod/comfyui with selective feature installation
# Features: Wan 2.1, Wan 2.2, Real-time log streaming
# =============================================================================

# Use latest tag for flexibility as requested (pin to SHA for strict reproducibility)
FROM runpod/comfyui:latest

# Metadata
LABEL org.opencontainers.image.title="ComfyUI Modular"
LABEL org.opencontainers.image.description="Modular ComfyUI with selective feature installation"
LABEL org.opencontainers.image.source="https://github.com/OWNER/REPO"
LABEL org.opencontainers.image.licenses="MIT"

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    ENABLE_FEATURES="" \
    LOG_FILE_PATH="/tmp/comfyui.log" \
    LOG_SERVER_PORT="8001"

# Install system dependencies
# aria2 is required for high-speed downloads in setup scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    aria2 \
    curl \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Python dependencies for log server
RUN pip install --no-cache-dir --ignore-installed flask>=2.0.0

# Create workspace directory and setup ComfyUI
RUN mkdir -p /workspace && cd /workspace && \
    git clone https://github.com/comfyanonymous/ComfyUI.git runpod-slim/ComfyUI && \
    cd runpod-slim/ComfyUI && \
    pip install --no-cache-dir -r requirements.txt

# Set working directory
WORKDIR /workspace

# Copy setup scripts (pre-tested, do not modify)
COPY setup_wan.sh /workspace/setup_wan.sh
COPY setup_parallel.sh /workspace/setup_parallel.sh

# Copy application files
COPY log_server.py /workspace/log_server.py
COPY entrypoint.sh /workspace/entrypoint.sh

# Set permissions and verify files exist
RUN chmod +x /workspace/setup_wan.sh \
    && chmod +x /workspace/setup_parallel.sh \
    && chmod +x /workspace/entrypoint.sh \
    && chmod +x /workspace/log_server.py \
    && ls -la /workspace/entrypoint.sh

# Create log file directory and set initial permissions
RUN mkdir -p /tmp && touch /tmp/comfyui.log && chmod 666 /tmp/comfyui.log

# Expose ports
# 8188: ComfyUI web interface
# 8001: Log streaming server
EXPOSE 8188 8001

# Health check (checks log server health)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Entrypoint
ENTRYPOINT ["/workspace/entrypoint.sh"]
