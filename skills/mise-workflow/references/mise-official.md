# Official mise Documentation

Check these pages when exact behavior or precedence matters:

| Topic                              | Page                                             |
| ---------------------------------- | ------------------------------------------------ |
| Configuration files and precedence | https://mise.jdx.dev/configuration.html          |
| Settings reference                 | https://mise.jdx.dev/configuration/settings.html |
| File tasks and task grouping       | https://mise.jdx.dev/tasks/file-tasks.html       |
| Task arguments (`#USAGE`)          | https://mise.jdx.dev/tasks/task-arguments.html   |
| `mise run`                         | https://mise.jdx.dev/cli/run.html                |
| `mise use` (versions, `--pin`)     | https://mise.jdx.dev/cli/use.html                |
| `mise trust`                       | https://mise.jdx.dev/cli/trust.html              |
| Lockfile (`mise.lock`)             | https://mise.jdx.dev/dev-tools/mise-lock.html    |
| Continuous integration             | https://mise.jdx.dev/continuous-integration.html |
| GitHub Action                      | https://github.com/jdx/mise-action               |
| Python and uv                      | https://mise.jdx.dev/mise-cookbook/python.html   |

Local checks that answer most questions without the docs:

```bash
mise config ls          # which config files apply, in order
mise tasks ls --hidden  # every task mise resolves
mise settings ls        # effective settings
mise doctor             # installation and activation problems
mise <command> --help   # flags of the installed version
```
