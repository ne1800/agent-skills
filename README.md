# agent-skills

A multi-skill repository for agent environments.

## Repository Layout

- `skills/<skill-name>/...` individual skills
- `scripts/install.sh` install skills into agent paths
- `scripts/uninstall.sh` remove installed skills
- `scripts/list-skills.sh` list available skills
- `scripts/validate.sh` validate skill structure
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
  --target gemini=/tmp/gemini-skills
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

## Gemini Native Skills

Gemini CLI consumes `SKILL.md` natively. This repo installs Gemini skills into `~/.agents/skills` by default.

Install only for Gemini:

```bash
./scripts/install.sh --agents gemini --skills all
```

## Targets

Defaults are in `config/targets.toml`:

- canonical: `~/.agents/skills`
- codex: `~/.agents/skills`
- claude: `~/.claude/skills`
- opencode: `~/.agents/skills`
- gemini: `~/.agents/skills`

If you use an older Codex setup pinned to `~/.codex/skills`, override it with `--target codex=~/.codex/skills`.

## Validation

```bash
./scripts/validate.sh
./scripts/list-skills.sh
```
