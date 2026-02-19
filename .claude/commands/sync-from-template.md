---
description: Pull latest .claude config from 2076-cloudflare-template into the current project
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Sync from Template

Pull the latest `.claude/` configuration from the 2076-cloudflare-template into the current project.

## Context

- **Template location:** `~/Documents/GitHub/2076-cloudflare-template/2076-template-project/`
- **Current project:** The project you are running in right now
- **Direction:** Template -> Current project (specialize + pull)

## Your Task

Synchronize `.claude/` configuration files (rules, commands, skills, agents, settings) from the template into this project, adapting template placeholders to project-specific values.

### Step 1: Identify Project Values

Read the current project's CLAUDE.md and wrangler.toml to determine placeholder replacements:

| Template Placeholder | Find From |
|---------------------|-----------|
| `{{DOMAIN}}` | CLAUDE.md or wrangler.toml |
| `{{PROJECT_SCOPE}}` | Root package.json scope |
| `{{D1_DATABASE_NAME}}` | wrangler.toml `d1_databases` |
| `{{APP_NAME}}` | `apps/` directory names |
| `{{WORKER_NAMES}}` | wrangler.toml |
| `{{COMPANY_DOMAIN}}` | CLAUDE.md |

**Note:** Not all placeholders need replacing. Rules that use `{{PLACEHOLDERS}}` as documentation examples should keep them as-is (e.g., `_TEMPLATE-*.md` files).

### Step 2: Discover What's New or Changed

Compare template `.claude/` with current project:

1. **Find files in template but NOT in project** (new files to pull)

2. **Find files in both** — compare content (ignore CRLF/LF):
   ```bash
   diff <(tr -d '\r' < template_file) <(tr -d '\r' < project_file)
   ```

3. **Skip line-ending-only differences**

4. **Check settings.json** — template may have new plugins the project is missing

### Step 3: Present Changes for Approval

```
NEW FILES (to add from template):
  - .claude/rules/new-rule.md — [description]
  - .claude/commands/new-command.md — [description]

UPDATED FILES (template has newer content):
  - .claude/rules/existing-rule.md — [what changed]

SETTINGS UPDATES:
  - settings.json: Adding plugins: [list]

SKIPPED (project has custom version):
  - .claude/commands/project-specific.md — [reason]

PROJECT-ONLY (not in template, keeping):
  - .claude/commands/custom-command.md
```

Wait for user approval.

### Step 4: Apply Changes

1. **Copy new generic files** directly (rules, templates — these don't need placeholder replacement)
2. **Copy new commands/skills** — most are generic; only replace placeholders if the command references project paths
3. **Update settings.json** — merge new plugins (keep existing project plugins)
4. **Update project CLAUDE.md** if new rules/commands/skills were added:
   - Update rules count
   - Update plugins table
   - Add new items to relevant tables

### Step 5: Handle settings.json Merge

```typescript
// Merge strategy: union of both plugin sets
const templatePlugins = templateSettings.enabledPlugins;
const projectPlugins = projectSettings.enabledPlugins;
const merged = { ...templatePlugins, ...projectPlugins };
```

**Never remove** project-specific plugins. Only add missing ones from template.

### Step 6: Commit

```bash
git add .claude/ CLAUDE.md
git commit -m "sync: Update .claude config from template

- [list of changes]
- Synced from 2076-cloudflare-template

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Guardrails

- **NEVER overwrite project-specific commands** that don't exist in template (e.g., `/critique`)
- **NEVER remove plugins** from settings.json — only add new ones
- **NEVER replace project-specific CLAUDE.md** — only update tables/sections
- **ALWAYS show summary** before writing — user must approve
- **ALWAYS ignore CRLF/LF differences** when comparing
- **ALWAYS preserve project customizations** in files that exist in both locations
- **Template `_TEMPLATE-*.md` files** should be copied as-is (they are documentation templates)

---
*Generated from session workflow: 2076-cloudflare-template -> Litla_Gamaleigan sync*
