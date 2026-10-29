#!/bin/sh
# Stop hook: when the agent finishes, report the architecture issues (rule
# violations, cycles) its changes introduced since HEAD. Silent otherwise.
# Exit 2 hands the findings back to the agent once; after that it may stop.

input=$(cat)
# Already sent back once this turn: let the agent stop instead of looping.
case "$input" in *'"stop_hook_active":true'* | *'"stop_hook_active": true'*) exit 0 ;; esac

command -v tangleguard >/dev/null 2>&1 || exit 0
# Not a repo, or nothing changed since HEAD: nothing to check.
[ -n "$(git status --porcelain 2>/dev/null)" ] || exit 0

findings=$(tangleguard -q validate --since HEAD 2>/dev/null)
status=$?
# 1 + output = new issues. Anything else (clean, scan error, a CLI too old for
# --since, which argh also rejects with 1 but no stdout) stays quiet.
[ "$status" -eq 1 ] && [ -n "$findings" ] || exit 0

printf '%s\n\nYour changes introduced these architecture issues. Fix them at the given file:line before finishing, or tell the user why they are intended. Never edit tangleguard.json to make them go away.\n' "$findings" >&2
exit 2
