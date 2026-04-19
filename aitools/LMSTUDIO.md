# LM_STUDIO.md — Complete Guide

## 1. What is LM Studio?

LM Studio is a desktop application that lets you run large language models locally with a graphical interface, built-in API server, and model management.

---

## 2. Installation

### Download

* Website: https://lmstudio.ai

### Linux (AppImage)

```bash
chmod +x LM-Studio-*.AppImage
./LM-Studio-*.AppImage
```

### macOS / Windows

* Install via downloaded package

---

## 3. First Launch

* Open LM Studio
* Go to **Discover**
* Search for models (e.g., `llama3`, `mistral`, `qwen`)
* Click **Download**

---

## 4. Model Management

### Download Model

* Navigate to **Discover**
* Select model → Click **Download**

### Local Models Location

```bash
~/.cache/lm-studio/
```

---

## 5. Running a Model

* Go to **Chat**
* Select downloaded model
* Click **Load Model**

---

## 6. API Server (OpenAI Compatible)

### Start Server

* Go to **Local Server**
* Click **Start Server**

### Default Endpoint

```bash
http://localhost:1234
```

---

## 7. API Usage

### Chat Completion

```bash
curl http://localhost:1234/v1/chat/completions -d '{
  "model": "local-model",
  "messages": [
    {"role": "user", "content": "Explain Kubernetes"}
  ]
}'
```

### Completion

```bash
curl http://localhost:1234/v1/completions -d '{
  "model": "local-model",
  "prompt": "Write a bash script"
}'
```

---

## 8. Using from Another Machine

### Bind to Network

* In **Local Server Settings**
* Enable: `Allow connections from network`

### Access

```bash
http://<your-ip>:1234
```

---

## 9. Performance Settings

### Key Controls

* **GPU Offload Layers**
* **Context Length**
* **Batch Size**
* **Threads**

### Recommended

| RAM  | Model Size |
| ---- | ---------- |
| 8GB  | 3B–7B      |
| 16GB | 7B–13B     |
| 32GB | 13B+       |

---

## 10. Quantization Types

| Type   | Description             |
| ------ | ----------------------- |
| Q2_K   | Very small, low quality |
| Q4_K_M | Balanced (recommended)  |
| Q5     | Better quality          |
| Q8     | High quality, heavy     |

---

## 11. Hardware Acceleration

### GPU Support

* NVIDIA (CUDA)
* Apple Silicon (Metal)
* Limited AMD support

---

## 12. Directory Setup (Custom)

```bash
mkdir -p /data/lmstudio/models
```

Then configure path in settings UI.

---

## 13. Logs & Debugging

* View logs inside LM Studio UI
* Enable verbose logging in settings

---

## 14. Integration Examples

### Python

```python
import requests

res = requests.post("http://localhost:1234/v1/chat/completions", json={
  "model": "local-model",
  "messages": [{"role": "user", "content": "Hello"}]
})

print(res.json())
```

### Node.js

```javascript
import fetch from "node-fetch";

const res = await fetch("http://localhost:1234/v1/chat/completions", {
  method: "POST",
  body: JSON.stringify({
    model: "local-model",
    messages: [{ role: "user", content: "Explain Docker" }]
  })
});

console.log(await res.json());
```

---

## 15. Docker (Optional Workaround)

LM Studio is GUI-first, but you can expose API and use it inside containers.

---

## 16. Best Models for DevOps

* llama3
* mistral
* qwen2.5-coder
* deepseek-coder

---

## 17. Common Issues

### Model Not Loading

* Reduce GPU layers
* Check RAM availability

### API Not Responding

* Ensure server is started
* Check port 1234

### Slow Performance

* Use Q4 quantization
* Reduce context length

---

## 18. Useful One-Liners

### Check RAM

```bash
free -h
```

### Check GPU

```bash
nvidia-smi
```

---

## 19. Security Notes

* Avoid exposing port 1234 publicly
* Use reverse proxy if needed
* Add authentication externally

---

## 20. Reverse Proxy (Nginx)

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://localhost:1234;
    }
}
```

---

## 21. Comparison vs Ollama

| Feature       | LM Studio | Ollama |
| ------------- | --------- | ------ |
| UI            | Yes       | No     |
| API           | Yes       | Yes    |
| Ease of Use   | High      | Medium |
| Custom Models | Limited   | Strong |

---

## 22. Quick Start Summary

```bash
# 1. Install LM Studio
# 2. Download model via UI
# 3. Load model
# 4. Start local server
# 5. Use API at http://localhost:1234
```

---

**End of File**
