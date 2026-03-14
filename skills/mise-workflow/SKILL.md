---
name: mise-workflow
description: Manage development workflows for repositories that use mise with file-based Bash tasks. Use this skill when a repo contains mise.toml/.mise.toml/mise.local.toml/.tool-versions/.mise/tasks, or when asked to install/update tools, create or refactor tasks, run CI workflows, troubleshoot task resolution, or enforce pinning policy.
---

# Mise Workflow

Specialized workflow for mise where task definitions live in executable Bash files under `.mise/tasks`, not in `[tasks.*]` sections.

## Operational Scope

Use this skill for:

- Tool/runtime management with `mise`.
- Task authoring and refactoring to file tasks.
- Task naming and namespace conventions.
- Project pinning policy and version updates.
- CI commands that rely on `mise install` and `mise run`.
- Troubleshooting missing tools, tasks, or wrong task resolution.

## Mandatory Policy

- Run commands through `mise`; do not assume global binaries.
- Install tools with `mise install` before project workflows.
- Do not define `[tasks.*]` in `mise.toml`.
- Define tasks only as executable `.sh` files under `.mise/tasks/**/*.sh`.
- Execute workflows via `mise run <task>`.
- Use `mise exec -- <command>` (or `mise x -- <command>`) for ad-hoc commands.
- Keep shared settings in `mise.toml` and local overrides in `mise.local.toml`.

## Task Naming Contract

Map file paths to task names via directory segments:

- `.mise/tasks/setup.sh` -> `setup`
- `.mise/tasks/pip/install.sh` -> `pip:install`
- `.mise/tasks/pip/update.sh` -> `pip:update`
- `.mise/tasks/<a>/<b>/<c>.sh` -> `<a>:<b>:<c>`
- `.mise/tasks/pip/_default.sh` -> `pip`

When splitting one task into sub-tasks, use `:` namespaces and matching nested directories.

## Taskfile Authoring Standard

For each task file:

1. Use shebang: `#!/usr/bin/env bash`
2. Start with strict mode: `set -euo pipefail`
3. Keep one responsibility per task.
4. Add optional metadata via `#MISE ...` comments.
5. Mark executable: `chmod +x .mise/tasks/**/*.sh`

Example task file:

```bash
#!/usr/bin/env bash
set -euo pipefail
#MISE description="Install python dependencies"

uv pip install -r requirements.txt
```

## Default Execution Workflow

1. Detect mise usage (`mise.toml`, `.tool-versions`, `.mise/tasks`).
2. Run `mise install`.
3. Inspect task inventory with `mise tasks ls`.
4. Run requested task via `mise run <task>`.
5. If missing, add/update `.mise/tasks/**/*.sh` instead of TOML tasks.
6. For one-off commands, use `mise exec -- <command>`.

## Pinning Policy

Default strategy is fuzzy pinning.

- Preferred: `python = "3.13"`.
- Prefer `mise use <tool>@<major.minor>`.
- Avoid `--pin` unless project policy requires exact versions.
- Respect project override key: `MISE_PIN_STRATEGY=fuzzy|exact` (default `fuzzy`).
- Use `mise use --global` only for user-machine defaults, not project config.

## Migration: TOML Tasks -> File Tasks

When encountering `[tasks.*]` in `mise.toml`:

1. Extract each task command.
2. Create matching file under `.mise/tasks/` with `.sh` suffix.
3. Convert namespaced keys to nested directories.
4. Add shebang + strict mode.
5. Mark file executable.
6. Remove TOML task section.
7. Validate with `mise tasks ls` and `mise run <task>`.

Name conversion examples:

- `[tasks.build]` -> `.mise/tasks/build.sh`
- `[tasks."pip:install"]` -> `.mise/tasks/pip/install.sh`
- `[tasks."deploy:prod:api"]` -> `.mise/tasks/deploy/prod/api.sh`

## CI Baseline Pattern

Use this baseline sequence in CI jobs:

```bash
mise install
mise run lint
mise run test
mise run build
```

If a repo has different task names, always discover with `mise tasks ls` first.

## Troubleshooting Quick Guide

Tool not found or wrong version:

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
- Keep names explicit (for example `pip:install`, not overloaded short names).

Task file ignored:

- Ensure `.sh` suffix is present.
- Ensure executable bit is set.
- Ensure file is under `.mise/tasks`.

## Output Standard

When generating changes for a repo:

- Show created/updated taskfile paths.
- Show expected `mise run <task>` command.
- Keep `mise.toml` focused on tools/settings/hooks, not task definitions.
- Mention whether fuzzy or exact pinning was applied and why.

## References

- Official docs list: `references/mise-official.md`
- Taskfile style guide: `references/taskfile-style.md`
- Migration checklist: `references/migration-checklist.md`
