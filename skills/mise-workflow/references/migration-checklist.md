# Migration Checklist: `[tasks.*]` to `.mise/tasks/`

Copy this checklist and tick it off per repository.

## 1. Inventory

- [ ] List TOML tasks: `rg -n '^\[tasks' mise.toml .mise.toml mise.local.toml`
- [ ] List existing file tasks: `mise tasks ls --hidden`
- [ ] Note the hooks and linters that match files by extension
      (`.pre-commit-config.yaml`, CI, editor settings).

## 2. Convert each task

- [ ] Map the key to a path: `[tasks."db:migrate"]` becomes
      `.mise/tasks/db/migrate.sh`; a task that is also a namespace becomes
      `<namespace>/_default.sh`.
- [ ] Choose the interpreter: Bash for command orchestration, Python for
      parsing or logic that needs tests. Do not rewrite working logic into
      another language just to change the file type.
- [ ] Add the shebang and the matching extension.
- [ ] Carry over the metadata as `#MISE` lines: `description`, `depends`,
      `alias`, `dir`, `sources`, `outputs`, `hide`.
- [ ] Turn `run` arrays into sequential commands; keep `env` values as
      exports in the script or in `[env]` when they are shared.
- [ ] Replace argument handling with `#USAGE` when the task takes options.
- [ ] Add `set -euo pipefail` to Bash tasks and `chmod +x` the file.

## 3. Clean up

- [ ] Remove the converted `[tasks.*]` tables.
- [ ] Leave `[tools]`, `[settings]`, `[env]` and other sections untouched.
- [ ] Update docs, CI and scripts that call the old task names, if any
      changed.

## 4. Validate

- [ ] `mise tasks ls` shows every expected name.
- [ ] `mise run <task>` succeeds for each migrated task, including
      `--help` for tasks with `#USAGE`.
- [ ] `rg -n '^\[tasks' mise.toml` finds nothing.
- [ ] The repository's lint and test tasks pass.
