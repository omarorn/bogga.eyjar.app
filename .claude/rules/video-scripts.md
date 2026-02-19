---
paths: "scripts/*video*.sh", "scripts/*ffmpeg*.sh"
---

# Video Processing Scripts

Video encoding with ffmpeg is CPU-intensive and requires extended timeouts.

## Timeout Requirements

| Operation | Minimum Timeout | Recommended |
|-----------|----------------|-------------|
| Video normalization | 300000ms (5 min) | 600000ms (10 min) |
| Video combining | 300000ms (5 min) | 600000ms (10 min) |
| Format conversion | 180000ms (3 min) | 300000ms (5 min) |

## Pattern

```bash
# Use extended timeout for any ffmpeg script
Bash(
  command="bash /path/to/video-script.sh",
  timeout=600000  # 10 minutes
)
```

## Why

- ffmpeg re-encodes video frame-by-frame (slow)
- Multiple videos compound processing time
- CPU speed varies (WSL, containers, CI)
- Default 2-minute timeout causes premature failures

## Background Execution

Scripts with timeout >120000ms automatically run in background:
- Conversation continues while processing
- Monitor with: `tail -50 /tmp/claude/.../task_id.output`
- System notifications when output updates
