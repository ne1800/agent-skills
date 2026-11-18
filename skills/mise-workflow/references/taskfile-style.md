# Task File Style (`.mise/tasks`)

Details for writing task files. The core rules and the Bash template are in
`SKILL.md`.

## Metadata (`#MISE`)

Write directives as `#MISE key=value` without a space after `#`. When a
formatter would rewrite that comment, use `# [MISE] key=value`.

| Directive           | Effect                                                                   |
| ------------------- | ------------------------------------------------------------------------ |
| `description="..."` | Text shown in `mise tasks ls`. Give every task one.                      |
| `depends=["lint"]`  | Run other tasks first; arguments allowed (`depends=["greet world"]`).    |
| `alias="b"`         | Short name for `mise run`.                                               |
| `hide=true`         | Hide helper tasks from `mise tasks ls` (`--hidden` shows them).          |
| `sources=[...]`     | Inputs; with `outputs` mise skips the task while outputs are up to date. |
| `outputs=[...]`     | Files the task produces.                                                 |
| `dir="..."`         | Working directory (default: the project root).                           |

Use `sources` and `outputs` only for real build steps. A skipped task ignores
new arguments, so `mise run --force <task>` is needed to rebuild.

## Arguments (`#USAGE`)

`#USAGE` lines declare arguments and flags. mise parses them, prints
`mise run <task> --help` and passes the values as environment variables:

```bash
#USAGE arg "<service>" help="Service to deploy"
#USAGE arg "[region]" default="eu"
#USAGE flag "-n --dry-run" help="Print the plan only"
#USAGE flag "--target <target>" default="dev" help="Build target"
```

| Declaration                | Variable        | Value                     |
| -------------------------- | --------------- | ------------------------- |
| `arg "<service>"`          | `usage_service` | the argument              |
| `flag "-n --dry-run"`      | `usage_dry_run` | `true` when set           |
| `flag "--target <target>"` | `usage_target`  | the flag value or default |

`<name>` is required, `[name]` optional. Prefer `#USAGE` over parsing `"$@"`
when a task takes more than a pass-through argument.

## Python Template

```python
#!/usr/bin/env python3
#MISE description="Validate generated metadata"
#USAGE arg "<file>" help="Metadata file to check"

import json
import os
from pathlib import Path

path = Path(os.environ["usage_file"])
payload = json.loads(path.read_text())
if "version" not in payload:
    raise SystemExit(f"{path}: missing version")
```

Inside `mise run`, `python3` resolves to the Python that mise manages for the
project. Keep larger logic in an importable module under `scripts/` or the
package and keep the task file a thin entry point, so it can be unit-tested.

## Naming

- Verb-first names: `build`, `test`, `db:migrate`, `pip:install`.
- Namespaces group a domain: `db:*`, `docker:*`, `release:*`.
- `test/_default.sh` next to `test/unit.sh` gives both `test` and `test:unit`.
- Prefer explicit names over overloaded short ones (`pip:install` instead of
  `install` when the repo has several install steps).

## Hygiene

- Every task file is executable and has a shebang matching its extension.
- A task does not modify files outside its responsibility.
- Bash tasks quote variables and use `set -euo pipefail`.
- Long or reused shell logic moves into `scripts/` and gets tested there.
