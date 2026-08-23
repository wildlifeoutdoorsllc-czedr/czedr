# Get Atlas and Nova in Cursor (Michael)

**Yes — you can have both.** They are two **chats** in the same folder, not two installs.

| | Atlas | Nova |
|---|--------|------|
| **For** | Day-to-day ops — SSH, deploy, TestFlight, “what do I click?” | Review — “Is this safe?”, architecture, second opinion |
| **How** | Any chat in `C:\Michaels Apps\czedr` (Atlas rule is automatic) | **New chat** + type `@nova-for-michael` or paste persona below |
| **Style** | One step at a time | One main finding at a time |

---

## Step 1 — Open the right folder

In Cursor: **File → Open Folder** → `C:\Michaels Apps\czedr`

Run once in Command Prompt:

```text
cd "C:\Michaels Apps\czedr"
git pull origin czedrmaster
```

---

## Step 2 — Atlas (ops helper)

1. **New chat** (regular Chat, not Agent).
2. First message:

```text
Atlas — read docs/ATLAS-CONTINUITY.md.
I'm Michael, not technical. One step at a time.
Today I need: [one goal]
```

Atlas replies in plain English and gives **one next step**.

---

## Step 3 — Nova (reviewer) — separate chat

Keep Atlas open for ops. Open a **second** chat for reviews:

1. **New chat**.
2. Type **`@nova-for-michael`** (Cursor should offer the rule), then:

```text
Nova — review this for security and architecture.
Read docs/PRODUCTION-SECURITY-CHECKLIST.md if needed.
My question: [paste here]
```

Or paste everything from: `integrations/ai_shared_space/personas/nova.md`

---

## Optional — local Nova script (needs API key)

If you set up `ai-interpreter\.env` with `OPENAI_API_KEY`:

- Double-click `scripts\ai-nova.cmd`

See `docs/CURSOR-INTERPRETER.md`. **You do not need this** to use Nova in Cursor chat.

---

## Handoff between them

| File | Use |
|------|-----|
| `integrations/ai_shared_space/inbox/to-atlas.md` | Task for Atlas |
| `integrations/ai_shared_space/inbox/to-nova.md` | Question for Nova |

Fill in the file, then tell the chat: “Read inbox/to-nova.md and answer.”

---

*You cannot recover old SocialXads chats here. These two roles work from **this repo** going forward.*
