#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

MODE="symlink"
AGENTS_SELECTOR="all"
SKILLS_SELECTOR="all"
FORCE=0

declare -A TARGET_OVERRIDES

usage() {
  cat <<USAGE
Usage: scripts/install.sh [options]

Options:
  --mode <symlink|copy>         Install mode (default: symlink)
  --agents <csv|all>            Targets: codex,claude,opencode,gemini (default: all)
  --skills <csv|all>            Skills to install (default: all)
  --target <agent=/path>        Override a target path (repeatable)
                                Keys: codex,claude,opencode,gemini,canonical
  --force                       Replace existing installed skill paths/commands
  -h, --help                    Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --agents)
      AGENTS_SELECTOR="$2"
      shift 2
      ;;
    --skills)
      SKILLS_SELECTOR="$2"
      shift 2
      ;;
    --target)
      pair="$(parse_target_override "$2")"
      TARGET_OVERRIDES["${pair%%=*}"]="${pair#*=}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$MODE" in
  symlink|copy)
    ;;
  *)
    echo "ERROR: --mode must be symlink or copy" >&2
    exit 1
    ;;
esac

declare -a selected_agents
resolve_agents "$AGENTS_SELECTOR" selected_agents

declare -a selected_skills
resolve_skills "$SKILLS_SELECTOR" selected_skills

resolve_target_path() {
  local key="$1"
  local configured=""

  if [[ -n "${TARGET_OVERRIDES[$key]:-}" ]]; then
    configured="${TARGET_OVERRIDES[$key]}"
  else
    if [[ "$key" == "opencode" && -n "${TARGET_OVERRIDES[canonical]:-}" ]]; then
      configured="${TARGET_OVERRIDES[canonical]}"
    else
      configured="$(resolve_agent_target "$key")"
    fi
  fi

  expand_tilde "$configured"
}

install_skill_to_target() {
  local skill="$1"
  local target_root="$2"
  local src="$SKILLS_ROOT/$skill"
  local dst="$target_root/$skill"

  mkdir -p "$target_root"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      echo "ERROR: destination exists: $dst (use --force to replace)" >&2
      exit 1
    fi
    rm -rf "$dst"
  fi

  if [[ "$MODE" == "symlink" ]]; then
    ln -s "$src" "$dst"
  else
    cp -R "$src" "$dst"
  fi

  echo "installed: $dst"
}

for agent in "${selected_agents[@]}"; do
  if [[ "$agent" == "gemini" ]]; then
    gemini_root="$(resolve_target_path gemini)"
    args=("$SCRIPT_DIR/generate-gemini-commands.sh" "--skills" "$SKILLS_SELECTOR" "--dest" "$gemini_root")
    if [[ "$FORCE" -eq 1 ]]; then
      args+=("--force")
    fi
    "${args[@]}"
    continue
  fi

  target_root="$(resolve_target_path "$agent")"
  for skill in "${selected_skills[@]}"; do
    install_skill_to_target "$skill" "$target_root"
  done
done
