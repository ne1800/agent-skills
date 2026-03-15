# Migration Checklist: [tasks.*] -> .mise/tasks/\*.sh

## Discovery

- Search for TOML tasks:
  - `rg '^\[tasks' mise.toml`
- List existing file tasks:
  - `find .mise/tasks -type f`

## Conversion

- Create one `.sh` file per task.
- Convert namespaced task keys into nested directories.
- Add shebang and strict mode.
- Preserve command behavior.
- Add executable bit.

## Cleanup

- Remove converted `[tasks.*]` blocks from `mise.toml`.
- Keep non-task config untouched (`[tools]`, `[settings]`, `[hooks]`, etc.).

## Validation

- `mise tasks ls` shows expected task names.
- `mise run <task>` works for migrated tasks.
- No TOML task sections remain:
  - `rg '^\[tasks' mise.toml`

## Policy Validation

- All task files under `.mise/tasks` end with `.sh`.
- Namespace split uses directory structure matching `:` names.
- Pinning policy remains project default (`MISE_PIN_STRATEGY=fuzzy` unless overridden).
