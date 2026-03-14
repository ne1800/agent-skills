# agent-skills

A multi-skill repository for agent environments.

## Repository Layout

- `skills/<skill-name>/...` individual skills
- `scripts/install.sh` install skills into agent paths
- `scripts/uninstall.sh` remove installed skills
- `scripts/list-skills.sh` list available skills
- `scripts/validate.sh` validate skill structure
- `scripts/generate-gemini-commands.sh` bridge skills to Gemini CLI custom commands
- `config/targets.toml` default install targets

## Quick Start

```bash
git clone https://github.com/ne1800/agent-skills.git
cd agent-skills
./scripts/install.sh
```

Default install mode is `symlink` and default agents are `codex,claude,opencode,gemini`.

## Install Options

Install all skills for all agents:

```bash
./scripts/install.sh
```

Install only one skill:

```bash
./scripts/install.sh --skills mise-workflow
```

Install with copy mode:

```bash
./scripts/install.sh --mode copy
```

Install for selected agents only:

```bash
./scripts/install.sh --agents codex,claude --skills mise-workflow
```

Override targets ad-hoc:

```bash
./scripts/install.sh \
  --agents codex,gemini \
  --skills mise-workflow \
  --target codex=/tmp/codex-skills \
  --target gemini=/tmp/gemini-commands
```

## Uninstall

Remove symlink installs:

```bash
./scripts/uninstall.sh --agents codex,claude --skills mise-workflow
```

Remove copied directories (requires `--force`):

```bash
./scripts/uninstall.sh --agents codex --skills mise-workflow --force
```

## Gemini Bridge

Gemini CLI does not consume `SKILL.md` natively. This repo bridges skills to Gemini custom commands.

Generate commands directly:

```bash
./scripts/generate-gemini-commands.sh --skills all
```

This creates command files in `~/.gemini/commands/skills/*.toml` by default.

## Targets

Defaults are in `config/targets.toml`:

- canonical: `~/.agents/skills`
- codex: `~/.codex/skills`
- claude: `~/.claude/skills`
- opencode: `~/.agents/skills`
- gemini commands: `~/.gemini/commands`

## Validation

```bash
./scripts/validate.sh
./scripts/list-skills.sh
```
