# Project Name

<!-- Replace with your project description -->

## Getting Started

<!-- Add your project-specific setup instructions here -->

## Multi-Agent Development

This repo is configured for parallel AI agent development. See [AGENTS.md](AGENTS.md) for instructions on running multiple AI CLIs (Claude Code, Codex, etc.) simultaneously.

**Quick start for agents:**
```bash
./tools/worktree/worktreectl.sh create <agent-name>
code ../.worktrees/<repo>/worktree_<agent-name>
```

## Project Structure

```
.
├── AGENTS.md           # Multi-agent workflow instructions
├── README.md           # This file
└── tools/
    └── worktree/       # Git worktree management scripts
        ├── worktreectl.sh
        └── create_worktree.sh
```

## License

<!-- Add your license here -->
