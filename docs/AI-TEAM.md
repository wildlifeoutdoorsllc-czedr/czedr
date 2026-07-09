# AI team — Atlas, Nova, Forge (Czedr)

Michael uses **three roles**. They are not three separate apps you install — they are **how you talk to AI** in this repo.

| Name | Role | Where you use it |
|------|------|------------------|
| **Atlas** | Patient ops guide — hosting, SSH, TestFlight, one step at a time | **Cursor chat** in this folder (`C:\Michaels Apps\czedr`) |
| **Nova** | Reviewer — security, architecture, “is this safe?” second opinion | Cursor **new chat** or **AI Interpreter** (`nova` persona) |
| **Forge** | Builder — writes code, fixes bugs, opens PRs | **Cursor Agent** or Cloud Agent, or Interpreter (`forge` persona) |

---

## Atlas (you may already be talking to Atlas)

**Atlas is this style of help in Cursor** — not a button.

1. Open folder: `C:\Michaels Apps\czedr`
2. New chat. First message:

```
Read docs/ATLAS-CONTINUITY.md and docs/AI-TEAM.md.
I'm Michael, not technical. One step at a time.
Today's goal: [fill in one thing]
```

Rule file: `.cursor/rules/atlas-for-michael.mdc` (applies automatically in this repo).

---

## Nova (review / second opinion)

**Use when:** “Is this secure?”, “What could go wrong?”, attorney/bank questions.

**Cursor:** New chat, paste the starter from `integrations/ai_shared_space/personas/nova.md`

**Interpreter (local):** Double-click `scripts/ai-nova.cmd` or run:

```text
scripts\cursor-interpreter.cmd -Persona nova -Message "Review our auth flow"
```

---

## Forge (build / fix code)

**Use when:** “Fix this bug”, “Rename payooze”, “Ship TestFlight”, “Deploy to VPS”.

**Cursor:** Switch to **Agent** mode (or Cloud Agent on cursor.com/agents).

**Interpreter (local):** Double-click `scripts/ai-forge.cmd` or run:

```text
scripts\cursor-interpreter.cmd -Persona forge -Message "Fix START-IPHONE-TESTING.cmd"
```

---

## Shared inbox (paste handoffs between AIs)

Like SocialXads `integrations/ai_shared_space/inbox/`:

| Path | Use |
|------|-----|
| `integrations/ai_shared_space/inbox/to-atlas.md` | Drop a task for Atlas-style ops help |
| `integrations/ai_shared_space/inbox/to-nova.md` | Drop something for review |
| `integrations/ai_shared_space/inbox/to-forge.md` | Drop a build/fix request |

Copy the file contents into a chat, or tell Cursor: “Read integrations/ai_shared_space/inbox/to-forge.md and do it.”

---

## Start everything on your PC (one double-click)

**`START-AI-TEAM.cmd`** at repo root:

1. Starts the AI Interpreter on `http://127.0.0.1:8790/`
2. Opens that page in your browser
3. Shows shortcuts for Atlas / Nova / Forge

First time only: copy `ai-interpreter\.env.example` → `ai-interpreter\.env` and add `OPENAI_API_KEY` (or use Ollama — see `docs/CURSOR-INTERPRETER.md`).

---

## Honest limits

- I **cannot** pull in a different company’s chat history (old SocialXads Atlas thread).
- **Nova** and **Forge** in Interpreter need an API key or local Ollama — they are not free magic voices.
- **Forge** Cloud Agents need GitHub connected (you already use this for Czedr PRs).

---

*One step:* Double-click **`START-AI-TEAM.cmd`**, then open a **new Cursor chat** and say “Atlas — read docs/AI-TEAM.md”.
