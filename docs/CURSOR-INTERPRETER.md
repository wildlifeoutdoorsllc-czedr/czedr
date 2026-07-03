# Cursor Interpreter Setup

Use this when you want Cursor to keep context without repeating the same notes.

## One-time setup

1. Create `ai-interpreter\.env` from `ai-interpreter\.env.example`.
2. Set `OPENAI_API_KEY` (or configure another backend).
3. Start interpreter:
   - `ai-interpreter\START-INTERPRETER.cmd`

## Add local Ollama (optional, recommended)

1. Run:
   - `scripts\setup-ollama-local.cmd`
2. Confirm local model works:
   - `ollama run llama3.2 "hello"`
3. Restart:
   - `ai-interpreter\START-INTERPRETER.cmd`
4. Check health:
   - `http://127.0.0.1:8790/v1/health` should show `openai` and `ollama`

## Fast usage from this repo

Run from terminal or any shell command launcher:

- Reuse the active session:
  - `scripts\cursor-interpreter.cmd -Message "Summarize latest Android fixes"`
- Force a new session:
  - `scripts\cursor-interpreter.cmd -NewSession -Message "Start CQ Athletes thread"`
- Route to one backend:
  - `scripts\cursor-interpreter.cmd -Backend openai -Message "Draft release notes"`
- Broadcast to all configured backends:
  - `scripts\cursor-interpreter.cmd -Broadcast -Message "Compare these options"`

The active session id is stored in `.cursor\interpreter-session.txt`.

## UI

Open `http://127.0.0.1:8790/` for session history, backend switching, and export.
