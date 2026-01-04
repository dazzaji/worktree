#!/usr/bin/env bash

# worktreectl.sh - safe Git worktree helper for multi-agent workflows.
# Usage:
#   ./worktreectl.sh create <name> [options]
#   ./worktreectl.sh remove <name> [options]
#   ./worktreectl.sh list
#   ./worktreectl.sh help

WORKTREECTL_SOURCED=0
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
  WORKTREECTL_SOURCED=1
fi

DIR_PREFIX_DEFAULT="worktree_"
BRANCH_PREFIX_DEFAULT="agent/"

is_sourced() {
  [[ "$WORKTREECTL_SOURCED" -eq 1 ]]
}

die() {
  echo "Error: $*" >&2
  if is_sourced; then
    return 1
  else
    exit 1
  fi
}

warn() { echo "Warn:  $*" >&2; }
info() { echo "Info:  $*"; }

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { die "Not inside a Git repository."; return 1; }
}

git_top() {
  git rev-parse --show-toplevel
}

default_worktree_root() {
  local top repo parent
  top="$(git_top 2>/dev/null)" || return 1
  repo="$(basename "$top")"
  parent="$(dirname "$top")"
  echo "${parent}/.worktrees/${repo}"
}

choose_default_base() {
  if git show-ref --verify --quiet "refs/heads/main"; then
    echo "main"
  elif git show-ref --verify --quiet "refs/heads/master"; then
    echo "master"
  elif git show-ref --verify --quiet "refs/remotes/origin/main"; then
    echo "origin/main"
  elif git show-ref --verify --quiet "refs/remotes/origin/master"; then
    echo "origin/master"
  else
    echo "HEAD"
  fi
}

require_ref() {
  local ref="$1"
  git rev-parse --verify "${ref}^{commit}" >/dev/null 2>&1 || { die "Base ref '${ref}' not found (or not a commit)."; return 1; }
}

require_branch_name() {
  local b="$1"
  git check-ref-format --branch "$b" >/dev/null 2>&1 || { die "Invalid branch name: '$b'"; return 1; }
}

sanitize_dir_suffix() {
  local raw="$1"
  local s
  s="$(printf '%s' "$raw" | tr -c '[:alnum:]._-' '_' )"
  while [[ "$s" == *"__"* ]]; do s="${s//__/_}"; done
  s="${s#_}"; s="${s%_}"
  [[ -n "$s" ]] || { die "Name '$raw' becomes empty after sanitizing for directory use."; return 1; }
  printf '%s' "$s"
}

local_branch_exists() {
  local b="$1"
  git show-ref --verify --quiet "refs/heads/$b"
}

branch_in_use_by_worktree() {
  local b="$1"
  local needle="refs/heads/$b"
  git worktree list --porcelain | awk -v n="$needle" '
    $1=="branch" && $2==n {found=1}
    END { exit(found?0:1) }
  '
}

