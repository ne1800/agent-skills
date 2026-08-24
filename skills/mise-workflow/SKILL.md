---
name: mise-workflow
description: Manage development workflows for repositories that use mise with executable file tasks. Use this skill when a repo contains mise.toml/.mise.toml/mise.local.toml/.tool-versions/.mise/tasks, or when asked to install/update tools, create or refactor tasks, run CI workflows, troubleshoot task resolution, or enforce pinning policy.
---

# Mise Workflow

Specialized workflow for mise where task definitions live in executable files
under `.mise/tasks`, not in `[tasks.*]` sections.

## Operational Scope

Use this skill for:

- Tool/runtime management with `mise`.
- Task authoring and refactoring to file tasks.
- Task naming and namespace conventions.
- Project pinning policy and version updates.
- CI commands that rely on `mise install` and `mise run`.
- Troubleshooting missing tools, tasks, interpreters, or wrong task resolution.

## Mandatory Policy

- Run commands through `mise`; do not assume global binaries.
- Install tools with `mise install` before project workflows.
- Do not define `[tasks.*]` in `mise.toml`.
- Define tasks as executable files under `.mise/tasks/`.
- Give every task a shebang; the shebang determines the interpreter.
- Prefer an interpreter-appropriate extension so editors, linters, and hooks
  recognize the file. `.sh`, `.py`, and extensionless task files are allowed.
- When an extension is present, keep it consistent with the shebang.
- Use Bash for simple CLI orchestration.
- Prefer Python for complex logic, parsing, APIs, data structures, or extensive
  tests. Other suitable interpreters remain allowed.
- Execute workflows via `mise run <task>`.
- Use `mise exec -- <command>` (or `mise x -- <command>`) for ad-hoc commands.
- Keep shared settings in `mise.toml` and local overrides in `mise.local.toml`.

## Task Naming Contract

Derive task names and `:` namespaces from the path. The file extension does not
become part of the task name:

- `.mise/tasks/setup.sh` -> `setup`
- `.mise/tasks/reports/generate.py` -> `reports:generate`
- `.mise/tasks/release` -> `release`
- `.mise/tasks/pip/_default.py` -> `pip`
- `.mise/tasks/<a>/<b>/<c>.<ext>` -> `<a>:<b>:<c>`

When splitting one task into sub-tasks, use `:` namespaces and matching nested
directories.

## Taskfile Authoring Standard

For each task file:

1. Keep one responsibility per task.
2. Choose the interpreter based on the task's complexity.
3. Add a shebang for that interpreter.
4. Prefer the matching file extension; use an extensionless name only
   intentionally.
5. Apply language-specific safety conventions. For Bash, start with
   `set -euo pipefail`.
6. Add optional metadata via `#MISE ...` comments.
7. Mark the file executable.

Simple Bash orchestration:

```bash
#!/usr/bin/env bash
#MISE description="Install Python dependencies"
set -euo pipefail

uv pip install -r requirements.txt
```

Structured Python logic:

```python
#!/usr/bin/env python3
#MISE description="Validate generated metadata"

import json
from pathlib import Path

payload = json.loads(Path("build/metadata.json").read_text())
if "version" not in payload:
    raise SystemExit("metadata is missing version")
```

Example executable-bit update:

```bash
chmod +x \
  .mise/tasks/pip/install.sh \
  .mise/tasks/metadata/validate.py \
  .mise/tasks/release
```

## Default Execution Workflow

1. Detect mise usage (`mise.toml`, `.tool-versions`, `.mise/tasks`).
2. Run `mise install`.
3. Inspect task inventory with `mise tasks ls`.
4. Run requested tasks via `mise run <task>`.
5. If a task is missing, add or update an executable file under `.mise/tasks/`
   instead of a TOML task.
6. For one-off commands, use `mise exec -- <command>`.

## Pinning Policy

Default strategy is fuzzy pinning.

- Preferred: `python = "3.13"`.
- Prefer `mise use <tool>@<major.minor>`.
- Avoid `--pin` unless project policy requires exact versions.
- Respect project override key: `MISE_PIN_STRATEGY=fuzzy|exact` (default
  `fuzzy`).
- Use `mise use --global` only for user-machine defaults, not project config.

## Migration: TOML Tasks -> File Tasks

When encountering `[tasks.*]` in `mise.toml`:

1. Extract each task command and preserve its behavior.
2. Assess its complexity and choose a suitable interpreter.
3. Convert namespaced keys to nested directories under `.mise/tasks/`.
4. Prefer a matching extension such as `.sh` or `.py`; extensionless files
   remain valid when intentionally chosen.
5. Add a shebang matching the interpreter and extension.
6. Add `set -euo pipefail` when the task uses Bash.
7. Mark the task executable.
8. Remove the TOML task section.
9. Validate task discovery and execution.

Name conversion examples:

- `[tasks.build]` -> `.mise/tasks/build.sh` for simple Bash orchestration.
- `[tasks."metadata:validate"]` -> `.mise/tasks/metadata/validate.py` for
  structured Python validation.
- `[tasks."deploy:prod:api"]` -> `.mise/tasks/deploy/prod/api.sh` for a
  namespaced Bash task.

Do not rewrite existing project logic into another language merely to satisfy a
filename convention.

## CI Baseline Pattern

Use this baseline sequence in CI jobs:

```bash
mise install
mise run lint
mise run test
mise run build
```

If a repo has different task names, always discover them with `mise tasks ls`
first.

## Troubleshooting Quick Guide

Tool or interpreter not found, or wrong version:

```bash
mise install
mise ls
mise doctor
```

Task not found:

```bash
mise tasks ls
find .mise/tasks -type f
```

Wrong task selected:

- Verify namespace path mapping in `.mise/tasks/**`.
- Keep names explicit, for example `pip:install` instead of overloaded short
  names.

Task file ignored:

- Ensure the file is executable.
- Ensure the file is under `.mise/tasks/`.
- Ensure the shebang names an available interpreter.
- If an extension is present, ensure it agrees with the shebang.
- If a linter or pre-commit-compatible hook skips an extensionless task, add
  the interpreter-appropriate extension or configure that tool explicitly.

The extension helps development tools classify the file; it does not override
the shebang or select the runtime interpreter.

## Output Standard

When generating changes for a repo:

- Show created or updated taskfile paths and their interpreters.
- Show the expected `mise run <task>` command.
- Keep `mise.toml` focused on tools, settings, and hooks rather than task
  definitions.
- Mention whether fuzzy or exact pinning was applied and why.

## References

- Official docs list: `references/mise-official.md`
- Taskfile style guide: `references/taskfile-style.md`
- Migration checklist: `references/migration-checklist.md`
