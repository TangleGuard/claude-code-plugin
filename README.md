# TangleGuard Claude Code Plugin

A Claude Code plugin that keeps your coding agent inside your architecture, powered by [TangleGuard](https://tangleguard.com). It bundles:

- **Skills** that teach the agent to query the codebase's real architecture (layers, packages, dependency graph) instead of guessing it from file paths — and to **preflight every import** with `check-import` before writing it, so dependencies that violate your rules or close a cycle never enter the codebase.
- **A guardrail hook**: when the agent finishes a task, it runs `tangleguard validate --since HEAD` and hands any rule violation or cycle the change introduced back to the agent, with `file:line`. Pre-existing issues are ignored, and a clean change produces no output. [How it works](https://tangleguard.com/docs/getting-started/hooks).

## Requirements

You need the TangleGuard CLI installed. The [installation guide](https://tangleguard.com/docs/apps/cli#installation) covers the install script, Homebrew and Windows.

## Installation

This repo is a Claude Code plugin and its own marketplace:

```
/plugin marketplace add TangleGuard/claude-code-plugin
/plugin install tangleguard@tangleguard
```

## Privacy

The skills and the hook run the TangleGuard CLI locally, and your code never leaves your machine. The CLI sends one anonymous usage event per command to [OpenPanel](https://openpanel.dev): the command name, the CLI version, the operating system, and whether `validate --since` was used. We need it to know how the CLI is used. No code, file paths or user identifiers are sent. The CLI command `tangleguard upload` sends architecture data to TangleGuard Cloud (if the user has an account and provided an API token), but the plugin never runs the upload command. Details are in our [privacy policy](https://tangleguard.com/legal/privacy-policy/en).

## Other agents

For any agent (and for humans), the guardrail check works as a git pre-commit hook. Save this as `.git/hooks/pre-commit` and make it executable:

```sh
#!/bin/sh
exec tangleguard -q validate --since HEAD
```

The skills follow the [Agent Skills](https://agentskills.io) format — point your agent's skill loader at the [`skills/`](skills/) directory (`architecture`, `validate`, `untangle`, `assign-layers`), or copy it into your project's skills folder (e.g. `.claude/skills/`, `.codex/skills/`).
