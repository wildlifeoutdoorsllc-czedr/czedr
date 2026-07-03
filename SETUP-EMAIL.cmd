@echo off
title Czedr - setup email on VPS
cd /d "%~dp0"
echo.
echo This installs mail tools on the VPS and shows how to add SMTP passwords.
echo You must create /root/.czedr-mail-secrets on the server (see docs\EMAIL-SETUP.md).
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "scp -P 22122 -i $env:USERPROFILE\.ssh\id_ed25519_czedr_onevps -r backend/src/Mail root@91.220.203.91:/var/www/czedr/backend/src/; ^
   scp -P 22122 -i $env:USERPROFILE\.ssh\id_ed25519_czedr_onevps backend/src/Auth/PasswordResetService.php scripts/setup-vps-email.sh scripts/czedr-mail-secrets.example scripts/test-mail.php docs/EMAIL-SETUP.md root@91.220.203.91:/tmp/czedr-email-patch/; ^
   ssh -p 22122 -i $env:USERPROFILE\.ssh\id_ed25519_czedr_onevps root@91.220.203.91 'mkdir -p /var/www/czedr/backend/src/Mail; cp /tmp/czedr-email-patch/PasswordResetService.php /var/www/czedr/backend/src/Auth/; cp /tmp/czedr-email-patch/*.sh /tmp/czedr-email-patch/*.example /tmp/czedr-email-patch/*.php /var/www/czedr/scripts/ 2>/dev/null; cp /tmp/czedr-email-patch/EMAIL-SETUP.md /var/www/czedr/docs/ 2>/dev/null; cp -r /tmp/czedr-email-patch/Mail/* /var/www/czedr/backend/src/Mail/ 2>/dev/null; bash /var/www/czedr/scripts/setup-vps-email.sh; systemctl restart czedr-api'"
echo.
pause
