@echo off
title Czedr - Edit MAIL_PASS line 10
cd /d "%~dp0"
echo.
echo  Opens the server editor ON LINE 10 (the MAIL_PASS line).
echo.
echo  IN THE EDITOR:
echo    - Move to the end of the line (after the = sign)
echo    - Delete the old placeholder text
echo    - Paste your 16-character Google App Password
echo    - Save: Ctrl+O  then Enter
echo    - Exit: Ctrl+X
echo.
echo  Easier option: double-click SET-GMAIL-APP-PASSWORD.cmd instead (no editor).
echo.
pause
set "KEY=%USERPROFILE%\.ssh\id_ed25519_czedr_onevps"
set "SSH_OPTS=-o ConnectTimeout=15 -o ServerAliveInterval=30 -o ServerAliveCountMax=4 -o StrictHostKeyChecking=accept-new"
ssh -p 22122 -i "%KEY%" %SSH_OPTS% -t root@91.220.203.91 "printf '\n  >>> LINE 10: edit MAIL_PASS after the = sign <<<\n  >>> Save Ctrl+O Enter   Quit Ctrl+X <<<\n\n'; exec nano +10 /root/.czedr-mail-secrets"
echo.
echo  After you saved and quit nano, run on the server:
echo    bash /var/www/czedr/scripts/setup-vps-email.sh
echo.
echo  Or double-click SET-GMAIL-APP-PASSWORD.cmd next time to skip the editor.
pause
