# Taskfile Style Guide (.mise/tasks)

## Required Layout

- Root: `.mise/tasks`
- Files: `*.sh` only
- Nested folders map to `:` task namespaces

Examples:

- `.mise/tasks/lint.sh` -> `lint`
- `.mise/tasks/test/unit.sh` -> `test:unit`
- `.mise/tasks/test/integration.sh` -> `test:integration`
- `.mise/tasks/test/_default.sh` -> `test`

## Required Header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

## Optional Metadata

Use `#MISE` directives for descriptions and config:

```bash
#MISE description="Run unit tests"
#MISE depends=["lint"]
```

## Recommended Conventions

- One concern per taskfile.
- Keep task names verb-first when possible (`build`, `test`, `pip:install`).
- Use namespaces for domains (`pip:*`, `db:*`, `docker:*`).
- Avoid hidden side effects that modify unrelated files.
