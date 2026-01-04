# Worktree Tooling

Git worktree manager for multi-agent AI development.

## Why Worktrees?

When two AI agents share a VS Code window and one switches branches, *both* end up on the same branch. Worktrees solve this by giving each agent its own directory with its own branch checkout.

## Commands

| Command | Description |
|---------|-------------|
| `create <name>` | Create a new worktree (and branch) |
| `remove <name>` | Remove a worktree (keeps branch by default) |
| `list` | List all worktrees |
| `help` | Show usage |

## Common Flags

| Flag | Description |
|------|-------------|
| `--from <ref>` | Base ref to branch from (default: auto-detects main/master) |
| `--branch <name>` | Explicit branch name (default: `agent/<name>`) |
| `--branch-prefix <prefix>` | Branch prefix (default: `agent/`) |
| `--dir-prefix <prefix>` | Directory prefix (default: `worktree_`) |
| `--root <path>` | Where to put worktrees (default: `../.worktrees/<repo>`) |
| `--use-existing-branch` | Attach worktree to an existing branch |
| `--fetch` | Run `git fetch --prune` before creating |
| `--no-cd` | Don't auto-cd into worktree when sourced |
| `--delete-branch` | Also delete the branch when removing worktree |
| `--delete-branch-force` | Force delete branch (`-D`) even if unmerged |
| `--force` | Force remove worktree even with uncommitted changes |

**Environment variable**: Set `WORKTREE_ROOT` to override the default worktree location.

## Example Workflow

Run these commands from the **repo root** (not from `tools/worktree/`):

```bash
# Agent 1 creates their worktree
./tools/worktree/worktreectl.sh create claude-task

# Agent 2 creates their worktree
./tools/worktree/worktreectl.sh create codex-task

# Each agent opens their worktree in a separate VS Code window
code ../.worktrees/<repo>/worktree_claude-task
code ../.worktrees/<repo>/worktree_codex-task

# When done
./tools/worktree/worktreectl.sh remove claude-task --delete-branch
./tools/worktree/worktreectl.sh remove codex-task --delete-branch
```

## Full Documentation

See the main worktree repo: https://github.com/dazzaji/worktree
