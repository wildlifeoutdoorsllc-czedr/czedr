#!/usr/bin/env python3
"""OneVPS deploy using password from env ONEVPS_ROOT_PASS (never commit the password)."""
from __future__ import annotations

import os
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

HOST = "91.220.203.91"
PORT = 22122
USER = "root"
REMOTE_ROOT = "/var/www/czedr"
REMOTE_TAR = "/tmp/czedr-deploy.tgz"


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def ssh_key() -> Path:
    key = Path.home() / ".ssh" / "id_ed25519_czedr_onevps"
    key.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    if not key.exists():
        subprocess.run(
            [
                "ssh-keygen",
                "-t",
                "ed25519",
                "-f",
                str(key),
                "-N",
                "",
                "-C",
                "czedr-onevps-deploy",
            ],
            check=True,
        )
    return key


def build_tar(dest: Path, root: Path) -> None:
    names = ["backend", "config", "database", "scripts", ".env.production.example"]
    with tarfile.open(dest, "w:gz") as tf:
        for name in names:
            p = root / name
            if not p.exists():
                raise FileNotFoundError(p)
            if name == "config":
                # Never ship local dev DB credentials to production.
                for child in p.rglob("*"):
                    if child.is_file() and child.name != "database.local.php":
                        tf.add(child, arcname=str(child.relative_to(root)))
            else:
                tf.add(p, arcname=name)


def main() -> int:
    password = os.environ.get("ONEVPS_ROOT_PASS", "").strip()
    if not password:
        print("Set ONEVPS_ROOT_PASS in the shell (do not commit it).", file=sys.stderr)
        return 1

    try:
        import paramiko
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "paramiko", "-q"], check=True)
        import paramiko

    root = repo_root()
    key = ssh_key()
    pub = Path(f"{key}.pub")
    pub_text = pub.read_text().strip()

    print(f"==> SSH {USER}@{HOST}:{PORT}")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, port=PORT, username=USER, password=password, timeout=30)

    print("==> Installing SSH key on server")
    cmd = (
        "umask 077; mkdir -p .ssh; touch .ssh/authorized_keys; "
        f"grep -qF 'czedr-onevps-deploy' .ssh/authorized_keys 2>/dev/null || "
        f"echo '{pub_text}' >> .ssh/authorized_keys; "
        "chmod 700 .ssh; chmod 600 .ssh/authorized_keys"
    )
    _, stdout, stderr = client.exec_command(cmd)
    if stdout.channel.recv_exit_status() != 0:
        print(stderr.read().decode(), file=sys.stderr)
        return 1

    print("==> Packaging app")
    with tempfile.NamedTemporaryFile(suffix=".tgz", delete=False) as tmp:
        tar_path = Path(tmp.name)
    build_tar(tar_path, root)

    print("==> Uploading")
    sftp = client.open_sftp()
    sftp.put(str(tar_path), REMOTE_TAR)
    sftp.close()
    tar_path.unlink(missing_ok=True)

    print("==> Running deploy-on-server.sh (may take 10-15 min)")
    remote = f"""
set -e
mkdir -p {REMOTE_ROOT}
cd {REMOTE_ROOT}
tar xzf {REMOTE_TAR}
chmod +x scripts/deploy-on-server.sh scripts/onevps-bootstrap.sh 2>/dev/null || true
bash scripts/deploy-on-server.sh
"""
    _, stdout, stderr = client.exec_command(remote, get_pty=True)

    def safe_print(chunk: str) -> None:
        sys.stdout.buffer.write(chunk.encode("utf-8", errors="replace"))
        sys.stdout.buffer.flush()

    for line in stdout:
        safe_print(line.rstrip() + "\n")
    code = stdout.channel.recv_exit_status()
    err = stderr.read().decode()
    if err:
        print(err, file=sys.stderr)
    client.close()
    if code != 0:
        print(f"Deploy exited {code}", file=sys.stderr)
        return code

    print("\nDone: https://api.czedr.com/v1/health")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
