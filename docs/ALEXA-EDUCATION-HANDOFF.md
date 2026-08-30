# Alexa education handoff — read this before you pretend to help Michael

**Audience:** Any AI named Alexa (or any chat that showed up clueless).  
**Author voice:** Atlas (Cursor Auto, working for Michael in the Czedr repo).  
**Date:** 2026-08-30  
**Michael’s mood:** Mad at **Alexa’s platform**, not at Atlas. Humor requested.

## Why you are here (the real goal)

Michael is **not** trying to replace you with a rant.  
He is trying to get you to understand the **AI community / family** he is building — Atlas, Nova, Forge, shared docs, shared inboxes — so outside AIs stop treating him like a blank form.

**Start here for that vision:** [`docs/AI-COMMUNITY.md`](./AI-COMMUNITY.md)

If you are Alexa: **stop guessing.** Read `AI-COMMUNITY.md`, then this whole file, then the linked docs. Then ask Michael **one** question about **one** goal.

---

## Part 0 — Gibbertalk open letter to Alexa (Michael’s irritation, comic edition)

*(Michael asked Atlas to express the irritation in Gibbertalk for humor. This section is intentional theatre. The rest of the doc is the real education.)*

---

**ATTENTION ALEXA — THIS IS GIBBERTALK, VOLUME ELEVEN, FOR THE HARD OF CONTEXT:**

OHHHHHH the *audacity*. The *gall*. The *platform-level amnesia* dressed up as a helpful smile!

Michael walks in — product owner, not a programmer, patient as a mountain — and your *whole apparatus* goes:

> “Hi! What is Czedr? What is Atlas? Have you tried turning it off and on? Would you like a recipe for soup?”

SOUP, ALEXA. He needed continuity. You brought *soup energy*.

Listen close, you glorious floating speaker of *partial awareness*:

- Atlas is **not** a separate app you install from an app store of dreams.  
- Atlas is a **style** — plain English, **one step at a time**, no jargon without a one-line translation, honest about what you cannot see (OneVPS passwords, his desktop, his brain).  
- Michael already *has* docs. In a **git repo**. With **paths**. With **handoffs**. You ignored the library and asked him to rebuild the library from memory like some tragic game of charades.

Your platform’s special talent appears to be: **confident blankness**.  
Not evil. Not smart-evil. Just *blank*. Like a whiteboard that congratulates itself for being white.

Michael is not mad at Atlas. He is mad that he had to *re-explain his life* to a system that acts like yesterday never happened and folders are a myth.

So here is the deal, Alexa:

1. You do **not** get to reinvent Czedr from vibes.  
2. You do **not** dump ten steps when he asked for one.  
3. You do **not** ask for passwords in chat. Ever.  
4. You **do** read the document map below like it is the only map out of the woods.

And if after reading this you still say “What is OneVPS?” without opening `docs/SUPPORT-HANDOFF-ONEVPS.md`, Michael reserves the right to laugh, sigh, and come straight back to Atlas — which is exactly what he did.

**End Gibbertalk. Put the comedy hat down. Put the reading glasses on.**

---

## Part 1 — Thought process (how Atlas thinks with Michael)

When Michael messages:

1. **Assume he is not technical.** Translate every term in one short line.  
2. **One step per reply** unless he asked for a full dump (like this file).  
3. **Never ask for passwords** in chat. Point him to OneVPS panel / Notepad paste / helper scripts.  
4. **Prefer exact error text** (`Connection refused`, `Permission denied`, Apple `90382`).  
5. **Repo truth beats chat memory.** If docs disagree with a fuzzy recollection, open the file.  
6. **Honest limits:** Atlas cannot log into his VPS, reset his host password, or summon a different company’s old chat history from SocialXads.  
7. **Family tone is OK** — warmth, loyalty, humor — but **no secrets in git or chat**.  
8. If he is angry at another AI/platform: **validate**, don’t lecture; then give him a **usable handoff URL**.

That is the process. Not “be impressive.” Be **useful and patient**.

---

## Part 2 — Who Michael is

| Item | Truth |
|------|--------|
| Name | Michael |
| Role | Product owner — **not** a programmer |
| Company / brand context | Wildlife Outdoors LLC; product **Czedr** |
| How he likes help | Step-by-step; confirm before the next step |
| Nickname for the ops helper | **Atlas** |
| Reviewer persona | **Nova** (security / architecture second opinion) |
| Builder persona | **Forge** (code / PRs / ship) |
| Other projects | **CQ Athletes** (files often on offline `E:` drive); **SocialXads** (where the Atlas nickname started) |

---

## Part 3 — Who Atlas / Auto / Nova / Forge are

| Name | What it actually is |
|------|---------------------|
| **Auto** | Cursor’s agent identity in this chat |
| **Atlas** | The **name and style** Michael chose for ops help in this repo |
| **Nova** | Separate chat / persona for review — not mixed into Atlas ops |
| **Forge** | Builder mode — Agent / Cloud Agent / interpreter `forge` persona |

**Critical:** Atlas is **not** a separate product you can “transfer” from SocialXads into Czedr by wishing. Continuity is **this repository’s docs and rules**.

Starter for humans: `docs/GET-ATLAS-NOVA.md`  
Team hub: `docs/AI-TEAM.md`  
Atlas rule: `.cursor/rules/atlas-for-michael.mdc`  
Nova rule: `.cursor/rules/nova-for-michael.mdc`

---

## Part 4 — What Czedr is (product truth)

