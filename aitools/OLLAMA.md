# OLLAMA.md — Complete Guide

## 1. What is Ollama?

Ollama is a local LLM runtime that lets you run, manage, and interact with large language models directly on your machine.

---

## 2. Installation

### Linux (Recommended)

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### macOS

Download from: https://ollama.com/download

### Verify Installation

```bash
ollama --version
```

---

## 3. Basic Commands

### Start Ollama Service

```bash
ollama serve
```

### Run a Model

```bash
ollama run llama3
```

### Pull a Model

```bash
ollama pull qwen2.5-coder:14b
```

### List Models

```bash
ollama list
```

### Remove Model

```bash
ollama rm llama3
```

---

## 4. Model Management

### Show Model Info

```bash
ollama show qwen2.5-coder:14b
```

### Copy Model

```bash
ollama cp llama3 my-llama
```

---

## 5. Running with API

### Default Endpoint

```
http://localhost:11434
```

### Generate Text

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Explain Kubernetes"
}'
```

### Chat API

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "llama3",
  "messages": [{"role": "user", "content": "Hello"}]
}'
```

---

## 6. Using from Another Machine

### Bind to Network

```bash
OLLAMA_HOST=0.0.0.0 ollama serve
```

### Access from LAN

```
http://<your-ip>:11434
```

---

## 7. Custom Model (Modelfile)

### Create Modelfile

```Dockerfile
FROM llama3

SYSTEM "You are a DevOps assistant"
PARAMETER temperature 0.7
```

### Build Model

```bash
ollama create devops-assistant -f Modelfile
```

### Run

```bash
ollama run devops-assistant
```

---

## 8. Resource Guidelines

| Model Size | RAM Required | Use Case           |
| ---------- | ------------ | ------------------ |
| 3B–7B      | 8GB          | Lightweight tasks  |
| 13B–14B    | 16GB         | Coding + reasoning |
| 30B+       | 32GB+        | Advanced tasks     |

---

## 9. Performance Tips

* Use quantized models (`Q4_K_M`, `Q5`)
* Keep models on SSD
* Limit concurrent requests
* Adjust context length

---

## 10. Environment Variables

```bash
OLLAMA_HOST=0.0.0.0
OLLAMA_PORT=11434
OLLAMA_MODELS=/data/ollama
```

---

## 11. Logs & Debugging

```bash
journalctl -u ollama -f
```

or

```bash
ollama serve --debug
```

---

## 12. Docker Setup

### Dockerfile

```Dockerfile
FROM ollama/ollama

RUN ollama pull llama3

CMD ["ollama", "serve"]
```

### Run Container

```bash
docker run -d -p 11434:11434 ollama/ollama
```

---

## 13. Integration Examples

### Python

```python
import requests

res = requests.post("http://localhost:11434/api/generate", json={
    "model": "llama3",
    "prompt": "Write a bash script"
})

print(res.json())
```

### Node.js

```javascript
import fetch from "node-fetch";

const res = await fetch("http://localhost:11434/api/generate", {
  method: "POST",
  body: JSON.stringify({
    model: "llama3",
    prompt: "Explain Docker"
  })
});

console.log(await res.json());
```

---

## 14. Disk Setup (Your Case)

```bash
mkdir -p /data/ollama/model
```

Optional bind:

```bash
export OLLAMA_MODELS=/data/ollama/model
```

---

## 15. Swap Recommendation (Your System)

For 26GB RAM:

```bash
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 16. Best Models for DevOps

* qwen2.5-coder:14b
* llama3
* mistral
* deepseek-coder

---

## 17. Common Issues

### Port Already in Use

```bash
lsof -i :11434
kill -9 <PID>
```

### Model Not Found

```bash
ollama pull <model>
```

### Slow Performance

* Reduce model size
* Use quantized versions
* Check CPU usage

---

## 18. Useful One-Liners

### Check RAM

```bash
free -h
```

### Check Disk

```bash
df -h
```

### Run Model in Background

```bash
nohup ollama serve &
```

---

## 19. Security Notes

* Do NOT expose Ollama directly to internet
* Use reverse proxy (nginx)
* Add authentication layer if needed

---

## 20. Nginx Reverse Proxy

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://localhost:11434;
    }
}
```

---

## 21. Final Tips

* Start with smaller models
* Upgrade RAM for better performance
* Use API for automation
* Combine with tools like OpenClaude, Aider

---

## 22. Quick Start Summary

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve
ollama pull llama3
ollama run llama3
```

---

**End of File**
