---
description: Push .claude config updates from the current project back to the 2076-cloudflare-template
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Sync to Template

Push improvements from the current project's `.claude/` directory back into the 2076-cloudflare-template repository.

## Context

- **Template location:** `~/Documents/GitHub/2076-cloudflare-template/2076-template-project/`
- **Current project:** The project you are running in right now
- **Direction:** Current project -> Template (generalize + push)

## Your Task

Synchronize `.claude/` configuration files (rules, commands, skills, agents, settings) from this project back to the template, replacing project-specific values with `{{PLACEHOLDERS}}`.

### Step 1: Identify Source and Target

```
SOURCE: <current project>/.claude/
TARGET: ~/Documents/GitHub/2076-cloudflare-template/2076-template-project/.claude/
```

Read the current project's CLAUDE.md to understand its domain, names, and URLs.

### Step 2: Discover New or Changed Files

Compare the two `.claude/` directories:

1. **List files in both locations:**
   ```bash
   find .claude/ -name "*.md" -o -name "*.json" | sort
   find ~/Documents/GitHub/2076-cloudflare-template/2076-template-project/.claude/ -name "*.md" -o -name "*.json" | sort
   ```

2. **Find files that exist in source but NOT in template** (new files to add)

3. **Find files that exist in both** — compare content (ignore CRLF/LF differences):
   ```bash
   diff <(tr -d '\r' < source_file) <(tr -d '\r' < template_file)
   ```

4. **Skip files with only line-ending differences** (CRLF vs LF)

### Step 3: Template-ize New Files

Before copying new rules/commands/skills to the template, replace ALL project-specific values with placeholders:

| Project-Specific | Template Placeholder |
|------------------|---------------------|
| Domain names (e.g., `gamaleigan.is`) | `{{DOMAIN}}` |
| App names (e.g., `litla-admin`) | `{{APP_NAME}}` or descriptive |
| Package scopes (e.g., `@litla/`) | `@{{PROJECT_SCOPE}}/` |
| Database names (e.g., `litla-gamaleigan-db`) | `{{D1_DATABASE_NAME}}` |
| Worker names | `{{WORKER_NAMES}}` |
| Company references | `{{COMPANY_DOMAIN}}` |
| Project-specific paths (e.g., `apps/litla-drivers/`) | Generic paths |

**Keep generic:** Rules should apply to ANY Cloudflare Workers project, not just the source project.

### Step 4: Present Changes for Approval

Show a summary table:

```
NEW FILES (to add to template):
  - .claude/rules/new-rule.md — [description]

UPDATED FILES (content changes):
  - .claude/rules/existing-rule.md — [what changed]

SKIPPED (line-ending only):
  - .claude/rules/unchanged-rule.md
```

Wait for user approval before writing.

### Step 5: Apply Changes

1. Write template-ized new files to the template directory
2. Update changed files with merged content
3. Update template CLAUDE.md if new rules/commands/skills were added (update the tables)

### Step 6: Commit

```bash
cd ~/Documents/GitHub/2076-cloudflare-template/2076-template-project
git add .claude/ CLAUDE.md
git commit -m "sync: Update template from [project-name]

- [list of changes]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Guardrails

- **NEVER copy project-specific secrets, API keys, or .env files**
- **NEVER copy .claude/settings.local.json** (local-only config)
- **ALWAYS template-ize** before copying — no project-specific values in template
- **ALWAYS show diff summary** before writing — user must approve
- **ALWAYS ignore CRLF/LF differences** — use `tr -d '\r'` when comparing
- **ALWAYS update CLAUDE.md tables** if adding new rules/commands/skills to template

---
*Generated from session workflow: Litla_Gamaleigan -> 2076-cloudflare-template sync*
