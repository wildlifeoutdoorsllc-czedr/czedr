@echo off
title OneVPS SSH - czedr.com
set "KEY=%USERPROFILE%\.ssh\id_ed25519_czedr_onevps"
set "SSH_OPTS=-o ConnectTimeout=15 -o ServerAliveInterval=30 -o ServerAliveCountMax=4 -o StrictHostKeyChecking=accept-new"
echo.
echo  Server: 91.220.203.91
echo  Port:   22122  (NOT 22)
echo  User:   root
echo.

if exist "%KEY%" (
  echo  Using your saved SSH key — no password needed.
  echo.
  ssh -p 22122 -i "%KEY%" %SSH_OPTS% root@91.220.203.91
) else (
  echo  No SSH key on this PC yet.
  echo  Run MAKE-VPS-WORK.cmd once and paste your OneVPS root password when asked.
  echo  Or try password login now:
  echo.
  pause
  ssh -p 22122 %SSH_OPTS% root@91.220.203.91
)

if errorlevel 1 (
  echo.
  echo  Login failed. See docs\ONEVPS-SSH-LOGIN.md
  echo.
  echo  Quick checks:
  echo    - Use port 22122, not 22
  echo    - If no key: run MAKE-VPS-WORK.cmd once with panel password
  echo    - If password fails: reset root password in OneVPS panel
  pause
)
