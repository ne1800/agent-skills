#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="$REPO_ROOT/skills"
TARGETS_TOML="$REPO_ROOT/config/targets.toml"

trim() {
  local input="$1"
  input="${input#${input%%[![:space:]]*}}"
  input="${input%${input##*[![:space:]]}}"
  printf '%s' "$input"
}

expand_tilde() {
  local input="$1"
  if [[ "$input" == "~" ]]; then
    printf '%s' "$HOME"
    return
  fi
  if [[ "$input" == ~/* ]]; then
    printf '%s/%s' "$HOME" "${input#~/}"
    return
  fi
  printf '%s' "$input"
}

read_target_value() {
  local key="$1"
  if [[ ! -f "$TARGETS_TOML" ]]; then
    echo "ERROR: missing targets config: $TARGETS_TOML" >&2
    exit 1
  fi

  awk -F'=' -v wanted="$key" '
    BEGIN { section = "" }
    /^[[:space:]]*\[/ {
      line = $0
      gsub(/^[[:space:]]*\[/, "", line)
      gsub(/\][[:space:]]*$/, "", line)
      section = line
      next
    }
    section == "targets" {
      key = $1
      gsub(/[[:space:]]/, "", key)
      if (key == wanted) {
        value = $2
        sub(/^[[:space:]]*/, "", value)
        sub(/[[:space:]]*#.*/, "", value)
        gsub(/^"/, "", value)
        gsub(/"$/, "", value)
        print value
        exit
      }
    }
  ' "$TARGETS_TOML"
}

resolve_agent_target() {
  local agent="$1"
  case "$agent" in
    codex)
      read_target_value "codex"
      ;;
    claude)
      read_target_value "claude"
      ;;
    opencode)
      read_target_value "opencode"
      ;;
    gemini)
      read_target_value "gemini_commands"
      ;;
    canonical)
      read_target_value "canonical"
      ;;
    *)
      echo "ERROR: unsupported agent target '$agent'" >&2
      exit 1
      ;;
  esac
}

split_csv() {
  local raw="$1"
  local -n out_ref="$2"
  out_ref=()

  IFS=',' read -r -a items <<< "$raw"
  for item in "${items[@]}"; do
    item="$(trim "$item")"
    if [[ -n "$item" ]]; then
      out_ref+=("$item")
    fi
  done
}

list_available_skills() {
  find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

resolve_skills() {
  local selector="$1"
  local -n out_ref="$2"
  out_ref=()

  if [[ "$selector" == "all" ]]; then
    mapfile -t out_ref < <(list_available_skills)
  else
    local -a parsed_skills=()
    split_csv "$selector" parsed_skills
    out_ref=("${parsed_skills[@]}")
  fi

  if [[ "${#out_ref[@]}" -eq 0 ]]; then
    echo "ERROR: no skills selected" >&2
    exit 1
  fi

  local skill
  for skill in "${out_ref[@]}"; do
    if [[ ! -d "$SKILLS_ROOT/$skill" ]]; then
      echo "ERROR: skill '$skill' not found in $SKILLS_ROOT" >&2
      exit 1
    fi
    if [[ ! -f "$SKILLS_ROOT/$skill/SKILL.md" ]]; then
      echo "ERROR: skill '$skill' is missing SKILL.md" >&2
      exit 1
    fi
  done
}

resolve_agents() {
  local selector="$1"
  local -n out_ref="$2"
  out_ref=()

  if [[ "$selector" == "all" ]]; then
    out_ref=(codex claude opencode gemini)
    return
  fi

  local -a parsed_agents=()
  split_csv "$selector" parsed_agents
  out_ref=("${parsed_agents[@]}")
  if [[ "${#out_ref[@]}" -eq 0 ]]; then
    echo "ERROR: no agents selected" >&2
    exit 1
  fi

  local agent
  for agent in "${out_ref[@]}"; do
    case "$agent" in
      codex|claude|opencode|gemini)
        ;;
      *)
        echo "ERROR: unsupported agent '$agent'" >&2
        exit 1
        ;;
    esac
  done
}

parse_target_override() {
  local input="$1"
  if [[ "$input" != *=* ]]; then
    echo "ERROR: invalid --target '$input' (expected agent=/path)" >&2
    exit 1
  fi

  local key="${input%%=*}"
  local value="${input#*=}"
  key="$(trim "$key")"
  value="$(trim "$value")"

  case "$key" in
    codex|claude|opencode|gemini|canonical)
      ;;
    *)
      echo "ERROR: --target key must be one of codex, claude, opencode, gemini, canonical" >&2
      exit 1
      ;;
  esac

  if [[ -z "$value" ]]; then
    echo "ERROR: --target for '$key' has empty path" >&2
    exit 1
  fi

  printf '%s=%s\n' "$key" "$value"
}

skill_description_from_frontmatter() {
  local skill_md="$1"
  awk '
    BEGIN { in_frontmatter = 0; frontmatter_seen = 0 }
    /^---[[:space:]]*$/ {
      if (frontmatter_seen == 0) {
        in_frontmatter = 1
        frontmatter_seen = 1
        next
      }
      if (in_frontmatter == 1) {
        in_frontmatter = 0
        next
      }
    }
    in_frontmatter == 1 && $0 ~ /^description:[[:space:]]*/ {
      line = $0
      sub(/^description:[[:space:]]*/, "", line)
      gsub(/^"/, "", line)
      gsub(/"$/, "", line)
      print line
      exit
    }
  ' "$skill_md"
}
