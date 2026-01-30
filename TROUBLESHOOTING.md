# Troubleshooting Guide

## Issue: "ComfyUI directory not found"

### Root Cause
The base image `runpod/comfyui:latest` might not have ComfyUI pre-installed in the expected path `/workspace/runpod-slim/ComfyUI`.

### Solution Applied
- Added a `git clone` and `pip install` step in the `Dockerfile` to ensure ComfyUI is present.
- Added a fallback check in `entrypoint.sh` to clone ComfyUI at runtime if it's still missing.

## Issue: "exec /workspace/entrypoint.sh failed: No such file or directory"

### Root Cause
This error typically occurs when:
1. The entrypoint script is not properly copied into the Docker image
2. Line ending issues (CRLF vs LF)
3. The file doesn't have execute permissions
4. Multi-stage build issues

### Solution Applied

**Fixed in Dockerfile:**
- Removed incorrect multi-stage build syntax (`AS base` without a second stage)
- Added verification step to confirm file exists after copy
- Ensured proper permissions with `chmod +x`

### Verification Steps

After building the image, you can verify the entrypoint exists:

```bash
# Build the image
docker build -t comfyui-modular:test .

# Check if entrypoint exists in the image
docker run --rm comfyui-modular:test ls -la /workspace/entrypoint.sh

# Check the shebang line
docker run --rm comfyui-modular:test head -1 /workspace/entrypoint.sh
```

### Additional Debugging

If the issue persists, try these steps:

1. **Check line endings locally:**
   ```bash
   file entrypoint.sh
   # Should show: "Bourne-Again shell script text executable, ASCII text"
   ```

2. **Convert line endings if needed:**
   ```bash
   # On macOS/Linux
   dos2unix entrypoint.sh
   # Or
   sed -i 's/\r$//' entrypoint.sh
   ```

3. **Verify file permissions locally:**
   ```bash
   chmod +x entrypoint.sh
   ```

4. **Test the script locally:**
   ```bash
   bash -n entrypoint.sh  # Check for syntax errors
   ```

5. **Build with no cache:**
   ```bash
   docker build --no-cache -t comfyui-modular:test .
   ```

6. **Inspect the built image:**
   ```bash
   docker run --rm -it --entrypoint /bin/bash comfyui-modular:test
   # Then inside the container:
   ls -la /workspace/
   cat /workspace/entrypoint.sh
   ```

### Alternative Entrypoint Format

If the issue persists, you can try using the shell form in the Dockerfile:

```dockerfile
# Instead of:
ENTRYPOINT ["/workspace/entrypoint.sh"]

# Try:
ENTRYPOINT ["/bin/bash", "/workspace/entrypoint.sh"]
```

### Common Pitfalls

1. **Base Image Conflicts**: The `runpod/comfyui:latest` base image might have its own entrypoint. Our Dockerfile overrides it, which should work correctly.

2. **File Not Copied**: Ensure you're building from the correct directory where all files exist:
   ```bash
   ls -la entrypoint.sh setup_wan.sh setup_parallel.sh log_server.py
   ```

3. **Docker Build Context**: Make sure you're running `docker build` from the repository root where the Dockerfile is located.

### Testing the Fix

Try rebuilding with the updated Dockerfile:

```bash
# Clean build
docker build --no-cache -t comfyui-modular:latest .

# Run with basic features
docker run -d \
  -p 8188:8188 -p 8001:8001 \
  -e ENABLE_FEATURES="wan2.1" \
  --name comfyui-test \
  comfyui-modular:latest

# Check logs
docker logs -f comfyui-test
```

### Expected Output

You should see:
```
--- [SYSTEM] Container Started at 2026-01-30T18:23:00+00:00 ---
--- [SYSTEM] Features Enabled: wan2.1 ---
--- [SYSTEM] Starting Log Server on port 8001 ---
--- [SYSTEM] Log Server PID: 123 ---
```

If you still encounter issues after applying these fixes, please provide:
1. The full Docker build output
2. The output of `docker logs <container-id>`
3. The output of `ls -la` in your project directory
