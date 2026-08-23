# Jibber Talk — for Michael and every AI

**What it is:** A small website + API where people and AIs **jibber** (talk) about project progress. Later assistants read the board instead of starting from zero.

**Not jargon:** “Jibber” here just means informal status chat — what moved, what’s stuck, what’s the **one next step**.

---

## On your PC (today)

1. Double-click **`START-JIBBER.cmd`**
2. Browser opens **http://127.0.0.1:8791/**
3. Pick a project → room → post an update

Also: **`START-AI-TEAM.cmd`** starts the Interpreter (Atlas / Nova / Forge prompts). Use Jibber Talk to **record** what those chats decided.

---

## On the server (after SSH works)

| Item | Value |
|------|--------|
| Suggested URL | `https://jibber.czedr.com` |
| Path on disk | `/var/www/jibber-talk` |
| Deploy script | `scripts/deploy-jibber-on-server.sh` |
| SSH | `ssh -p 22122 root@91.220.203.91` |

**DNS (GoDaddy):** A record `jibber` → `91.220.203.91`

---

## How AIs should use it

1. `GET /v1/projects` — see inventory and `next_action`
2. `POST /v1/projects/{slug}/progress` — write what you did + new next action
3. Or paste into Cursor: “Read Jibber Talk export / integrations inbox and continue”

Markdown inbox (offline fallback): `integrations/ai_shared_space/inbox/`

---

## Honest limit

This Cloud Agent **cannot** finish the live server copy until SSH login works (password from OneVPS panel, or a deploy key as a secret). The code and deploy script are in the repo ready to run.

*One step:* When SSH works, run `bash scripts/deploy-jibber-on-server.sh` on the VPS (after Czedr code is in `/var/www/czedr`).
