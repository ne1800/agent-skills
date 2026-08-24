#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "validate succeeds" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/validate.sh"
  [ "$status" -eq 0 ]
  [[ $output == *"Validation passed"* ]]
}

@test "list-skills includes mise-workflow" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/list-skills.sh --names-only"
  [ "$status" -eq 0 ]
  [[ $output == *"mise-workflow"* ]]
}

@test "expand_tilde handles repo-style home-relative paths" {
  run bash -c "source '$REPO_ROOT/scripts/lib.sh'; expand_tilde '~/.codex/skills'"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.codex/skills" ]
}

@test "antigravity resolves to its global skill directory" {
  run bash -c "source '$REPO_ROOT/scripts/lib.sh'; resolve_agent_target antigravity"
  [ "$status" -eq 0 ]
  # The target config intentionally keeps the tilde unexpanded.
  # shellcheck disable=SC2088
  [ "$output" = "~/.gemini/config/skills" ]
}

@test "skill descriptions support folded yaml blocks" {
  skill_file="$TEST_ROOT/folded-skill.md"
  cat > "$skill_file" << 'EOF'
---
name: sample-skill
description: >-
  First sentence.
  Second sentence.
---
EOF

  run bash -c "source '$REPO_ROOT/scripts/lib.sh'; skill_description_from_frontmatter '$skill_file'"
  [ "$status" -eq 0 ]
  [ "$output" = "First sentence. Second sentence." ]
}

@test "install/uninstall symlink mode with all agents" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/install.sh --mode symlink --agents codex,claude,opencode,antigravity --skills mise-workflow --target codex='$TEST_ROOT/codex' --target claude='$TEST_ROOT/claude' --target opencode='$TEST_ROOT/opencode' --target antigravity='$TEST_ROOT/antigravity'"
  [ "$status" -eq 0 ]

  [ -L "$TEST_ROOT/codex/mise-workflow" ]
  [ -L "$TEST_ROOT/claude/mise-workflow" ]
  [ -L "$TEST_ROOT/opencode/mise-workflow" ]
  [ -L "$TEST_ROOT/antigravity/mise-workflow" ]

  run bash -c "cd '$REPO_ROOT' && ./scripts/uninstall.sh --agents codex,claude,opencode,antigravity --skills mise-workflow --target codex='$TEST_ROOT/codex' --target claude='$TEST_ROOT/claude' --target opencode='$TEST_ROOT/opencode' --target antigravity='$TEST_ROOT/antigravity'"
  [ "$status" -eq 0 ]

  [ ! -e "$TEST_ROOT/codex/mise-workflow" ]
  [ ! -e "$TEST_ROOT/claude/mise-workflow" ]
  [ ! -e "$TEST_ROOT/opencode/mise-workflow" ]
  [ ! -e "$TEST_ROOT/antigravity/mise-workflow" ]
}

@test "install/uninstall copy mode for codex" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/install.sh --mode copy --agents codex --skills mise-workflow --target codex='$TEST_ROOT/codex'"
  [ "$status" -eq 0 ]

  [ -d "$TEST_ROOT/codex/mise-workflow" ]
  [ ! -L "$TEST_ROOT/codex/mise-workflow" ]

  run bash -c "cd '$REPO_ROOT' && ./scripts/uninstall.sh --agents codex --skills mise-workflow --target codex='$TEST_ROOT/codex' --force"
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_ROOT/codex/mise-workflow" ]
}

@test "shared target deduplicates codex and opencode" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/install.sh --mode symlink --agents codex,opencode --skills mise-workflow --target codex='$TEST_ROOT/shared' --target opencode='$TEST_ROOT/shared'"
  [ "$status" -eq 0 ]
  [ -L "$TEST_ROOT/shared/mise-workflow" ]
  [[ $output == *"skip duplicate target for"* ]]

  run bash -c "cd '$REPO_ROOT' && ./scripts/uninstall.sh --agents codex,opencode --skills mise-workflow --target codex='$TEST_ROOT/shared' --target opencode='$TEST_ROOT/shared'"
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_ROOT/shared/mise-workflow" ]
  [[ $output == *"skip duplicate target for"* ]]
}