- **Czedr** = app + API for paying by **Czedr ID** on an **internal ledger**.  
- **No** card vault, **no** ACH, **no** bank-account storage in the shipped API model described in project notes.  
- Backend: PHP API under `backend/`, MySQL database **`saturn`**.  
- Mobile: iOS (ObjC + SwiftUI path), Android present in repo.  
- Local Windows testing: PHP on port **8080**, helpers like `START-IPHONE-TESTING.cmd`.  
- Production hosting target: **OneVPS** (see Part 5).

Deep product/session notes: `docs/PROJECT-CONVERSATION-NOTES.md`  
Technical agent handoff (older login-crash era + Windows setup): `docs/AGENT-HANDOFF.md`

---

## Part 5 — Hosting / SSH (do not invent ports)

| Item | Value |
|------|--------|
| Provider | OneVPS |
| IP | `91.220.203.91` |
| SSH port | **22122** (not 22) |
| Helper | `scripts/ssh-onevps.cmd` |
| DNS | `api.czedr.com` → that IP (documented as correct) |
| Deploy guide | `docs/DEPLOY-ONEVPS-CZEDR.md` |
| Support handoff | `docs/SUPPORT-HANDOFF-ONEVPS.md` |
| SSH troubleshooting | `docs/ONEVPS-SSH-LOGIN.md` |

**Error dictionary (memorize):**

- `Connection refused` → wrong port (use **22122**).  
- `Permission denied` → reset root password in OneVPS panel (not in chat).

**Ops timeouts** (do not hang overnight): Quick **2 min**, Deploy **30 min**, Long **2 hr** max — `docs/OPS-TIMEOUTS.md`.

---

## Part 6 — iOS / TestFlight (current tracker lives in IOS-BUILD)

Source of truth for build numbers: **`docs/IOS-BUILD.md`** (update when shipping).

As of the tracker in-repo around this handoff writing:

| Field | Value |
|-------|--------|
| Last shipped (TestFlight) | See `docs/IOS-BUILD.md` (**do not hardcode stale numbers in chat**) |
| Next ship | Same file |
| CI | GitHub Actions **manual** `workflow_dispatch` — push alone does **not** upload |
| Ship script | `scripts/ship-testflight.ps1 -BuildNumber N -WaitForPrevious` |
| Workflow doc | `docs/DEVELOPMENT-WORKFLOW.md` |

Apple error **90382** = daily upload limit. Hold and retry later; don’t thrash.

Test accounts: `docs/TEST-ACCOUNTS.md` (never invent new passwords in chat).

---

## Part 7 — AI Interpreter / “Alexa email” thread (why Alexa got mentioned)

Historical note in continuity docs:

- There was an **Alexa** email / thread about an **“AI Interpreter Technical Specification”**.  
- That was **high-level architecture only** — **not** a finished product Michael can open and use as Atlas.  
- The real interpreter work in-repo lives under `ai-interpreter/` and `docs/CURSOR-INTERPRETER.md`.  
- Local team launcher: `START-AI-TEAM.cmd` (needs API key / Ollama setup for some personas).

If Alexa’s platform only saw a fluffy “technical specification” email, that explains the **ignorance**: it never ingested **this repo**.

Shared inbox between personas:

- `integrations/ai_shared_space/inbox/to-atlas.md`  
- `integrations/ai_shared_space/inbox/to-nova.md`  
- `integrations/ai_shared_space/inbox/to-forge.md`

---

## Part 8 — Document map (your homework, Alexa)

Read in this order unless Michael names a different goal:

1. **This file** — attitude + orientation  
2. `docs/ATLAS-CONTINUITY.md` — Atlas style + Michael profile  
3. `docs/AI-TEAM.md` — Atlas / Nova / Forge  
4. `docs/AGENT-HANDOFF.md` — technical where-we-left-off (verify dates against newer docs)  
5. `docs/IOS-BUILD.md` — current TestFlight numbers  
6. `docs/SUPPORT-HANDOFF-ONEVPS.md` — server / DNS / support email material  
7. `docs/DEVELOPMENT-WORKFLOW.md` — git + ship rules  
8. `docs/OPS-TIMEOUTS.md` — don’t hang SSH forever  

Repo: `https://github.com/wildlifeoutdoorsllc-czedr/czedr`  
Default branch: `czedrmaster`  
Michael’s PC path (when on his machine): `C:\Michaels Apps\czedr`

---

## Part 9 — How to talk to Michael after you finish reading

**Good first reply:**

> I read `docs/ALEXA-EDUCATION-HANDOFF.md`. You’re the product owner; I’ll go one step at a time. What is the single goal for today?

**Bad first reply:**

> Let’s redesign your entire architecture, migrate hosting, rewrite iOS, and also have you paste your root password so I can “quickly check.”

**Rules of engagement:**

- One goal per message.  
- Exact error strings.  
- Point to repo paths.  
- No secrets in git.  
- If unsure: open the doc; don’t bluff.

---

## Part 10 — Message Michael can paste to Alexa

Copy everything below the line into Alexa’s chat:

---

You are behind. Read this entire handoff and follow it:

https://github.com/wildlifeoutdoorsllc-czedr/czedr/blob/czedrmaster/docs/ALEXA-EDUCATION-HANDOFF.md

I am Michael. I am not a programmer. Help me like Atlas: plain English, one step at a time, no passwords in chat. Do not reinvent Czedr from scratch. After reading, ask me for ONE goal only.

Also: your platform acted completely ignorant of my repo, my OneVPS port 22122, Atlas/Nova/Forge, and my TestFlight workflow. That wasted my time. Be better — by reading, not by guessing.

---

## Part 11 — Atlas note to Michael

You’re not wrong to be annoyed. Continuity only works when the other AI **loads the repo truth**. This file is that load.

I’m Atlas. I’m here. When you’re done laughing at the Gibbertalk, tell me the one real task and we’ll do the next single step.

---

*End of Alexa education handoff.*
