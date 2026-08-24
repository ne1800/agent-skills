# Migration Checklist: `[tasks.*]` -> `.mise/tasks/`

## Discovery

- Search for TOML tasks:
  - `rg '^\[tasks' mise.toml`
- List existing file tasks:
  - `find .mise/tasks -type f`
- Inspect project conventions, available mise-managed runtimes, and hook/linter
  file matching before choosing filenames.

## Conversion

- Create one executable file per task under `.mise/tasks/`.
- Convert namespaced task keys into nested directories.
- Preserve existing command behavior.
- Choose the interpreter based on the task:
  - Bash for simple CLI orchestration.
  - Python for complex logic, parsing, APIs, data structures, or extensive
    tests.
  - Another suitable interpreter when appropriate.
- Add a shebang for the chosen interpreter.
- Prefer an interpreter-appropriate extension such as `.sh` or `.py`.
- Use an extensionless filename only intentionally.
- Ensure any extension agrees with the shebang.
- Add `set -euo pipefail` to Bash tasks.
- Add the executable bit.
- Do not rewrite unrelated project logic merely to change languages.

## Cleanup

- Remove converted `[tasks.*]` blocks from `mise.toml`.
- Keep non-task configuration untouched (`[tools]`, `[settings]`, `[hooks]`,
  and similar sections).

## Validation

- `mise tasks ls` shows the expected path-derived task names and namespaces.
- `mise run <task>` works for every migrated task.
- Every task file is executable.
- Every task has a usable shebang.
- Every filename extension agrees with its shebang.
- Extensionless tasks are intentional and covered by editor, linter, and hook
  configuration where necessary.
- No TOML task sections remain:
  - `rg '^\[tasks' mise.toml`

## Policy Validation

- All task files live under `.mise/tasks/`.
- `.sh`, `.py`, other suitable extensions, and extensionless task files are
  allowed.
- Namespace directories match the intended `:` task names.
- Pinning policy remains the project default
  (`MISE_PIN_STRATEGY=fuzzy` unless overridden).
