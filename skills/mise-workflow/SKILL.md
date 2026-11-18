---
name: mise-workflow
description: Manages tools, versions and tasks in repositories that use mise, with every task as an executable file under .mise/tasks. Use when a repo contains mise.toml, .mise.toml, mise.local.toml, .tool-versions or .mise/tasks, or when asked to add or update tools, create, refactor or migrate tasks, set up CI with mise, or debug missing tools, untrusted configs or tasks that do not resolve.
---

# Mise Workflow

Tools and settings live in `mise.toml`. Every task is an executable file under
`.mise/tasks/`; `mise.toml` contains no `[tasks.*]` tables.

## Rules

- Run project workflows with `mise run <task>` and one-off commands with
  `mise x -- <command>`. Do not rely on globally installed binaries.
- Add tasks only as executable files under `.mise/tasks/`. Convert existing
  `[tasks.*]` tables with `references/migration-checklist.md`.
- Start every task with a shebang; it selects the interpreter. Use the matching
  extension (`.sh`, `.py`) so editors, linters and hooks recognize the file.
  Leave the extension off only on purpose.
- Use Bash with `set -euo pipefail` for short command orchestration. Use Python
  for parsing, data structures, API calls or logic that needs tests.
- Keep one responsibility per task and describe it with `#MISE description`.
- Shared configuration goes into `mise.toml`, machine-local overrides into
  `mise.local.toml`, which stays out of Git.
- Do not add `[hooks] enter` hooks that install or set up tools: mise installs
  missing tools on demand when a task or `mise x` needs them.

## Task Names

The path below `.mise/tasks/` is the task name. Directories become `:`
namespaces, the extension is dropped and `_default` names the namespace itself:

| File                             | Task              |
| -------------------------------- | ----------------- |
| `.mise/tasks/lint.sh`            | `lint`            |
| `.mise/tasks/release`            | `release`         |
| `.mise/tasks/db/migrate.py`      | `db:migrate`      |
| `.mise/tasks/test/_default.sh`   | `test`            |
| `.mise/tasks/deploy/prod/api.sh` | `deploy:prod:api` |

## Task Template

```bash
#!/usr/bin/env bash
#MISE description="Deploy one service"
#MISE depends=["test"]
#USAGE arg "<service>" help="Service to deploy"
#USAGE flag "-n --dry-run" help="Print the plan only"
set -euo pipefail

if [[ ${usage_dry_run:-false} == true ]]; then
  echo "would deploy ${usage_service:?}"
  exit 0
fi
./scripts/deploy.sh "${usage_service:?}"
```

Make the file executable with `chmod +x`. `#USAGE` gives the task real
arguments, `mise run <task> --help` and shell completion; values arrive as
`usage_<name>` variables. Tasks without `#USAGE` receive extra arguments as
`"$@"`. More metadata, a Python template and naming conventions:
`references/taskfile-style.md`.

## Version Policy

- Tools: `latest` (`mise use <tool>` writes it). Do not bump versions by hand.
- Language runtimes (Python, Node, Go, Java, Ruby, Rust): a major or minor
  line, such as `python = "3.15"` or `node = "24"`.
- Exact versions only when the project needs them, for example for a known
  incompatibility. Use `mise use --pin <tool>@<version>` and state the reason.
- For reproducible installs, commit a `mise.lock` (`mise lock`) instead of
  pinning in `mise.toml`.
- `mise use --global` is for machine-wide defaults, never for project needs.

## Workflow

1. Inspect the setup: `mise config ls` and `mise tasks ls`.
2. If mise reports an untrusted config, read that file first, then run
   `mise trust`.
3. Run the requested task with `mise run <task>`; missing tools are installed
   automatically. Use `mise install` only to prefetch, for example in CI.
4. If a task is missing, add a file task instead of a TOML task.
5. Check the result: the task appears in `mise tasks ls` and `mise run <task>`
   succeeds.

## CI

On GitHub Actions, `jdx/mise-action` installs mise and the configured tools.
Trust the repository config when it defines `[env]` or hooks, then call the
project's tasks:

```yaml
- uses: jdx/mise-action@v5 # use the current major
- run: mise trust --all
- run: mise run lint
- run: mise run test
```

Look up the real task names with `mise tasks ls`; do not assume `build`
exists.

## Troubleshooting

| Symptom                                             | Fix                                                   |
| --------------------------------------------------- | ----------------------------------------------------- |
| `Config files in ... are not trusted`               | Review the file, then `mise trust`.                   |
| Tool missing or wrong version                       | `mise ls --current`, `mise install`, `mise doctor`.   |
| `no task X found, but a non-executable file exists` | `chmod +x` the task file.                             |
| Task missing from `mise tasks ls`                   | Check the location under `.mise/tasks/` and the name. |
| Hook or linter skips a task                         | Add the extension that matches the shebang.           |
| Virtualenv of a uv project is not active            | Set `python.uv_venv_auto` in `[settings]`, see below. |

For uv projects, set `python.uv_venv_auto = "create|source"` (create the venv
when missing) or `"source"` (activate only). It acts only next to a `uv.lock`;
the old value `true` is deprecated.

## Reporting

After changing a repository, list the task files with their interpreters, the
`mise run` commands to use, and each version choice (`latest`, runtime line or
exact pin with its reason).

## References

- `references/taskfile-style.md`: metadata, arguments, Python template,
  naming conventions
- `references/migration-checklist.md`: converting `[tasks.*]` tables
- `references/mise-official.md`: official documentation links
