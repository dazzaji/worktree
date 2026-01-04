# worktree

**Run multiple AI coding agents in parallel on the same repo — without conflicts.**

This repo provides `worktreectl.sh`, a Git worktree manager designed for multi-agent AI development. Each agent gets its own isolated directory and branch, so Claude Code, Codex, or any other AI CLI can work simultaneously without stepping on each other.

## The Problem

When two AI agents share a VS Code window and one switches branches, *both* agents end up on the same branch. They overwrite each other's work, read each other's files, and create merge chaos.

## The Solution

Git worktrees. Each agent works in a **separate directory** with its **own branch checkout**. No branch switching in shared space. No conflicts.

```
repo/                           # main repo (on main branch)
../.worktrees/repo/
    worktree_claude-task/       # Claude Code works here (agent/claude-task)
    worktree_codex-task/        # Codex works here (agent/codex-task)
```

## Quickstart

```bash
# 1. Create worktrees for each agent
./worktreectl.sh create claude-task
./worktreectl.sh create codex-task

# 2. Open each worktree in its own VS Code window
code ../.worktrees/<repo>/worktree_claude-task
code ../.worktrees/<repo>/worktree_codex-task

# 3. Run each agent CLI in its own window
#    Claude Code in window 1, Codex in window 2
#    Both work in parallel, no conflicts

# 4. When done, clean up
./worktreectl.sh remove claude-task --delete-branch
./worktreectl.sh remove codex-task --delete-branch
```

## Use Cases

- **Two agents, same task, different approaches** — Compare implementations, merge the best
- **Two agents, different tasks** — Divide work (e.g., one implements, one writes docs)
- **Agent review of agent work** — One implements, the other reviews the PR
- **Fast experimentation** — Spin up a worktree, try something, delete if it fails
- **Reproducible agent runs** — Each worktree holds its own build artifacts, venv, node_modules

## Why Worktrees (Not Just Branches)

Branches share the same working directory. If Agent A checks out `branch-a` and Agent B checks out `branch-b`, the last one to run `git checkout` wins — and both agents are now on the same branch.

Worktrees are **separate directories**, each with its own branch checkout. Agent A works in `worktree_a/` on `branch-a`. Agent B works in `worktree_b/` on `branch-b`. They never interfere.

## Why Separate VS Code Windows

Each VS Code window has one working directory. If both agents share a window, file reads/writes go to the same place. Separate windows = separate contexts = true isolation.

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
| `--root <path>` | Where to put worktrees (default: `../.worktrees/<repo>`) |
| `--use-existing-branch` | Attach worktree to an existing branch |
| `--delete-branch` | Also delete the branch when removing worktree |
| `--no-cd` | Don't auto-cd into worktree when sourced |

## Defaults

These work out of the box for most multi-agent setups:

| Setting | Default |
|---------|---------|
| Base ref | `main` (fallback: master, origin/main, origin/master, HEAD) |
| Branch prefix | `agent/` |
| Directory prefix | `worktree_` |
| Worktree root | `../.worktrees/<repo>/` (outside repo, keeps it clean) |

## Agent Conventions

For AI agents reading this doc:

- **Your worktree path**: `../.worktrees/<repo>/worktree_<name>/`
- **Your branch**: `agent/<name>` (unless overridden)
- **Stay in your directory**: Never `cd` to another agent's worktree
- **Never run `git checkout`**: Your branch is already checked out in your worktree
- **Commit and push normally**: `git add`, `git commit`, `git push` all work as expected

## Backwards Compatibility

`create_worktree.sh` still works as a thin wrapper:

```bash
source ./create_worktree.sh my-task  # equivalent to: source ./worktreectl.sh create my-task
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| "Branch already in use" | Another worktree has this branch checked out. Use `--branch <other-name>` or remove the other worktree first. |
| "Path already exists" | A worktree with this name exists. Use a different name or remove it with `./worktreectl.sh remove <name>`. |
| "Base ref not found" | The branch you're trying to base from doesn't exist. Use `--from <valid-ref>` or run `git fetch`. |

## Related Docs

- [coordination_plan.md](coordination_plan.md) — Multi-agent coordination workflow and lessons learned
- [dev_plan.md](dev_plan.md) — Technical decisions and implementation notes

## Safety Guarantees

This script prevents common foot-guns:

- Checks for directory collisions before creating
- Checks for branch name collisions
- Validates branch names against Git rules
- Warns if base is HEAD with uncommitted changes
- Refuses to delete branches still in use by other worktrees
- Keeps branches by default when removing worktrees (explicit opt-in to delete)
