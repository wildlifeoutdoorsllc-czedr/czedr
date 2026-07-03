# OneVPS SSH login help (Windows)

Server: `91.220.203.91` · Port **`22122`** · User **`root`**

I cannot see or reset your password from here. Use this checklist.

---

## Easiest way (recommended)

Double-click **`CONNECT-TO-VPS.cmd`** in the Czedr folder (or `scripts\ssh-onevps.cmd`).

Automated scripts use **timeouts** so stuck SSH does not run for hours — see `docs/OPS-TIMEOUTS.md`.

If this PC already ran **`MAKE-VPS-WORK.cmd`** once, login uses your saved key — **no password**.

---

## Step 1 — Exact command (PowerShell)

**With SSH key** (no password):

```powershell
ssh -p 22122 -i $env:USERPROFILE\.ssh\id_ed25519_czedr_onevps root@91.220.203.91
```

**With password only** (first time, before key is installed):

```powershell
ssh -p 22122 root@91.220.203.91
```

**Not** `ssh root@91.220.203.91` (that uses port 22 and will fail).

First time: type **`yes`** when asked about the host key.

---

## Step 2 — Password tips

1. Copy password from OneVPS email/panel into **Notepad** first.
2. Remove accidental spaces at start/end.
3. In PowerShell: **right-click** pastes the password (Ctrl+V may not work in all terminals).
4. Nothing appears while typing — that is normal.
5. Turn **Caps Lock** off.

---

## Step 3 — What error do you see?

| Message | Meaning | Fix |
|---------|---------|-----|
| `Connection timed out` | Wrong port or firewall | Use `-p 22122` |
| `Connection refused` on 22 | Wrong port | Use `-p 22122` |
| `Permission denied` | Wrong password or user | Reset password in OneVPS panel |
| `Access denied` | Same as above | Reset password |
| Host key prompt | Normal first connect | Type `yes` |

---

## Step 4 — Reset password (OneVPS panel)

1. Log in at [onevps.cloud](https://onevps.cloud) (client area).
2. Open your VPS → **Manage** / **SolusVM**.
3. Use **Root password** / **Reset password** / **Change password**.
4. Copy the **new** password to Notepad.
5. Try SSH again within 1–2 minutes.

If there is no reset button, open a **support ticket**: “Please reset root password for 91.220.203.91”.

---

## Step 5 — Browser console (no SSH needed)

If SSH still fails, use the **VNC / Serial / HTML5 console** in the OneVPS/SolusVM panel:

1. Panel → your VPS → **VNC** or **Console**.
2. Log in as `root` with the panel password (or reset there).
3. On the server run:

```bash
passwd
# set a new password you choose
```

Then from Windows:

```powershell
ssh -p 22122 root@91.220.203.91
```

---

## Step 6 — PuTTY (if PowerShell SSH fails)

| Field | Value |
|-------|--------|
| Host | `91.220.203.91` |
| Port | `22122` |
| Type | SSH |

Login as: **`root`**

Guide: https://blog.onevps.com/how-to-connect-to-linux-from-windows-using-putty/

---

## After successful login

```bash
passwd
apt update && apt upgrade -y
```

Continue: `docs/DEPLOY-ONEVPS-CZEDR.md`
