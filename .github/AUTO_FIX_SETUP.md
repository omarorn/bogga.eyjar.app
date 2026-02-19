# Auto-Fix GitHub Issues with Claude

This GitHub Actions workflow automatically analyzes new issues and creates pull requests with fixes.

## 🚀 How It Works

1. **Issue Created** → A new issue is opened in your repository
2. **Claude Analyzes** → Claude reads the issue, searches the codebase, and determines if it can fix it
3. **Fix Created** → If possible, Claude creates the necessary code changes
4. **PR Opened** → A pull request is automatically created with the fix
5. **Review & Merge** → You review the PR and merge if it looks good

## 📋 Setup Instructions

### Step 1: Add GitHub Secret

You need to add your Anthropic API key to GitHub Secrets:

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `ANTHROPIC_API_KEY`
5. Value: Your API key from https://console.anthropic.com/
6. Click **Add secret**

### Step 2: Enable Workflow Permissions

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **Workflow permissions**
3. Select **Read and write permissions**
4. Check **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

### Step 3: Test It!

Create a test issue to see it in action:

**Title:** Fix typo in README
**Body:**
```
There's a typo in the README.md file on line 10.
It says "Litla Gámaleigan is a IoT platform" but should be "Litla Gámaleigan is an IoT platform".
```

Claude should automatically:
- Analyze the issue
- Find the README.md file
- Create a fix
- Open a PR

## 🎯 What Issues Can Claude Auto-Fix?

Claude works best on:

✅ **Simple bugs:**
- Typos in code or documentation
- Missing imports
- Simple logic errors
- Configuration fixes

✅ **Code improvements:**
- Adding missing type annotations
- Fixing linting errors
- Simple refactoring

✅ **Documentation:**
- Fixing typos
- Adding missing documentation
- Updating outdated info

❌ **What Claude can't auto-fix:**
- Complex architectural changes
- Issues requiring external dependencies
- Vague or unclear issues
- Issues requiring user input or design decisions

## 🔧 Manual Trigger

You can also trigger Claude on existing issues by commenting:

```
/claude fix
```

This will make Claude analyze the issue and create a fix even if it wasn't automatically triggered.

## 📊 Workflow Files

- `.github/workflows/auto-fix-issues.yml` - GitHub Actions workflow
- `.github/scripts/fix-issue.js` - Node.js script that calls Claude API
- `.github/scripts/package.json` - Dependencies for the script

## 🛡️ Safety Features

- Claude only creates a PR, it doesn't merge automatically
- You always review before merging
- If Claude can't fix an issue, it comments with analysis instead
- All changes are tracked in git history
- PRs are labeled with `automated-fix` and `claude`

## 💰 Cost Considerations

- Each issue analysis uses ~8K tokens (~$0.02-0.05 per issue)
- Only runs when new issues are created
- You can disable the workflow anytime

## 🔍 Monitoring

Check workflow runs:
1. Go to **Actions** tab in GitHub
2. Click **Auto-fix Issues with Claude**
3. See all runs and their results

## ⚙️ Customization

### Only fix issues with a specific label

Edit `.github/workflows/auto-fix-issues.yml`:

```yaml
jobs:
  auto-fix:
    if: contains(github.event.issue.labels.*.name, 'auto-fix')
```

### Change Claude model

Edit `.github/scripts/fix-issue.js`:

```javascript
model: 'claude-sonnet-4-5-20250929', // or 'claude-opus-4-5-20251101' for more complex fixes
```

### Skip certain file types

Add to `.github/scripts/fix-issue.js` in the `findRelevantFiles` function:

```javascript
const results = execSync(
  `git grep -l -i "${keyword}" -- "*.js" "*.ts" "*.tsx" || true`,
  { encoding: 'utf-8' }
).trim();
```

## 🐛 Troubleshooting

**Workflow doesn't run:**
- Check that you have the `ANTHROPIC_API_KEY` secret set
- Verify workflow permissions are enabled
- Check the Actions tab for error messages

**Claude can't fix issues:**
- Make sure issue descriptions are clear and detailed
- Include file names and line numbers if possible
- Mention specific error messages

**PRs have wrong changes:**
- Claude might have misunderstood the issue
- Close the PR and add more details to the issue
- Comment `/claude fix` to retry

## 📚 Examples

### Example 1: Fix Import Error

**Issue:**
```
Title: Missing import in admin dashboard
Body: The file litla-admin/src/components/Dashboard.tsx is missing an import for useState from React.
```

**Result:** Claude adds `import { useState } from 'react';` and creates a PR.

### Example 2: Update Documentation

**Issue:**
```
Title: Update deployment instructions
Body: The README says to use `npm run build` but we now use `npm run deploy`. Please update the README.md file.
```

**Result:** Claude updates README.md and creates a PR.

## 🎓 Learn More

- [Claude API Documentation](https://docs.anthropic.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Claude Code](https://claude.com/claude-code)

---

**Need help?** Open an issue and tag it with `automation-help`!
