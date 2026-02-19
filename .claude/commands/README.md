# Project Slash Commands

This directory contains custom slash commands for Claude Code to streamline common workflows.

## Available Commands

### `/document-agent`

**Purpose:** Systematically document completed agent deliverables

**Usage:**
```
/document-agent [agent-id]
```

**What it does:**
- Provides template for retrieving agent output
- Guides systematic documentation of files, features, errors
- Ensures consistent format across all agent documentation
- Includes checklist to verify thorough documentation

**When to use:**
- After agent completes (TaskOutput shows completion)
- Before updating TODO.md or tasks.md
- When you need to capture agent deliverables for tracking

**See:** `commands/document-agent.md` for full template

---

## Creating New Commands

To create a new slash command:

1. **Create markdown file** in this directory: `commands/my-command.md`

2. **Add front matter** (optional, for metadata):
   ```markdown
   ---
   name: my-command
   description: Brief description
   ---
   ```

3. **Write command content** with instructions for Claude

4. **Use the command:** `/my-command` in Claude Code session

**Note:** Slash commands are project-specific. For cross-project commands, add to `~/.claude/commands/`

---

## Related

- **Scripts:** `scripts/` - Bash automation scripts (e.g., `batch-fix-types.sh`)
- **Global Commands:** `~/.claude/commands/` - User-level slash commands
- **Rules:** `.claude/rules/` - File-scoped correction patterns

---

**This directory helps codify project-specific workflows into reusable commands.**
