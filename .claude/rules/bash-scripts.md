---
paths: "**/*.sh", "scripts/**/*.sh"
---

# Bash Script Execution

Always make scripts executable before running them in WSL/Git environments.

## Pattern

| Step | Command |
|------|---------|
| 1. Make executable | `chmod +x script.sh` |
| 2. Run script | `bash script.sh` or `./script.sh` |

## Why

- Git may not preserve executable bit across Windows/WSL
- WSL file systems may mount with different permissions
- `chmod +x` is idempotent (safe to run multiple times)

## Example

```bash
# Always do this before running any .sh file
chmod +x /path/to/script.sh
bash /path/to/script.sh
```
