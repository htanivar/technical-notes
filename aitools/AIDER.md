# 🤖 Pair Programming with Aider + DeepSeek

This guide explains how to use **Aider** with your **DeepSeek API key** for cost‑effective AI pair programming.

---

## ⚡ 1. Setup

### Install Aider
```bash
pipx install aider-chat
```

### Configure DeepSeek API
```bash
export DEEPSEEK_API_KEY="your_api_key_here"
export OPENAI_API_KEY=$DEEPSEEK_API_KEY
export OPENAI_API_BASE="https://api.deepseek.com/v1"
```

### Verify
```bash
aider --version
```

---

## 💰 2. Cost‑Effective Model

- Prefer **`deepseek-coder`** → cheaper & optimized for coding.
- Avoid sending unnecessary files (context = tokens = cost).

Run:
```bash
aider --model deepseek-coder
```

---

## 🎯 3. Pair Programming Workflow

### 🔹 Start Aider in your project
```bash
cd ~/your/project
aider --model deepseek-coder
```

### 🔹 Add files to work on (context)
```text
/add backend/app.py frontend/App.jsx
```

### 🔹 Ask for help
```text
/edit Refactor this function into helper module
/edit Add proper error handling for API calls
```

### 🔹 Remove context (to save tokens)
```text
/drop frontend/App.jsx
```

### 🔹 List files in context
```text
/ls
```

### 🔹 Switch focus (start fresh)
```text
/drop *
/add backend/routes/
```

### 🔹 Stop Aider
```text
/exit
```

---

## 🛠️ 4. Best Practices for Cost Efficiency

1. **Keep context small** → only add files you need.
2. **Batch edits** → group changes in one request.
3. **Use summaries** → ask Aider to explain code instead of pasting big files yourself.
4. **Drop unused files** → to reduce tokens.
5. **Commit often** → keep clean history with Git.

---

## 👩‍💻 5. Example Session

```text
/add backend/auth.py
/edit Add JWT-based authentication
/add frontend/src/App.jsx
/edit Update login flow to use new backend JWT
/ls
/drop frontend/src/App.jsx
/edit Write unit tests for auth.py
/git commit -m "Implemented JWT auth + frontend login update"
/exit
```

---

## 📚 6. References

- [DeepSeek Platform](https://platform.deepseek.com/)
- [Aider Docs](https://aider.chat/docs/)

---

✅ With this setup, you can **start, stop, change context, and keep usage cost‑efficient** with DeepSeek while pair programming.
