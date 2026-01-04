# worktree

This repo includes a practical Git worktree helper for LLM/agent workflows.
The primary script is `worktreectl.sh`. The older `create_worktree.sh` remains as a thin wrapper for backward compatibility.

## Why it’s a good fit for LLM/agent coding projects

Worktrees map nicely to agent patterns:

* **One worktree per task/branch** (feature, refactor, experiment) → less context bleed.
* **Concurrent experiments** (two approaches in parallel) without stash gymnastics.
* **Reproducible agent runs**: each worktree can hold its own build artifacts, venv, node_modules, caches, logs.
* **Fast rollback**: delete worktree + branch and you’ve cleanly removed an experiment.

This script specifically helps because it:

* enforces *unique naming*,
* creates a fresh branch automatically,
* and handles the “cd into it” step (when sourced).

## Quick start

Create a worktree (default base is `main` if present, then fallbacks):
```bash
source ./create_worktree.sh my-task
```

Explicit base, branch name, and root:
```bash
./worktreectl.sh create my-task --from main --branch agent/my-task --root ../.worktrees/your-repo
```

Remove a worktree (keeps branch by default):
```bash
./worktreectl.sh remove my-task
```

## Key defaults and options

Defaults (override with flags):
* Base ref: `main` → `master` → `origin/main` → `origin/master` → `HEAD`
* Branch prefix: `agent/`
* Directory prefix: `worktree_`
* Worktree root: `../.worktrees/<repo>`

Common overrides:
* `--from <ref>` to choose a base
* `--branch <name>` or `--branch-prefix <prefix>` to control branch names
* `--root <path>` or `WORKTREE_ROOT` to change the root
* `--use-existing-branch` to attach a worktree to an existing branch
* `--no-cd` to prevent auto-`cd` even when sourced

## Multi-agent workflow tip

For true isolation, open each worktree in its own VS Code window and run each agent in its own window.
