---
name: changes
description: >-
  Show the human what a coding session changed structurally — new and removed
  dependencies between packages, changed module-level edges, added and removed
  components — as TangleGuard's own output, shown verbatim, never the agent's
  paraphrase of its own work. Use after changing code and before the user
  commits, and whenever asked "what did you change structurally", "review the
  structural changes", "structural diff", "what did this touch
  architecturally", or "show me the changes before I commit".
---

# Changes: Show the Structural Diff, Don't Paraphrase It

An agent summarising its own structural changes is the wrong source: it
reports what it meant to do, not what the code now does. TangleGuard
computes the difference between the working tree and HEAD from the code
itself. Your job is to run it and show the result unchanged.

The binary is `tangleguard`. If it is not on the PATH, ask the user to
install it (see https://tangleguard.com/docs/apps/cli#installation).
Commands need the language (`-l`) and optionally a path (`-p`, defaults to
the current directory). Supported languages include `rust`, `go`,
`typescript` / `javascript`, `python`, `kotlin`, `java`, `csharp`, `php`, and
`dart`.

## Show the changes

Run from the repository root; add `-p` only when the user names a subfolder:

```bash
tangleguard -q -l <language> [-p <path>] changes
```

It prints a compact markdown summary of the working tree against HEAD
(untracked files included): new and removed dependencies between packages,
changed module-level edges inside existing package dependencies, and added
and removed components. When nothing changed structurally it prints one
quiet line saying so. The exit code is always 0 — the command informs, it
does not judge.

**Show the stdout to the user verbatim, in a fenced block.** No summary
above it, no paraphrase, no interpretation, no selection of "the important
parts". The human reads TangleGuard's output, not your account of it. If they
ask a question about it afterwards, answer that — but the output itself goes
through untouched.

## When the user wants a visual look

```bash
tangleguard -q -l <language> [-p <path>] changes --html
```

Prints the same summary and writes one self-contained HTML page — the graph
of the changed components and their neighbours, additions and removals
coloured — then prints its `file://` path. Show that path so the user can
open it; it works offline.

## Branch against branch

`--base <ref> --head <ref>` compares two git refs instead of the working tree
against HEAD, e.g. `changes --base main --head feature/x`.
