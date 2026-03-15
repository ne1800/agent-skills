#!/usr/bin/env bash
#MISE description="Run Bats test suite"
set -euo pipefail

bats --print-output-on-failure test/bats
