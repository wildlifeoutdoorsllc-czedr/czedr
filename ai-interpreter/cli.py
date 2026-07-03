#!/usr/bin/env python3
"""CLI for AI Interpreter — one comment, routed to your backends."""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

DEFAULT_BASE = os.getenv(
    "INTERPRETER_URL", "http://127.0.0.1:8790"
).rstrip("/")


def _headers() -> dict[str, str]:
    h = {"Content-Type": "application/json"}
    key = os.getenv("INTERPRETER_API_KEY", "")
    if key:
        h["Authorization"] = f"Bearer {key}"
    return h


def _request(method: str, path: str, body: dict | None = None) -> dict:
    url = f"{DEFAULT_BASE}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=_headers(), method=method)
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        err = e.read().decode()
        print(err, file=sys.stderr)
        sys.exit(1)


def cmd_sessions(_: argparse.Namespace) -> None:
    out = _request("GET", "/v1/sessions")
    for s in out["sessions"]:
        print(f"{s['id']}  {s['title']}  ({s['message_count']} msgs)")


def cmd_new(args: argparse.Namespace) -> None:
    body = {"title": args.title, "system_prompt": args.system or ""}
    s = _request("POST", "/v1/sessions", body)
    print(s["id"])


def cmd_ask(args: argparse.Namespace) -> None:
    sid = args.session
    if not sid:
        s = _request("POST", "/v1/sessions", {"title": args.title or "CLI"})
        sid = s["id"]
        print(f"session: {sid}", file=sys.stderr)
    body = {
        "session_id": sid,
        "message": args.message,
        "backend": args.backend,
        "include_history": not args.no_history,
    }
    if args.broadcast:
        body_b = {
            "session_id": sid,
            "message": args.message,
            "backends": args.backends.split(",") if args.backends else None,
        }
        out = _request("POST", "/v1/broadcast", body_b)
        for r in out["results"]:
            print(f"\n--- {r['backend']} ---")
            if r["ok"]:
                print(r["reply"])
            else:
                print(f"ERROR: {r['error']}", file=sys.stderr)
    else:
        out = _request("POST", "/v1/query", body)
        print(out["reply"])


def cmd_export(args: argparse.Namespace) -> None:
    out = _request("GET", f"/v1/sessions/{args.session}/export")
    print(out["markdown"])


def main() -> None:
    p = argparse.ArgumentParser(description="AI Interpreter CLI")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("sessions", help="List sessions").set_defaults(func=cmd_sessions)

    n = sub.add_parser("new", help="Create session")
    n.add_argument("--title", default="default")
    n.add_argument("--system", default="")
    n.set_defaults(func=cmd_new)

    a = sub.add_parser("ask", help="Send message (stored + routed)")
    a.add_argument("message")
    a.add_argument("--session", "-s", help="Existing session id")
    a.add_argument("--title", help="Title if creating new session")
    a.add_argument("--backend", "-b", help="Backend id")
    a.add_argument("--broadcast", action="store_true", help="Send to all backends")
    a.add_argument("--backends", help="Comma-separated backend ids for broadcast")
    a.add_argument("--no-history", action="store_true")
    a.set_defaults(func=cmd_ask)

    e = sub.add_parser("export", help="Export session as markdown")
    e.add_argument("session")
    e.set_defaults(func=cmd_export)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
