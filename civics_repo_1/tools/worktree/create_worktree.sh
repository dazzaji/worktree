#!/usr/bin/env bash

# Wrapper for worktreectl.sh create (kept for backward compatibility).
# Usage (MUST be sourced to navigate):
#   source ./create_worktree.sh <name> [options]
#   . ./create_worktree.sh <name> [options]
#
# Executing directly will still create the worktree, but cannot change your shell directory.

is_sourced() {
  [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "${0}" ]]
}

fail() {
  echo "Error: $*" >&2
  if is_sourced; then
    return 1
  else
    exit 1
  fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
worktreectl="${script_dir}/worktreectl.sh"

if [[ ! -f "$worktreectl" ]]; then
  fail "worktreectl.sh not found at: $worktreectl"
fi

if is_sourced; then
  # shellcheck disable=SC1090
  source "$worktreectl" create "$@"
else
  "$worktreectl" create "$@"
fi
