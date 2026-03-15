#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

errors=0

mapfile -t skills < <(list_available_skills)

if [[ ${#skills[@]} -eq 0 ]]; then
  echo "ERROR: no skills found under $SKILLS_ROOT" >&2
  exit 1
fi

for skill in "${skills[@]}"; do
  skill_dir="$SKILLS_ROOT/$skill"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f $skill_md ]]; then
    echo "ERROR: $skill is missing SKILL.md" >&2
    errors=1
    continue
  fi

  first_line="$(head -n 1 "$skill_md" || true)"
  if [[ $first_line != "---" ]]; then
    echo "ERROR: $skill SKILL.md must start with YAML frontmatter (---)" >&2
    errors=1
  fi

  name_value="$(awk '
    BEGIN { in_frontmatter = 0; seen_first = 0 }
    /^---[[:space:]]*$/ {
      if (seen_first == 0) {
        in_frontmatter = 1
        seen_first = 1
        next
      }
      if (in_frontmatter == 1) {
        exit
      }
    }
    in_frontmatter == 1 && /^name:[[:space:]]*/ {
      line = $0
      sub(/^name:[[:space:]]*/, "", line)
      gsub(/^"/, "", line)
      gsub(/"$/, "", line)
      print line
      exit
    }
  ' "$skill_md")"

  desc_value="$(skill_description_from_frontmatter "$skill_md")"

  if [[ -z $name_value ]]; then
    echo "ERROR: $skill SKILL.md frontmatter is missing name" >&2
    errors=1
  fi

  if [[ -z $desc_value ]]; then
    echo "ERROR: $skill SKILL.md frontmatter is missing description" >&2
    errors=1
  fi

  if [[ -f "$skill_dir/agents/openai.yaml" ]]; then
    echo "OK: $skill (SKILL.md + agents/openai.yaml)"
  else
    echo "OK: $skill (SKILL.md)"
  fi
done

if [[ $errors -ne 0 ]]; then
  exit 1
fi

echo "Validation passed"
