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
  [[ "$output" == *"Validation passed"* ]]
}

@test "list-skills includes mise-workflow" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/list-skills.sh --names-only"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mise-workflow"* ]]
}

@test "install/uninstall symlink mode with all agents" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/install.sh --mode symlink --agents codex,claude,opencode,gemini --skills mise-workflow --target codex='$TEST_ROOT/codex' --target claude='$TEST_ROOT/claude' --target opencode='$TEST_ROOT/opencode' --target gemini='$TEST_ROOT/gemini-commands'"
  [ "$status" -eq 0 ]

  [ -L "$TEST_ROOT/codex/mise-workflow" ]
  [ -L "$TEST_ROOT/claude/mise-workflow" ]
  [ -L "$TEST_ROOT/opencode/mise-workflow" ]
  [ -f "$TEST_ROOT/gemini-commands/skills/mise-workflow.toml" ]

  run bash -c "cd '$REPO_ROOT' && ./scripts/uninstall.sh --agents codex,claude,opencode,gemini --skills mise-workflow --target codex='$TEST_ROOT/codex' --target claude='$TEST_ROOT/claude' --target opencode='$TEST_ROOT/opencode' --target gemini='$TEST_ROOT/gemini-commands'"
  [ "$status" -eq 0 ]

  [ ! -e "$TEST_ROOT/codex/mise-workflow" ]
  [ ! -e "$TEST_ROOT/claude/mise-workflow" ]
  [ ! -e "$TEST_ROOT/opencode/mise-workflow" ]
  [ ! -e "$TEST_ROOT/gemini-commands/skills/mise-workflow.toml" ]
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

@test "generate gemini command from skill" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/generate-gemini-commands.sh --skills mise-workflow --dest '$TEST_ROOT/gemini'"
  [ "$status" -eq 0 ]

  COMMAND_FILE="$TEST_ROOT/gemini/skills/mise-workflow.toml"
  [ -f "$COMMAND_FILE" ]
  grep -q '^description = ' "$COMMAND_FILE"
  grep -q '^prompt = ' "$COMMAND_FILE"
}
