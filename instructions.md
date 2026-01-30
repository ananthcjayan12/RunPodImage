
1.  **Corrected Flask Application (`log_server.py`)**:
    *   **Improvements**: Added proper error handling, input validation, and logging.
    *   **Features**: Implemented a `/health` endpoint for monitoring and a production-ready streaming logic with `Response` streaming and client disconnection handling.
    *   **Best Practices**: Used environment variables for configuration (`LOG_FILE_PATH`, `LOG_SERVER_PORT`), added signal handlers for graceful shutdown (SIGTERM/SIGINT), and enhanced the UI with CSS animations and better UX.

2.  **Comprehensive `Dockerfile`**:
    *   **Optimized Layer Caching**: Organized commands to maximize Docker layer reuse.
    *   **Security & Hardening**: Installed only necessary dependencies (`aria2`, `curl`, `procps`), cleaned up apt caches to reduce image size, and set proper file permissions.
    *   *Note*: Used `FROM runpod/comfyui:latest` as requested for flexibility.
    *   **Monitoring**: Added a `HEALTHCHECK` instruction to monitor the log server.

3.  **Master Entrypoint (`entrypoint.sh`)**:
    *   **Logic**: Orchestrates the background log server, conditional feature installation (Wan 2.1/2.2), and the single startup of ComfyUI.
    *   **Robustness**: Uses `set -e` for error detection, `pkill` to avoid duplicate processes, and `tee` to ensure logs are visible both in the UI and via `docker logs`.

4.  **GitHub Actions Workflow (`.github/workflows/publish.yml`)**:
    *   **Automation**: Automatically builds and publishes the image to GitHub Container Registry (GHCR) on pushes to `main`/`master` or new tags.
    *   **Standardization**: Uses `docker/metadata-action` for consistent tagging (e.g., `latest`, `sha-xxxx`, `v1.0`).
    *   **Accessibility**: Generates a summary with the public image URL for easy deployment.

### **Local Building and Testing Instructions**

**Build the image:**
```bash
docker build -t comfyui-modular:local .
```

**Run with specific features:**
```bash
docker run -d \
  -p 8188:8188 -p 8001:8001 \
  -e ENABLE_FEATURES="wan2.1,wan2.2" \
  --name comfyui-pod \
  comfyui-modular:local
```

**Verify health:**
```bash
curl http://localhost:8001/health
```

### **RunPod Template Configuration**
1.  **Image Name**: `ghcr.io/<your-github-username>/comfyui-modular:latest`
2.  **Environment Variables**: Set `ENABLE_FEATURES` to `wan2.1`, `wan2.2`, or both.
3.  **Exposed Ports**: `8188` (ComfyUI) and `8001` (Log Viewer).
4.  **Accessing Logs**: Once the pod is running, navigate to the `8001` proxy URL provided by RunPod.

Detailed design decisions and assumptions can be found in the newly created `plans/implementation_plan.md`.