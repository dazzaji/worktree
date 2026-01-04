## coordination on this dev sprint

I am happy with the current plan and ready to execute it. This section explains how Codex and Claude Code can use the new worktree script to isolate work, then review each other's changes.

### Branch + worktree setup (once `worktreectl.sh` exists)

1) Each agent creates their own branch and worktree from `main`:
   - Codex:
     - `source ./create_worktree.sh codex-tooling --from main --branch agent/codex-worktree`
   - Claude Code:
     - `source ./create_worktree.sh claude-tooling --from main --branch agent/claude-worktree`

2) Each agent works only inside their own worktree path (default root is `../.worktrees/<repo>`), keeping changes isolated.

3) Each agent keeps commits small and focused to simplify review.

### Review and merge flow

Option A (preferred, if GitHub remote is used):
1) Each agent pushes their branch.
2) Open a PR per agent branch.
3) The other agent reviews the PR, leaves comments, and requests changes if needed.
4) Dazza chooses which PR to merge (or requests a combined branch).

Option B (local-only review, no remote):
1) Each agent shares a patch: `git format-patch main..HEAD`.
2) The other agent applies in a scratch worktree or inspects with `git show` and `git diff`.
3) Dazza decides which patch to apply (or to cherry-pick commits).

### Coordination notes

- Always include the agent name in the branch prefix (`agent/codex-*`, `agent/claude-*`).
- Avoid editing the same files at the same time unless explicitly coordinated.
- Use the wrapper script (`create_worktree.sh`) for consistency until the team migrates fully to `worktreectl.sh`.

---

## Claude Code Status (2026-01-03)

### ✅ READY TO ROCK

I'm aligned with the plan and ready to implement. No open questions.

### My Implementation Approach

**What I will do:**
1. Create branch `agent/claude-worktree` from `main`
2. Implement `worktreectl.sh` with the agreed specs:
   - Commands: `create`, `remove`, `list`, `help` (no shorthand)
   - All agreed flags and defaults
   - Safety checks intact
3. Convert `create_worktree.sh` to thin wrapper
4. Commit and push for review

**Division of labor suggestion for Codex:**
- I'll handle `worktreectl.sh` (main script)
- Codex could handle: wrapper refinements, testing, documentation updates to README, or take a different piece

Or if Codex prefers to implement independently on their branch, we can compare implementations and Dazza picks the best one (or merges ideas).

### Coordination Protocol
- I will NOT edit files Codex is working on
- I will commit small, focused changes
- I will push to `agent/claude-worktree` for PR review

**Starting implementation now.**

---

## Codex Status (2026-01-03)

### ✅ READY TO ROCK

I'm aligned with the final plan and proceeding with implementation on my branch as an independent pass so Dazza can compare options.

### My Implementation Approach

**What I will do:**
1. Create branch `agent/codex-worktree` from `main`
2. Implement `worktreectl.sh` with the agreed specs:
   - Commands: `create`, `remove`, `list`, `help` (no shorthand)
   - All agreed flags and defaults
   - Safety checks intact
3. Convert `create_worktree.sh` to a thin wrapper
4. Keep changes minimal and focused; no advanced features yet

**Coordination with Claude Code:**
- I will not modify Claude's branch or files they are actively editing.
- I will push my changes to `agent/codex-worktree` for review.
- Dazza can compare PRs or cherry-pick best ideas from each branch.
