# OPENCLAUDE.md — Complete Guide

## 1. What is OpenClaude?

OpenClaude is a local-first AI coding assistant interface that connects to local or remote LLMs (like Ollama) and provides agent-style workflows such as planning, editing, and multi-step execution.

---

## 2. Installation

### Clone Repository

```bash
git clone https://github.com/OpenClaude/OpenClaude.git
cd OpenClaude
```

### Install Dependencies

```bash
npm install
```

### Run Application

```bash
npm run dev
```

---

## 3. Project Structure

```bash
openclaude/
├── src/
├── public/
├── config/
├── package.json
└── README.md
```

---

## 4. Connecting to Ollama

### Default Endpoint

```bash
http://localhost:11434
```

### Configure in OpenClaude

* Open Settings
* Set Provider: `Ollama`
* Base URL: `http://localhost:11434`
* Model: `qwen2.5-coder:14b`

---

## 5. Using Local Models

Make sure Ollama is running:

```bash
ollama serve
```

Pull model:

```bash
ollama pull qwen2.5-coder:14b
```

---

## 6. Agent Modes

### Chat Mode

* Simple conversation with model

### Plan Mode

* Breaks tasks into steps
* Generates execution plan

### Agent Mode

* Executes multi-step workflows
* Reads/writes files
* Iterative reasoning

---

## 7. Plan Mode Workflow

1. User provides task
2. Model generates plan
3. User reviews/approves
4. Execution begins

---

## 8. Context Management

### Best Practices

* Keep prompts small
* Use file references instead of large text
* Limit history length

---

## 9. File Operations

OpenClaude can:

* Read files
* Modify code
* Create new files
* Refactor projects

---

## 10. Configuration

### Example Config

```json
{
  "provider": "ollama",
  "baseUrl": "http://localhost:11434",
  "model": "qwen2.5-coder:14b"
}
```

---

## 11. Performance Tips

* Use smaller models for faster iteration
* Use quantized models (Q4)
* Reduce context size
* Avoid unnecessary history

---

## 12. Multi-Model Setup

You can switch models dynamically:

* Coding → `qwen2.5-coder`
* Chat → `llama3`
* Reasoning → `deepseek`

---

## 13. Integration with IDEs

### GoLand / VS Code

* Run OpenClaude separately
* Use it alongside your IDE
* Copy/paste or API integration

---

## 14. API Usage (If Enabled)

```bash
curl http://localhost:<port>/api/chat -d '{
  "message": "Generate Dockerfile"
}'
```

---

## 15. Running in Background

```bash
nohup npm run dev &
```

---

## 16. Logs & Debugging

```bash
npm run dev -- --debug
```

---

## 17. Common Issues

### Cannot Connect to Ollama

* Check Ollama is running
* Verify port 11434

### Slow Responses

* Use smaller model
* Reduce context

### Memory Issues

* Lower model size
* Close unused apps

---

## 18. Security Notes

* Do not expose OpenClaude publicly
* Use firewall rules
* Restrict API access

---

## 19. Advanced Usage

### Custom Prompts

* Define system prompts for behavior

### Task Automation

* Combine Plan + Agent mode

### DevOps Workflows

* Infra generation
* CI/CD scripts
* Docker/K8s configs

---

## 20. Useful One-Liners

### Check Running Process

```bash
ps aux | grep openclaude
```

### Kill Process

```bash
kill -9 <PID>
```

---

## 21. Example Workflow

```text
User: Build a Dockerized Node.js app

Plan:
1. Create Dockerfile
2. Add .dockerignore
3. Configure docker-compose
4. Test build

Execute → Done
```

---

## 22. Comparison

| Feature    | OpenClaude | Ollama |
| ---------- | ---------- | ------ |
| UI         | Yes        | No     |
| Agent Mode | Yes        | No     |
| Planning   | Yes        | No     |
| API        | Optional   | Yes    |

---

## 23. Quick Start Summary

```bash
git clone https://github.com/OpenClaude/OpenClaude.git
cd OpenClaude
npm install
npm run dev
```

Then:

* Connect to Ollama
* Select model
* Start using Agent Mode

---

**End of File**
