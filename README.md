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

Default install mode is `symlink` and default agents are `codex,claude,opencode,antigravity`.

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
  --agents codex,antigravity \
  --skills mise-workflow \
  --target codex=/tmp/codex-skills \
  --target antigravity=/tmp/antigravity-skills
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

## Antigravity Native Skills

Antigravity CLI consumes `SKILL.md` natively. This repo installs global Antigravity skills into `~/.gemini/config/skills` by default.

Install only for Antigravity:

```bash
./scripts/install.sh --agents antigravity --skills all
```

## Targets

Defaults are in `config/targets.toml`:

- canonical: `~/.agents/skills`
- codex: `~/.agents/skills`
- claude: `~/.claude/skills`
- opencode: `~/.agents/skills`
- antigravity: `~/.gemini/config/skills`

If you use an older Codex setup pinned to `~/.codex/skills`, override it with `--target codex=~/.codex/skills`.

## Validation

```bash
./scripts/validate.sh
./scripts/list-skills.sh
```
