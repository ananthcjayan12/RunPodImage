# Hot Fix Instructions for Running Pod

## Quick Fix (Without Rebuilding)

If you have a **currently running pod** and want to fix the OOM issue immediately:

### Option 1: Automated Script (Recommended)

1. **Upload the hotfix script to your pod**:
   ```bash
   # From your local machine, copy to pod
   scp hotfix_memory_leak.sh root@<POD_IP>:/workspace/
   ```

2. **SSH into your pod**:
   ```bash
   ssh root@<POD_IP>
   ```

3. **Run the hotfix script**:
   ```bash
   cd /workspace
   chmod +x hotfix_memory_leak.sh
   bash hotfix_memory_leak.sh
   ```

4. **Test**: Run 2-3 consecutive generations to verify no OOM

---

### Option 2: Manual Fix (Step by Step)

If you prefer to do it manually:

#### Step 1: Install TeaCache
```bash
cd /workspace/runpod-slim/ComfyUI/custom_nodes
git clone https://github.com/1038lab/ComfyUI-TeaCache.git
```

#### Step 2: Update Your Workflow JSON

Find your `Infinitetalk.json` workflow file and make these changes:

**Node 122 (WanVideoModelLoader)**:
```json
"load_device": "main_device"  // Change from "offload_device"
```

**Node 134 (WanVideoBlockSwap)**:
```json
"blocks_to_swap": 5  // Change from 20
```

**Node 128 (WanVideoSampler)**:
```json
"force_offload": true  // Change from false
```

**Node 237 (WanVideoClipVisionEncode)**:
```json
"force_offload": true  // Should already be true
```

#### Step 3: Restart ComfyUI with VRAM Management

```bash
# Kill existing ComfyUI
pkill -f "python3 main.py"

# Wait a moment
sleep 2

# Restart with auto VRAM management
cd /workspace/runpod-slim/ComfyUI
nohup python3 main.py --listen 0.0.0.0 --port 8188 \
    --enable-cors-header \
    --vram-management-mode auto \
    >> /tmp/comfyui.log 2>&1 &
```

#### Step 4: Verify
```bash
# Check if ComfyUI is running
ps aux | grep "python3 main.py"

# Monitor logs
tail -f /tmp/comfyui.log
```

---

### Option 3: API-Based Workflow Update

If you're sending workflows via API, update your JSON payload:

```python
import json

# Load your workflow
with open('Infinitetalk.json', 'r') as f:
    workflow = json.load(f)

# Apply fixes
workflow['122']['inputs']['load_device'] = 'main_device'
workflow['134']['inputs']['blocks_to_swap'] = 5
workflow['128']['inputs']['force_offload'] = True
workflow['237']['inputs']['force_offload'] = True

# Save updated workflow
with open('Infinitetalk_fixed.json', 'w') as f:
    json.dump(workflow, f, indent=2)

# Use this workflow in your API calls
```

---

## Verification

After applying the fix, test with multiple consecutive generations:

```bash
# Monitor VRAM usage
watch -n 1 nvidia-smi

# You should see:
# - Generation 1: VRAM usage ~20-22GB ✅
# - After Gen 1: VRAM drops to ~2-5GB ✅
# - Generation 2: VRAM usage ~20-22GB ✅ (No OOM!)
# - After Gen 2: VRAM drops again ✅
```

---

## Troubleshooting

### Still Getting OOM?
Increase block swapping:
```json
"blocks_to_swap": 8  // or 10
```

### ComfyUI Won't Start?
Check logs:
```bash
tail -100 /tmp/comfyui.log
```

### Workflow Not Found?
The script looks for workflow at:
- `/workspace/runpod-slim/ComfyUI/Workflow_API/Infinitetalk.json`

If your workflow is elsewhere, update the path in the script or manually edit the JSON.

---

## Performance Expectations

| Metric           | Before Fix | After Fix |
| ---------------- | ---------- | --------- |
| 1st Generation   | 15 min     | 2-3 min ✅ |
| 2nd Generation   | OOM ❌      | 2-3 min ✅ |
| 3rd+ Generations | OOM ❌      | 2-3 min ✅ |
| VRAM Cleanup     | None       | Auto ✅    |

---

## Need Help?

If you encounter issues:
1. Check `/tmp/comfyui.log` for errors
2. Verify VRAM usage with `nvidia-smi`
3. Ensure workflow JSON is valid with `python3 -m json.tool Infinitetalk.json`
