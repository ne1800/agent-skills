#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

show_desc=1

usage() {
  cat << USAGE
Usage: scripts/list-skills.sh [options]

Options:
  --names-only               Print only skill names
  -h, --help                Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --names-only)
      show_desc=0
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

mapfile -t skills < <(list_available_skills)

if [[ ${#skills[@]} -eq 0 ]]; then
  echo "No skills found in $SKILLS_ROOT"
  exit 0
fi

for skill in "${skills[@]}"; do
  if [[ $show_desc -eq 0 ]]; then
    echo "$skill"
    continue
  fi

  desc="$(skill_description_from_frontmatter "$SKILLS_ROOT/$skill/SKILL.md")"
  if [[ -z $desc ]]; then
    desc="(no description)"
  fi
  echo "$skill - $desc"
done
