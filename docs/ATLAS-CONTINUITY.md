# Atlas continuity — for Michael and any assistant

**Read this first** if Michael asks for “Atlas” or wants the same style of help he had on SocialXads.

---

## Who is “Atlas”?

**Atlas is not a separate product or a button in Cursor.**

On the **SocialXads** project, Michael named his AI assistant **Atlas** after a helpful chat (the model agreed to that nickname). There is no guaranteed way to “transfer” that exact chat into the **Czedr** project.

**What Michael liked about Atlas:**

- Plain language, no jargon unless explained
- **One step at a time** — wait for his reply before the next step
- Patient with SSH, DNS, hosting, and copy-paste
- Practical fixes (Notepad, Desktop copies) when the editor fails
- Honest limits (“I can’t see your OneVPS password”)

Any assistant in **this repo** can follow this doc and the Cursor rule **`atlas-for-michael.mdc`** to work in that style.

---

## Michael’s profile (for assistants)

| Item | Detail |
|------|--------|
| Role | Product owner — **not** a programmer |
| Preference | Step-by-step; confirm each step before continuing |
| Communication | Call out errors by exact text (`Connection refused`, `Permission denied`) |
| Security | Never ask for passwords in chat; use panel + Notepad paste |
| Projects | **Czedr** (this repo), **CQ Athletes** (docs on E: drive, often offline), **SocialXads** (separate repo, Atlas nickname originated there) |

---

## Current priorities (Czedr — May 2026)

### Blocked: SSH to production VPS

| Item | Value |
|------|--------|
| Provider | OneVPS |
| IP | `91.220.203.91` |
| SSH | `ssh -p 22122 root@91.220.203.91` (**not** port 22) |
| Helper | `scripts/ssh-onevps.cmd` |
| Docs | `docs/ONEVPS-SSH-LOGIN.md`, `docs/SUPPORT-HANDOFF-ONEVPS.md` |

**Connection refused** → wrong port (use **22122**).  
**Permission denied** → reset root password in OneVPS panel.

### Done or in progress

- DNS: **`api.czedr.com`** → `91.220.203.91` (correct)
- Deploy guide: `docs/DEPLOY-ONEVPS-CZEDR.md`
- API **not** live on server yet (ports 80/443 closed until deploy)
- iOS/Android app work in repo; TestFlight workflow in `docs/IOS-BUILD.md`

### Other threads

- **AI interpreter** (avoid repeating prompts): `ai-interpreter/`, `docs/CURSOR-INTERPRETER.md`
- **CQ Athletes** developer unknown; files were on `E:\Documents\CQ Athletes` (drive often offline)
- **Alexa** email about “AI Interpreter Technical Specification” — high-level architecture only; not built as product yet

---

## Document map (start here)

| Doc | Use when |
|-----|----------|
| **`docs/MANAGEMENT-TAKEOVER.md`** | New management / ownership cutover + backup checklist |
| **`docs/AGENT-HANDOFF.md`** | Older Czedr technical handoff (prefer RELEASE-TRAIN + IOS-BUILD for live numbers) |
| **`docs/SUPPORT-HANDOFF-ONEVPS.md`** | OneVPS support ticket + server/DNS summary |
| **`docs/DEPLOY-ONEVPS-CZEDR.md`** | After SSH works — deploy API |
| **`docs/ONEVPS-SSH-LOGIN.md`** | SSH troubleshooting |
| **`docs/PROJECT-CONVERSATION-NOTES.md`** | Session history summary |
| **`docs/DEVELOPMENT-WORKFLOW.md`** | Git, TestFlight, commits |
| **This file** | Atlas style + Michael’s context |
| **OPS timeouts** | `docs/OPS-TIMEOUTS.md` — SSH/deploy max wait (2 min / 30 min / 2 hr) |

---

## How to “get Atlas” in Cursor (practical)

1. **Stay in Czedr** (`D:\CZEDR`) — rule `atlas-for-michael.mdc` applies automatically.
2. **New chat** with first message:
   ```
   Read docs/ATLAS-CONTINUITY.md and docs/SUPPORT-HANDOFF-ONEVPS.md.
   I'm Michael, not technical. One step at a time. Today’s goal: [SSH / deploy / support email].
   ```
3. **SocialXads Atlas** — open the **SocialXads** folder in Cursor if that project’s history matters; chats don’t merge across folders.
4. **Model** — use a strong reasoning model (e.g. Claude Sonnet/Opus), not the fastest mini model, for hosting/support tasks.

---

## Support email (OneVPS) — ready to send

See **Section 10** in `docs/SUPPORT-HANDOFF-ONEVPS.md`.

---

## For other AIs (Alexa / Nova / contractors)

Michael may bridge assistants via copy-paste or files. Preferred handoff:

- One goal per message
- Exact error strings
- Point to paths in this repo (no secrets in git)

SocialXads used `integrations/ai_shared_space/inbox/` — Czedr equivalent is these **`docs/*HANDOFF*.md`** files.

---

*Michael: you don’t need a special Atlas install. Open a new chat here, mention this file, and ask for the next single step.*
