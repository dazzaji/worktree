# Multi-Agent Development Guide

This repo supports multiple AI agents (Claude Code, Codex, Gemini, etc.) working simultaneously using Git worktrees.

## Before You Start

**If another agent is already working in this repo, you MUST create your own worktree first.**

```bash
# Create your isolated worktree
./tools/worktree/worktreectl.sh create <your-task-name>

# Example:
./tools/worktree/worktreectl.sh create claude-feature
./tools/worktree/worktreectl.sh create codex-bugfix
```

Then ask the user to open that worktree in a **separate VS Code window**:
```bash
code ../.worktrees/<repo>/worktree_<your-task-name>
```

## Rules for Agents

1. **Stay in your worktree directory** - Never `cd` to another agent's worktree
2. **Never run `git checkout` in the main repo** - Your branch is already checked out in your worktree
3. **Commit and push normally** - `git add`, `git commit`, `git push` all work as expected
4. **Your branch**: `agent/<your-task-name>` (unless you specified `--branch`)
5. **Your path**: `../.worktrees/<repo>/worktree_<your-task-name>/`

## Why This Matters

When two agents share a VS Code window and one runs `git checkout`, BOTH agents end up on the same branch. Worktrees solve this by giving each agent its own directory with its own branch checkout.

## Quick Reference

| Command | Description |
|---------|-------------|
| `./tools/worktree/worktreectl.sh create <name>` | Create new worktree |
| `./tools/worktree/worktreectl.sh list` | List all worktrees |
| `./tools/worktree/worktreectl.sh remove <name>` | Remove worktree (keeps branch) |
| `./tools/worktree/worktreectl.sh remove <name> --delete-branch` | Remove worktree and branch |
| `./tools/worktree/worktreectl.sh help` | Show all options |

## Cleanup

When your task is complete:
```bash
./tools/worktree/worktreectl.sh remove <your-task-name> --delete-branch
```
