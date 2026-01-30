## 🛠️ Project: Modular ComfyUI Docker Environment

**Objective:** Create a Docker image based on `runpod/comfyui` that can selectively install features (like Wan2.1 or Wan2.2) based on environment variables and provides a real-time web-based log viewer.

---

### 1. Repository Structure

Ensure the GitHub repository is organized as follows:

* `Dockerfile`: The main build instructions.
* `setup_parallel.sh`: The script for Wan 2.1 and Infinite Talk downloads.
* `setup_wan.sh`: The script for Wan 2.2 downloads.
* `log_server.py`: The Flask application for live log streaming.
* `entrypoint.sh`: The master script that controls the startup logic.
* `.github/workflows/publish.yml`: The automation to push to GHCR.

---

### 2. The Master Entrypoint (`entrypoint.sh`)

The interns need to create this script to handle the feature logic. This prevents the container from restarting ComfyUI multiple times.

```bash
#!/bin/bash
# 1. Start the Live Log Server in the background
python3 /workspace/log_server.py > /tmp/log_server_status.log 2>&1 &

echo "--- [SYSTEM] Initialization Started ---" >> /tmp/comfyui.log
echo "--- [SYSTEM] Features Enabled: $ENABLE_FEATURES ---" >> /tmp/comfyui.log

# 2. Conditional Feature Execution
if [[ $ENABLE_FEATURES == *"wan2.1"* ]]; then
    echo "--- [PROCESS] Starting Wan 2.1 Setup ---" >> /tmp/comfyui.log
    bash /workspace/setup_parallel.sh >> /tmp/comfyui.log 2>&1
fi

if [[ $ENABLE_FEATURES == *"wan2.2"* ]]; then
    echo "--- [PROCESS] Starting Wan 2.2 Setup ---" >> /tmp/comfyui.log
    bash /workspace/setup_wan.sh >> /tmp/comfyui.log 2>&1
fi

# 3. Start ComfyUI (Only once, after all downloads finish)
echo "--- [SYSTEM] Starting ComfyUI ---" >> /tmp/comfyui.log
cd /workspace/runpod-slim/ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188 >> /tmp/comfyui.log 2>&1

```

---

### 3. The Log Server (`log_server.py`)

A Flask application must be created to provide a web interface for viewing the logs in real-time.

**Instructions for Interns:**
* Use Flask to create a simple server on port `8001`.
* It should stream the content of `/tmp/comfyui.log`.

---

### 4. The Dockerfile Tasks

The interns must configure the `Dockerfile` to use the specific RunPod hash you provided.

**Instructions for Interns:**

* Use `FROM runpod/comfyui@sha256:0bc728e7...`
* Install `aria2` and `flask`.
* Ensure all `.sh` files and `log_server.py` are copied and granted execution permissions (`chmod +x`).
* Expose ports `8188` (Comfy) and `8001` (Logs).

---

### 5. GitHub Actions Setup (`publish.yml`)

The goal here is to host the image on **GitHub Container Registry (GHCR)** for free.

**Instructions for Interns:**

* Create `.github/workflows/publish.yml`.
* Use `docker/login-action` with `registry: ghcr.io`.
* Set the image tag to `ghcr.io/${{ github.repository_owner }}/comfyui-modular:latest`.

---

### 6. Summary Table for Interns

| Component                | Action Required                                               |
| ------------------------ | ------------------------------------------------------------- |
| **Pathing**              | Use `/workspace/runpod-slim/ComfyUI` consistently.            |
| **Aria2**                | Ensure `aria2c` is used with `-x 16 -s 16` for maximum speed. |
| **Environment Variable** | Implement `ENABLE_FEATURES` logic in `entrypoint.sh`.         |
| **Log Streaming**        | `log_server.py` must point to `/tmp/comfyui.log`.             |

---

### 7. Deployment Guide (How to run on RunPod)

Once they finish, tell them to deploy using these settings:

1. **Image Name:** `ghcr.io/your-username/your-repo:latest`
2. **Environment Variable:** `ENABLE_FEATURES` = `wan2.1,wan2.2`
3. **Exposed Ports:** `8188`, `8001`