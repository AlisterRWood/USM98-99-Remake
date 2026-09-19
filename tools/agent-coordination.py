#!/usr/bin/env python3
"""Manage local, cross-worktree file claims for parallel agents."""

import argparse
import json
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path


def git_common_dir():
    value = subprocess.check_output(
        ["git", "rev-parse", "--git-common-dir"], text=True
    ).strip()
    path = Path(value)
    if not path.is_absolute():
        path = Path.cwd() / path
    return path.resolve()


def registry_dir():
    path = git_common_dir() / "agent-coordination"
    (path / "claims").mkdir(parents=True, exist_ok=True)
    return path


def acquire_lock():
    path = registry_dir() / ".lock"
    for _ in range(100):
        try:
            path.mkdir()
            return path
        except FileExistsError:
            time.sleep(0.05)
    raise SystemExit("Could not acquire coordination lock; try again.")


def release_lock(path):
    path.rmdir()


def claims():
    result = []
    for path in sorted((registry_dir() / "claims").glob("*.json")):
        try:
            result.append(json.loads(path.read_text()))
        except json.JSONDecodeError:
            print(f"Ignoring malformed claim file: {path}", file=sys.stderr)
    return result


def normalize(path):
    return str(Path(path).as_posix()).lstrip("./")


def branch():
    return subprocess.check_output(
        ["git", "branch", "--show-current"], text=True
    ).strip()


def command_claim(args):
    requested = {normalize(path) for path in args.files}
    active = claims()
    conflicts = []
    for item in active:
        overlap = sorted(requested.intersection(item.get("files", [])))
        if overlap:
            conflicts.append((item, overlap))
    if conflicts:
        print("Claim rejected: overlapping active ownership exists.", file=sys.stderr)
        for item, overlap in conflicts:
            print(
                f"- {item['id']} by {item['agent']} ({item['task']}): "
                f"{', '.join(overlap)}",
                file=sys.stderr,
            )
        raise SystemExit(2)
    claim_id = f"claim-{uuid.uuid4().hex[:10]}"
    item = {
        "id": claim_id,
        "agent": args.agent,
        "task": args.task,
        "branch": branch(),
        "files": sorted(requested),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    lock = acquire_lock()
    try:
        for existing in claims():
            overlap = sorted(requested.intersection(existing.get("files", [])))
            if overlap:
                raise SystemExit(
                    f"Claim rejected after recheck: {existing['id']} owns {', '.join(overlap)}"
                )
        (registry_dir() / "claims" / f"{claim_id}.json").write_text(
            json.dumps(item, indent=2) + "\n"
        )
    finally:
        release_lock(lock)
    print(json.dumps(item, indent=2))


def command_release(args):
    removed = []
    lock = acquire_lock()
    try:
        for path in (registry_dir() / "claims").glob("*.json"):
            item = json.loads(path.read_text())
            if item.get("id") == args.claim or item.get("agent") == args.agent:
                path.unlink()
                removed.append(item["id"])
    finally:
        release_lock(lock)
    if not removed:
        raise SystemExit("No matching claim found.")
    print("Released: " + ", ".join(removed))


def command_list(_args):
    active = claims()
    if not active:
        print("No active claims.")
        return
    for item in active:
        print(f"{item['id']} | {item['agent']} | {item['task']} | {item['branch']}")
        print("  " + ", ".join(item["files"]))


def command_check(args):
    requested = {normalize(path) for path in args.files}
    conflicts = []
    for item in claims():
        overlap = sorted(requested.intersection(item.get("files", [])))
        if overlap and item.get("branch") != branch():
            conflicts.append((item, overlap))
    if conflicts:
        print("Active claim conflict:", file=sys.stderr)
        for item, overlap in conflicts:
            print(f"- {item['id']}: {', '.join(overlap)}", file=sys.stderr)
        raise SystemExit(2)
    print("No active claim conflicts.")


parser = argparse.ArgumentParser(description=__doc__)
subparsers = parser.add_subparsers(dest="command", required=True)

claim_parser = subparsers.add_parser("claim")
claim_parser.add_argument("--agent", required=True)
claim_parser.add_argument("--task", required=True)
claim_parser.add_argument("files", nargs="+")
claim_parser.set_defaults(function=command_claim)

release_parser = subparsers.add_parser("release")
group = release_parser.add_mutually_exclusive_group(required=True)
group.add_argument("--claim")
group.add_argument("--agent")
release_parser.set_defaults(function=command_release)

list_parser = subparsers.add_parser("list")
list_parser.set_defaults(function=command_list)

check_parser = subparsers.add_parser("check")
check_parser.add_argument("files", nargs="+")
check_parser.set_defaults(function=command_check)

args = parser.parse_args()
args.function(args)
