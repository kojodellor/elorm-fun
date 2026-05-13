# elorm-fun

Agent guidance files for the [awesome-claude-skills](https://github.com/anthropics/awesome-claude-skills) repository.

## Contents

| File | Purpose |
|---|---|
| [`agents/AGENTS.md`](./agents/AGENTS.md) | Universal AI agent guidance (Claude Code, Codex, Copilot, etc.) |
| [`agents/WARP.md`](./agents/WARP.md) | Warp terminal agent companion guide |

## What's inside

**AGENTS.md** covers the six core areas that make AI coding agents effective in this repo:
- Key commands (git, Connect plugin, MCP Builder eval harness)
- Project structure and skill package layout
- Code style with examples
- Git workflow and branch/commit/PR naming conventions
- Testing approach (no root test suite — validation is structural)
- Three-tier boundaries (✅ proceed / ⚠️ ask first / 🚫 never)

**WARP.md** is a Warp-focused companion with the same rules in a table-heavy, scannable format plus Warp-specific terminal tips.

## Usage

Copy `agents/AGENTS.md` to the root of your fork of awesome-claude-skills so AI agents automatically pick it up:

```bash
cp agents/AGENTS.md /path/to/awesome-claude-skills/AGENTS.md
cp agents/WARP.md   /path/to/awesome-claude-skills/WARP.md
```
