---
name: architecture
description: >-
  Inspect a codebase's real architecture — layers, packages, lines of code,
  the package dependency graph, a saved view focused on one area (or save a
  new one), one
  block's full context (its layer, rules,
  actual edges, and blast radius), and the evidence behind any dependency
  (the exact imports, file:line) — by querying the TangleGuard CLI instead of
  reading files and guessing. Use when orienting in an unfamiliar codebase,
  when asked how the code is organized or what depends on what, and before
  any architectural or design discussion. Also when the user wants to see
  the architecture themselves ("show me the graph", "visualize the
  dependencies", "can I look at the structure"): write them the interactive
  HTML page.
---

# Architecture: Query the Structure, Don't Guess It

TangleGuard is a static analysis tool (native Rust, extremely fast) that
extracts a codebase's structure deterministically. If you only need the
structure, ask TangleGuard instead of reading source files: it is faster,
cheaper in tokens, and grounded in facts rather than inference from file
paths.

The binary is `tangleguard`. If it is not on the PATH, ask the user to
install it (see https://tangleguard.com/docs/apps/cli#installation) — do
not fall back to guessing the
architecture. Commands need the language (`-l`) and optionally a path (`-p`,
defaults to the current directory). Output is markdown, ready to drop into
your reasoning; add `--format json` to parse it programmatically. Supported
languages include `rust`, `go`, `typescript` / `javascript`, `python`,
`kotlin`, `java`, `csharp`, `php`, and `dart`.

This skill covers reading the structure. The CLI can do more: cycle
preflight, layer suggestions, structural diffs, and more. The `untangle`,
`validate`, `assign-layers` and `changes` skills cover those. Before you
conclude that TangleGuard can't answer something, or tell the user a feature
is missing, run `tangleguard --help` once (`tangleguard <command> --help` for
a command's options).

## Get the big picture

```bash
tangleguard -q -l <language> [-p <path>] architecture
```

Prints a compact summary: the layers, the allowed dependency rules, the
packages (with their resolved layer and lines of code), and the package-level
dependency graph. Run this first — one call instead of reading dozens of
files. Add `--depth 1` (or 2, up to 4) to list each package's modules and
their dependencies too.

## Focus on one area (views)

```bash
tangleguard -q -l <language> [-p <path>] architecture --view "<name>"
```

The summary ends with a **Views** list. A view is a named slice of the
codebase that the team saved in TangleGuard, such as one feature or domain
("Authentication") or one subsystem ("Scanner Overview"), plus built-in ones:
**Between packages** (only dependencies that cross package boundaries) and
**Within packages** (only each package's internal dependencies). `--view`
scopes the summary to that slice: its depth, opened and hidden parts, and
which dependencies it shows. When the task is about an area a view covers,
use the view instead of the whole summary: it is smaller and already focused
on the parts the team considers relevant. An unknown name fails and lists the
valid ones. Via the MCP server, pass the name as the `view` parameter of the
`architecture` tool.

## Save a view

Only when the user asks for one. There is no dedicated command: a view is an
entry in the config's `views` list, so read the config, add the entry, and
write it back.

1. `tangleguard [-p <path>] read-config` prints the config as JSON.
2. Add the view next to the layers and rules: the top-level `views`, or
   `workspaces.<name>.views` if the config keeps its rules in workspace
   sections. Leave every other field untouched.
3. `tangleguard [-p <path>] write-config --config '<full merged JSON>'`
4. Run `architecture --view "<name>"` and check it shows the slice you meant.

```json
{
  "name": "Scanner internals",
  "config": {
    "depth": 1,
    "deselectedNodes": [["cli"], ["desktop"]],
    "expandedNodes": [["scanner", "rust"]],
    "dependencyConfig": {
      "crossPackages": true,
      "local": true,
      "deduplicateEdges": true,
      "enableEdgePropagation": true
    }
  }
}
```

- A node is a path: the package name, then the module's segments. Module
  `rust::module_scanner` of package `scanner` in the `architecture --depth`
  output is `["scanner", "rust", "module_scanner"]`.
- `depth` works like `--depth` (0 = packages only). `expandedNodes` opens
  single nodes beyond it.
- `deselectedNodes` hides nodes with everything below them; the rest stays.
  To focus on one area, hide what surrounds it.
- `crossPackages` shows dependencies between packages, `local` those inside a
  package. All four `dependencyConfig` flags are required. Optional:
  `minLoc`, `maxLoc`, `showOnlyCircularDeps`.

The TangleGuard UI lists the saved view too.

## Get one block's full context (before touching it)

```bash
tangleguard -q -l <language> [-p <path>] context --node <node>
```

The briefing to read before changing a specific block, in one call: its
layer, the rules that apply to it (what it may depend on, what may depend on
it — each with the permitting rule), its actual direct incoming/outgoing
edges with reference counts, its **blast radius** (every block that
transitively depends on it — what could break, what to re-test), and whether
it sits in a cycle. `--node` accepts a `pkg::module` qualified name or a
source-file path (the file you are about to edit). Prefer this over
`architecture` when the task concerns one block rather than the whole
codebase — it is smaller and more precise.

## Explain a dependency (evidence behind an arrow)

```bash
tangleguard -q -l <language> [-p <path>] explain-dependency --from <source> --to <target>
```

The architecture summary shows _that_ a dependency exists; this shows _why_:
every reference behind it — imported items, source `file:line`, and the exact
import statement. The statements reveal whether a dependency is a single
type-only import (cheap to move) or a broad runtime one. `--from`/`--to`
accept `pkg::module` prefixes (the package segment may be omitted) or file
paths; `--to` also accepts an external package name to list every usage of a
third-party dependency.

For a circular dependency, don't explain its edges one by one:
`check-circles --evidence` lists every edge inside each tangle with its import
statements in one call (see the untangle skill).

## When the user wants to see it

```bash
tangleguard -q -l <language> [-p <path>] scan --html
```

Writes the whole dependency graph as one self-contained, interactive HTML
page — depth control, filters, the project's layers, rules and violations —
to `.tangleguard/scan.html` in the repository and prints its `file://` path.
Show that path so the user can open it; it works offline (`-o <file>` writes
it elsewhere). The `.tangleguard/` folder ignores itself in git, so there is
nothing to add to `.gitignore` and nothing to commit.

The page is for the human. Do not open or read it yourself — it is several
megabytes — and do not run plain `scan` for your own orientation either: it
prints the raw graph as JSON. For your own reasoning use `architecture`,
`context` and `explain-dependency` above; for a picture of what a change did,
the `changes` skill has `changes --html`.
