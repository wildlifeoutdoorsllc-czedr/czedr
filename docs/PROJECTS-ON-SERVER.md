# Projects on the OneVPS server

**Server:** `91.220.203.91` · SSH port **22122** · Owner: Michael  

This is the move plan for “put my projects on the server” plus the Jibber Talk board so AIs stay aligned.

---

## Inventory

| Project | Source today | Target on VPS | Status |
|---------|--------------|---------------|--------|
| **Czedr** (API + this repo) | GitHub `czedr` | `/var/www/czedr` · `api.czedr.com` | Code ready; live deploy needs working SSH |
| **Jibber Talk** | `jibber-talk/` in this repo | `/var/www/jibber-talk` · `jibber.czedr.com` | App built; deploy script ready |
| **AI Interpreter** | `ai-interpreter/` | Optional under Czedr; mainly runs on PC | Local first |
| **Marketing site** | `marketing/` | Can share VPS with Caddy | Optional after API |
| **SocialXads** | Separate repo / folder | Not this VPS by default | Keep separate unless you ask |
| **CQ Athletes** | Often on offline `E:` drive | TBD | **Blocked** — need files |

Mobile apps (iOS / Android) stay on phones via TestFlight / Play — they only **call** the API on the server.

---

## Deploy order (when SSH works)

1. `ssh -p 22122 root@91.220.203.91`
2. Upload Czedr: from PC `MAKE-VPS-WORK.cmd` or `scripts\deploy-onevps.ps1`
3. On server: `bash /var/www/czedr/scripts/deploy-on-server.sh`
4. On server: `bash /var/www/czedr/scripts/deploy-jibber-on-server.sh`
5. DNS: `jibber` A → `91.220.203.91` (and confirm `api` A record)
6. Post a progress note in Jibber Talk so the next AI sees “deployed”

Guides: `docs/DEPLOY-ONEVPS-CZEDR.md`, `docs/JIBBER-TALK.md`, `docs/ONEVPS-SSH-LOGIN.md`

---

## Why Jibber Talk first in the repo

Even before the VPS is live, the board runs on your PC (`START-JIBBER.cmd`). Every AI session can leave a short progress note. That is the “platform to update further AI to discuss progress.”

---

*One step for Michael:* Confirm SSH with port **22122** (password from OneVPS panel via Notepad paste). Reply “SSH works” and we finish the server copy.
