#!/bin/sh
set -eu

ci_mode=0
if [ "${1:-}" = "--ci" ]; then
  ci_mode=1
fi

if [ "$ci_mode" -eq 0 ]; then
  python3 tools/agent-coordination.py list
fi

branch_name=$(git branch --show-current)
case "$branch_name" in
  main|master)
    if [ "$ci_mode" -eq 0 ]; then
      echo "Refusing agent handoff from protected branch: $branch_name" >&2
      exit 2
    fi
    ;;
  codex/*|agent/*)
    ;;
  *)
    echo "Warning: branch '$branch_name' does not use codex/ or agent/ prefix." >&2
    ;;
esac

changed_files=$(git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only)
if [ -n "$changed_files" ]; then
  python3 tools/agent-coordination.py check $changed_files
else
  echo "No committed changes found relative to origin/main."
fi

if [ "$ci_mode" -eq 0 ]; then
  echo "Agent handoff metadata check passed."
fi