usage() {
  cat <<'EOF'
worktreectl.sh — safe Git worktree helper

Commands:
  create <name> [options]   Create a new worktree (and usually a new branch)
  remove <name> [options]   Remove a worktree (keeps branch by default)
  list                      List worktrees
  help                      Show this help

CREATE options:
  --from <ref>              Base ref to branch from (default: main/master/origin/*/HEAD auto-detect)
  --branch <name>           Branch name to create/use (default: agent/<name>)
  --dir-prefix <prefix>     Directory prefix (default: worktree_)
  --branch-prefix <prefix>  Branch prefix (default: agent/)
  --root <path>             Root directory to place worktrees (default: ../.worktrees/<repo>)
  --use-existing-branch     Use an existing local branch instead of creating a new one
  --no-cd                   Do not cd into the worktree even if sourced
  --fetch                   Run 'git fetch --prune' before creating

REMOVE options:
  --root <path>             Same meaning as create
  --dir-prefix <prefix>     Same meaning as create
  --force                   Force removal (passes -f to git worktree remove)
  --delete-branch           ALSO delete the local branch after removal (explicit opt-in)
  --delete-branch-force     Force delete branch (-D). Use only when you are sure.

Notes:
  - If you source this script, it can cd into the worktree on create:
      source ./worktreectl.sh create my-task
EOF
  if is_sourced; then
    return 0
  else
    exit 0
  fi
}

cmd_list() {
  require_git_repo || return 1
  git worktree list
}

cmd_create() {
  require_git_repo || return 1

  local name="${1:-}"
  [[ -n "$name" ]] || { die "create requires a <name>. Try: ./worktreectl.sh help"; return 1; }
  shift || true

  local from=""
  local branch=""
  local dir_prefix="$DIR_PREFIX_DEFAULT"
  local branch_prefix="$BRANCH_PREFIX_DEFAULT"
  local root="${WORKTREE_ROOT:-}"
  local use_existing_branch="false"
  local do_cd="true"
  local do_fetch="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from)
        [[ -n "${2:-}" ]] || { die "--from requires a ref."; return 1; }
        from="${2}"; shift 2 ;;
      --branch)
        [[ -n "${2:-}" ]] || { die "--branch requires a name."; return 1; }
        branch="${2}"; shift 2 ;;
      --dir-prefix)
        [[ -n "${2:-}" ]] || { die "--dir-prefix requires a value."; return 1; }
        dir_prefix="${2}"; shift 2 ;;
      --branch-prefix)
        [[ -n "${2:-}" ]] || { die "--branch-prefix requires a value."; return 1; }
        branch_prefix="${2}"; shift 2 ;;
      --root)
        [[ -n "${2:-}" ]] || { die "--root requires a path."; return 1; }
        root="${2}"; shift 2 ;;
      --use-existing-branch) use_existing_branch="true"; shift ;;
      --no-cd) do_cd="false"; shift ;;
      --fetch) do_fetch="true"; shift ;;
      -h|--help) usage; return 0 ;;
      *) die "Unknown option: $1 (try: ./worktreectl.sh help)"; return 1 ;;
    esac
  done

  local suffix
  suffix="$(sanitize_dir_suffix "$name")" || return 1

  if [[ -z "$root" ]]; then
    root="$(default_worktree_root)" || return 1
  fi

  if [[ "$do_fetch" == "true" ]]; then
    info "Fetching latest refs (git fetch --prune)..."
    git fetch --prune || { die "git fetch failed."; return 1; }
  fi

  if [[ "$use_existing_branch" == "true" && -n "$from" ]]; then
    warn "--from is ignored when --use-existing-branch is set."
  fi

  if [[ "$use_existing_branch" != "true" ]]; then
    if [[ -z "$from" ]]; then
      from="$(choose_default_base)"
    fi
    require_ref "$from" || return 1
  fi

  if [[ -z "$branch" ]]; then
    branch="${branch_prefix}${name}"
  fi
  require_branch_name "$branch" || return 1

  mkdir -p "$root" || { die "Failed to create root directory: $root"; return 1; }
  local root_abs="$root"
  if [[ -d "$root" ]]; then
    root_abs="$(cd "$root" && pwd)"
  fi
  local path="${root_abs}/${dir_prefix}${suffix}"

  info "Repo:   $(git_top)"
  info "Root:   $root_abs"
  info "Name:   $name"
  info "Path:   $path"
  info "Branch: $branch"
  if [[ "$use_existing_branch" == "true" ]]; then
    info "Base:   (existing branch)"
  else
    info "Base:   $from"
  fi

  if [[ "$use_existing_branch" != "true" && "$from" == "HEAD" ]]; then
    if ! git diff --quiet || ! git diff --cached --quiet; then
      warn "Working tree has uncommitted changes; base is HEAD. New branch will start from current HEAD commit (not uncommitted changes)."
    fi
  fi

  [[ ! -e "$path" ]] || { die "Path already exists: $path"; return 1; }

  if [[ "$use_existing_branch" == "true" ]]; then
    local_branch_exists "$branch" || { die "Branch '$branch' does not exist locally; cannot use existing branch."; return 1; }
  else
    if local_branch_exists "$branch"; then
      die "Local branch '$branch' already exists. Use --use-existing-branch, or pick another --branch."
      return 1
    fi
  fi

  if local_branch_exists "$branch"; then
    if branch_in_use_by_worktree "$branch"; then
      die "Branch '$branch' is already checked out in an existing worktree. Choose another branch or remove the other worktree first."
      return 1
    fi
  fi

  if [[ "$use_existing_branch" == "true" ]]; then
    info "Creating worktree using existing branch..."
    git worktree add "$path" "$branch" || { die "Failed to create worktree at: $path"; return 1; }
  else
    info "Creating worktree and new branch..."
    git worktree add -b "$branch" "$path" "$from" || { die "Failed to create worktree at: $path"; return 1; }
  fi

  info "Worktree created: $path"
  if is_sourced && [[ "$do_cd" == "true" ]]; then
    cd "$path" || { die "Failed to cd into: $path"; return 1; }
    info "Now in: $(pwd)"
  else
    echo "$path"
    info "Tip: source the script to auto-cd: source ./worktreectl.sh create <name>"
  fi
}

cmd_remove() {
  require_git_repo || return 1

  local name="${1:-}"
  [[ -n "$name" ]] || { die "remove requires a <name>. Try: ./worktreectl.sh help"; return 1; }
  shift || true

  local dir_prefix="$DIR_PREFIX_DEFAULT"
  local root="${WORKTREE_ROOT:-}"
  local force="false"
  local delete_branch="false"
  local delete_branch_force="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir-prefix)
        [[ -n "${2:-}" ]] || { die "--dir-prefix requires a value."; return 1; }
        dir_prefix="${2}"; shift 2 ;;
      --root)
        [[ -n "${2:-}" ]] || { die "--root requires a path."; return 1; }
        root="${2}"; shift 2 ;;
      --force) force="true"; shift ;;
      --delete-branch) delete_branch="true"; shift ;;
      --delete-branch-force) delete_branch_force="true"; delete_branch="true"; shift ;;
      -h|--help) usage; return 0 ;;
      *) die "Unknown option: $1 (try: ./worktreectl.sh help)"; return 1 ;;
    esac
  done

  if [[ -z "$root" ]]; then
    root="$(default_worktree_root)" || return 1
  fi
  local root_abs="$root"
  if [[ -d "$root" ]]; then
    root_abs="$(cd "$root" && pwd)"
  fi

  local suffix
  suffix="$(sanitize_dir_suffix "$name")" || return 1
  local path="${root_abs}/${dir_prefix}${suffix}"

  [[ -e "$path" ]] || { die "Worktree path not found: $path"; return 1; }

  local branch_ref=""
  branch_ref="$(git worktree list --porcelain | awk -v p="$path" '
    $1=="worktree" {w=$2}
    $1=="branch" && w==p {print $2}
  ' || true)"

  info "Removing worktree: $path"
  if [[ "$force" == "true" ]]; then
    git worktree remove -f "$path" || { die "git worktree remove failed for: $path"; return 1; }
  else
    git worktree remove "$path" || { die "git worktree remove failed for: $path"; return 1; }
  fi

  info "Worktree removed."

  if [[ "$delete_branch" == "true" ]]; then
    if [[ -z "$branch_ref" ]]; then
      warn "Could not determine branch for $path; skipping branch deletion."
      return 0
    fi
    local b="${branch_ref#refs/heads/}"
    if [[ "$b" == "$branch_ref" ]]; then
      warn "Branch ref is not a local heads ref ($branch_ref); skipping branch deletion."
      return 0
    fi

    if branch_in_use_by_worktree "$b"; then
      die "Refusing to delete branch '$b' because it is checked out in another worktree."
      return 1
    fi

    info "Deleting branch: $b"
    if [[ "$delete_branch_force" == "true" ]]; then
      git branch -D "$b" || { die "Failed to force delete branch: $b"; return 1; }
    else
      git branch -d "$b" || { die "Branch delete failed (likely unmerged). Re-run with --delete-branch-force if you really want to."; return 1; }
    fi
  else
    info "Branch kept (default). Use --delete-branch if you want branch deletion."
  fi
}

main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    create) cmd_create "$@" || return 1 ;;
    remove) cmd_remove "$@" || return 1 ;;
    list)   cmd_list || return 1 ;;
    help|-h|--help) usage ;;
    *) die "Unknown command: $cmd (try: ./worktreectl.sh help)"; return 1 ;;
  esac
}

if is_sourced; then
  main "$@"
else
  main "$@"
  exit $?
fi
