#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

AGENTS_SELECTOR="all"
SKILLS_SELECTOR="all"
FORCE=0

declare -A TARGET_OVERRIDES

usage() {
  cat <<USAGE
Usage: scripts/uninstall.sh [options]

Options:
  --agents <csv|all>            Targets: codex,claude,opencode,gemini (default: all)
  --skills <csv|all>            Skills to uninstall (default: all)
  --target <agent=/path>        Override a target path (repeatable)
                                Keys: codex,claude,opencode,gemini,canonical
  --force                       Required to remove non-symlink directories
  -h, --help                    Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

remove_skill_target() {
  local skill="$1"
  local target_root="$2"
  local dst="$target_root/$skill"

  if [[ -L "$dst" ]]; then
    rm -f "$dst"
    echo "removed symlink: $dst"
    return
  fi

  if [[ -d "$dst" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      echo "ERROR: refusing to remove directory without --force: $dst" >&2
      exit 1
    fi
    rm -rf "$dst"
    echo "removed directory: $dst"
    return
  fi

  if [[ -e "$dst" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      echo "ERROR: refusing to remove file without --force: $dst" >&2
      exit 1
    fi
    rm -f "$dst"
    echo "removed file: $dst"
    return
  fi

  echo "skip (not installed): $dst"
}

for agent in "${selected_agents[@]}"; do
  if [[ "$agent" == "gemini" ]]; then
    gemini_root="$(resolve_target_path gemini)"
    commands_dir="$gemini_root/skills"
    for skill in "${selected_skills[@]}"; do
      cmd_file="$commands_dir/$skill.toml"
      if [[ -f "$cmd_file" ]]; then
        rm -f "$cmd_file"
        echo "removed command: $cmd_file"
      else
        echo "skip (missing command): $cmd_file"
      fi
    done
    continue
  fi

  target_root="$(resolve_target_path "$agent")"
  for skill in "${selected_skills[@]}"; do
    remove_skill_target "$skill" "$target_root"
  done
done
