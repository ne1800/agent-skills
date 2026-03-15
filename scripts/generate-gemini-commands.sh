#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

SKILLS_SELECTOR="all"
DEST_OVERRIDE=""
FORCE=0

usage() {
  cat << USAGE
Usage: scripts/generate-gemini-commands.sh [options]

Options:
  --skills <csv|all>       Skills to bridge (default: all)
  --dest <path>            Override gemini commands destination path
  --force                  Overwrite existing command files
  -h, --help               Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills)
      SKILLS_SELECTOR="$2"
      shift 2
      ;;
    --dest)
      DEST_OVERRIDE="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h | --help)
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

declare -a selected_skills
resolve_skills "$SKILLS_SELECTOR" selected_skills

gemini_commands_root="${DEST_OVERRIDE:-$(resolve_agent_target gemini)}"
gemini_commands_root="$(expand_tilde "$gemini_commands_root")"
commands_dir="$gemini_commands_root/skills"
mkdir -p "$commands_dir"

for skill in "${selected_skills[@]}"; do
  skill_dir="$SKILLS_ROOT/$skill"
  skill_md="$skill_dir/SKILL.md"
  out_file="$commands_dir/$skill.toml"

  if [[ -e $out_file && $FORCE -ne 1 ]]; then
    echo "ERROR: command exists: $out_file (use --force to overwrite)" >&2
    exit 1
  fi

  if [[ -e $out_file ]]; then
    rm -f "$out_file"
  fi

  description="$(skill_description_from_frontmatter "$skill_md")"
  if [[ -z $description ]]; then
    description="Use the $skill skill"
  fi

  description_escaped="$(printf '%s' "$description" | sed 's/\\/\\\\/g; s/"/\\"/g')"

  {
    printf 'description = "%s"\n' "$description_escaped"
    printf "prompt = '''\n"
    printf 'Use the skill "%s".\n\n' "$skill"
    printf 'Apply the following instructions from SKILL.md:\n\n'
    cat "$skill_md"
    printf '\n\nUser request:\n{{args}}\n'
    printf "'''\n"
  } > "$out_file"

  echo "generated: $out_file"
done
