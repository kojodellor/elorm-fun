---
name: project-awesome-claude-skills
description: Context for the awesome-claude-skills repo — a curated Claude skill catalog with strict CI rules
metadata: 
  node_type: memory
  type: project
  originSessionId: c8ab2e69-3dec-4e08-b6f4-e91ad135a89a
---

Repo at `/Users/elorm/awesome-claude-skills`. Curated catalog of Claude Skills for Claude.ai, Claude Code, and the Claude API.

**Why:** No traditional app stack — every contribution's primary artifact is `SKILL.md`. CI enforces README format strictly (alphabetical, no emojis, no crypto/web3, listing-only PRs must only touch README.md).

**How to apply:** Before editing README.md always run `cat .github/workflows/label-ready-skill.yml`. New skills go in a lowercase-hyphenated folder copied from `template-skill/`. Commit message format: "Add [Skill Name] skill".

Key directories: `composio-skills/` (generated, don't edit), `mcp-builder/` (eval harness), `connect-apps-plugin/` (Claude Code plugin), `template-skill/` (canonical scaffold).

See `AGENTS.md` and `WARP.md` in the repo root for full agent guidance.
