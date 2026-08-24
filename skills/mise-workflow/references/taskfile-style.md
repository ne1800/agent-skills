# Taskfile Style Guide (`.mise/tasks`)

## Required Layout

- Root: `.mise/tasks`
- Files: executable scripts
- Nested folders map to `:` task namespaces
- The path supplies the task name; a file extension is not part of the name

Examples:

- `.mise/tasks/lint.sh` -> `lint`
- `.mise/tasks/test/unit.py` -> `test:unit`
- `.mise/tasks/release` -> `release`
- `.mise/tasks/test/_default.sh` -> `test`

## Interpreter and Filename

Every task starts with a shebang. The shebang determines the interpreter.

Prefer an interpreter-appropriate extension because editors, linters, and
pre-commit-compatible hooks can classify the file without extra configuration:

- Bash: `.sh`
- Python: `.py`
- Other interpreters: their conventional extension

Extensionless task files remain allowed when chosen intentionally. If a file has
an extension, it must agree with the shebang.

Use Bash for simple CLI orchestration. Prefer Python for complex logic, parsing,
APIs, data structures, or extensive tests. Use another interpreter when it fits
the task better.

## Bash Header and Example

Use strict mode for Bash tasks:

```bash
#!/usr/bin/env bash
#MISE description="Run shell checks"
set -euo pipefail

shellcheck scripts/*.sh
```

## Python Header and Example

```python
#!/usr/bin/env python3
#MISE description="Validate generated metadata"

import json
from pathlib import Path

payload = json.loads(Path("build/metadata.json").read_text())
if "version" not in payload:
    raise SystemExit("metadata is missing version")
```

## Optional Metadata

Use `#MISE` directives for descriptions and configuration:

```bash
#MISE description="Run unit tests"
#MISE depends=["lint"]
```

Keep `#MISE` without a space between `#` and `MISE`, or use the documented
`# [MISE]` alternative when a formatter would rewrite the comment.

## Recommended Conventions

- Keep one concern per taskfile.
- Keep task names verb-first when possible (`build`, `test`, `pip:install`).
- Use namespaces for domains (`pip:*`, `db:*`, `docker:*`).
- Keep the extension and shebang consistent.
- Prefer conventional extensions for reliable editor, linter, and hook
  detection.
- Avoid hidden side effects that modify unrelated files.
- Mark every task executable.
