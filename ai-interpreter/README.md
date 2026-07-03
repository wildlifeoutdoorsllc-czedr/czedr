# AI Interpreter

Say it **once** — the interpreter stores your conversation and routes it to one or more AI backends without re-pasting context.

## Quick start (Windows)

1. Copy `.env.example` → `.env` and set at least:
   ```env
   OPENAI_API_KEY=sk-...
   ```
2. Double-click **`START-INTERPRETER.cmd`**
3. Open **http://127.0.0.1:8790/** in your browser

## CLI

```powershell
cd D:\CZEDR\ai-interpreter
pip install -r requirements.txt

# New session + ask (history kept automatically)
python cli.py ask "Explain our REST API routing" --title "Czedr backend"

# Reuse session — no duplicate context
python cli.py ask "Now add WebSocket notes" --session <session-id>

# Send same message to every configured backend
python cli.py ask "Compare auth approaches" --session <id> --broadcast

# Export thread for email/docs
python cli.py export <session-id>
```

## API (JSON)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/v1/health` | Backends + status |
| POST | `/v1/sessions` | Create thread with `system_prompt` |
| POST | `/v1/query` | Add user message + get reply |
| POST | `/v1/broadcast` | Same message → all backends |
| GET | `/v1/sessions/{id}/export` | Markdown export |

Example:

```json
POST /v1/query
{
  "session_id": "...",
  "message": "Your question here",
  "backend": "openai",
  "include_history": true
}
```

## Multiple backends

- Edit **`config.yaml`** (copy from `config.example.yaml`)
- Or set env vars for `ollama`, second OpenAI-compatible endpoint, etc.

## Security

- Runs on **localhost** by default
- Optional: set `INTERPRETER_API_KEY` in `.env` (UI can store in browser localStorage)

## Data

Sessions live in `ai-interpreter/data/interpreter.db` (gitignored).
