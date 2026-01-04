# worktree

It’s a solid “keeper” **if your default workflow is**: *spin up a clean parallel checkout from whatever you’re currently on, on a new branch, and jump into it immediately.* For LLM/agent coding projects, worktrees are genuinely useful, and this script covers the main foot-guns (dir collision, branch collision, not-in-repo) and makes the workflow frictionless.

That said, it’s not “so perfect you’ll never touch it again.” It’s a good base, and for agent-heavy work you’ll probably want 2–4 small upgrades.

## Why it’s a good fit for LLM/agent coding projects

Worktrees map nicely to agent patterns:

* **One worktree per task/branch** (feature, refactor, experiment) → less context bleed.
* **Concurrent experiments** (two approaches in parallel) without stash gymnastics.
* **Reproducible agent runs**: each worktree can hold its own build artifacts, venv, node_modules, caches, logs.
* **Fast rollback**: delete worktree + branch and you’ve cleanly removed an experiment.

This script specifically helps because it:

* enforces *unique naming*,
* creates a fresh branch automatically,
* and handles the “cd into it” step (which matters when you’re moving quickly).

## The main reasons you might want to tweak it

These are the common mismatches for real usage:

1. **It always branches from current HEAD**

   * For agent work you often want: “branch from `main` (or a clean base)” not from wherever you happen to be.
   * Today, if you’re mid-feature and run this, your new worktree starts from your mid-feature state.

2. **Branch naming is forced to `worktree_<name>`**

   * That’s fine personally, but teams often prefer `feature/<x>`, `fix/<x>`, `spike/<x>`.
   * Also: prefixing the branch name with `worktree_` is a bit semantically odd; “worktree” is an implementation detail, not the intent.

3. **It assumes worktrees live under the current repo directory**

   * Many people prefer a dedicated folder like `../worktrees/<repo>/...` to keep the main repo directory uncluttered.

4. **No automatic remote push/upstream setup**

   * In agent workflows you often want a quick “create branch + set upstream on first push” pattern (not mandatory, but convenient).

## Recommendation

Save it somewhere *if you are actually using worktreess frequently*—because you’ll use it over and over and small friction adds up. But treat it as a **template you’ll refine**, not a sacred artifact.

Practically:

* If you’ll use worktrees **weekly or more** → **keeper**, then add the few upgrades below.
* If you’ll use them **a couple times a year** → don’t overthink it; keep this around or rewrite when needed.

## If you keep it, these upgrades make it “agent-grade”

In priority order:

1. **Default base branch**

   * Add an option like `--from main` (default `main`) so new worktrees come from a clean base unless you explicitly say “from current HEAD”.

2. **Separate directory name from branch name**

   * Directory can be `worktree_<name>` but branch can be `feature/<name>` or `<name>`.
   * This is especially helpful when your agent creates many short-lived worktrees.

3. **Stable worktree root**

   * Put them in `../.worktrees/<repo>/<name>` (or `~/worktrees/<repo>/<name>`).
   * Keeps repo root clean and makes cleanup easier.

4. **Optional “cleanup” companion command**

   * A second script: remove worktree + delete branch in one go (with safety checks).

## Verdict on *this* specific script

* Quality: **good** (it’s careful and user-friendly).
* “Keeper as-is”: **keeper if you accept its defaults** (branch from current HEAD, naming scheme).
* Best path: **save it, then spend 15 minutes making it match your preferred workflow**.

If you want, I can produce a revised version tailored for LLM agent projects with:

* `--from main` default,
* `--branch feature/<name>` optional,
* worktrees stored under a dedicated root,
* and a paired `remove_worktree.sh` cleanup tool.
