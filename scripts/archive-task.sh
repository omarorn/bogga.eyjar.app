#!/bin/bash

# archive-task.sh
# Automate task archival from tasks.md → completedtasks.md
# Usage: ./scripts/archive-task.sh TASK-XXX

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}Task Archival Automation${NC}"
echo "Project: $PROJECT_ROOT"
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Task ID required${NC}"
    echo "Usage: ./scripts/archive-task.sh TASK-XXX"
    echo ""
    echo "Example: ./scripts/archive-task.sh TASK-092"
    exit 1
fi

TASK_ID="$1"

# File paths
TASKS_FILE="$PROJECT_ROOT/tasks.md"
COMPLETED_FILE="$PROJECT_ROOT/completedtasks.md"
TODO_FILE="$PROJECT_ROOT/TODO.md"

# Verify files exist
if [[ ! -f "$TASKS_FILE" ]]; then
    echo -e "${RED}Error: tasks.md not found${NC}"
    exit 1
fi

if [[ ! -f "$COMPLETED_FILE" ]]; then
    echo -e "${RED}Error: completedtasks.md not found${NC}"
    exit 1
fi

if [[ ! -f "$TODO_FILE" ]]; then
    echo -e "${RED}Error: TODO.md not found${NC}"
    exit 1
fi

# Check if task exists in tasks.md
if ! grep -q "### $TASK_ID:" "$TASKS_FILE"; then
    echo -e "${RED}Error: $TASK_ID not found in tasks.md${NC}"
    echo ""
    echo "Available tasks:"
    grep -E "^### TASK-" "$TASKS_FILE" | head -10
    exit 1
fi

echo -e "${YELLOW}Found task in tasks.md${NC}"
echo ""

# Extract task section from tasks.md (everything until next ### or ---)
TASK_CONTENT=$(awk "/^### $TASK_ID:/{flag=1; next} /^###|^---/{flag=0} flag" "$TASKS_FILE")

if [ -z "$TASK_CONTENT" ]; then
    echo -e "${RED}Error: Could not extract task content${NC}"
    exit 1
fi

# Show preview
echo -e "${BLUE}Task Preview:${NC}"
echo "$TASK_CONTENT" | head -20
echo ""

# Prompt for completion details
read -p "Completion date (YYYY-MM-DD) [$(date +%Y-%m-%d)]: " COMPLETION_DATE
COMPLETION_DATE=${COMPLETION_DATE:-$(date +%Y-%m-%d)}

read -p "Time spent (e.g., '1.5 hours', '30 min'): " TIME_SPENT

read -p "Additional notes (optional): " ADDITIONAL_NOTES

# Confirm archival
echo ""
echo -e "${YELLOW}Ready to archive:${NC}"
echo "  Task ID: $TASK_ID"
echo "  Completion Date: $COMPLETION_DATE"
echo "  Time Spent: $TIME_SPENT"
echo ""

read -p "Proceed with archival? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo -e "${YELLOW}Aborted.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Archiving task...${NC}"

# Step 1: Create completion entry
COMPLETION_ENTRY="### $TASK_ID ✅
**Completed:** $COMPLETION_DATE
**Time Spent:** $TIME_SPENT

$TASK_CONTENT"

if [ ! -z "$ADDITIONAL_NOTES" ]; then
    COMPLETION_ENTRY="$COMPLETION_ENTRY

**Notes:** $ADDITIONAL_NOTES"
fi

COMPLETION_ENTRY="$COMPLETION_ENTRY

---"

# Step 2: Find insertion point in completedtasks.md (after header, before first task)
# Insert after the header section (typically line 8-10)
HEADER_LINES=$(grep -n "^## " "$COMPLETED_FILE" | head -1 | cut -d: -f1)

# Create temp file with new content
{
    head -n "$HEADER_LINES" "$COMPLETED_FILE"
    echo ""
    echo "$COMPLETION_ENTRY"
    echo ""
    tail -n +$((HEADER_LINES + 1)) "$COMPLETED_FILE"
} > "$COMPLETED_FILE.tmp"

mv "$COMPLETED_FILE.tmp" "$COMPLETED_FILE"

echo -e "  ${GREEN}✓${NC} Added to completedtasks.md"

# Step 3: Remove from tasks.md
# Use sed to delete from ### TASK-XXX to the next ### or ---
sed -i "/^### $TASK_ID:/,/^###\|^---/{/^### $TASK_ID:/d; /^###\|^---/!d;}" "$TASKS_FILE"

echo -e "  ${GREEN}✓${NC} Removed from tasks.md"

# Step 4: Update statistics
echo -e "${YELLOW}Updating statistics...${NC}"

# Count tasks
COMPLETED_COUNT=$(grep -E "^### TASK-" "$COMPLETED_FILE" | wc -l)
ACTIVE_COUNT=$(grep -E "^### TASK-" "$TASKS_FILE" | wc -l)
BLOCKED_COUNT=$(grep -E "^### TASK-.*🚫" "$TASKS_FILE" | wc -l)
PENDING_COUNT=$((ACTIVE_COUNT - BLOCKED_COUNT))
TOTAL_TASKS=$((COMPLETED_COUNT + ACTIVE_COUNT))

# Calculate completion percentage
if [[ $TOTAL_TASKS -gt 0 ]]; then
    COMPLETION_PCT=$(awk "BEGIN {printf \"%.0f\", ($COMPLETED_COUNT / $TOTAL_TASKS) * 100}")
else
    COMPLETION_PCT=0
fi

# Get current date
CURRENT_DATE=$(date -u +"%B %d, %Y - %H:%M UTC")

# Update tasks.md header
sed -i "3s|^**Last Updated:.*|**Last Updated:** $CURRENT_DATE|" "$TASKS_FILE"
sed -i "4s|^**Total Active Tasks:.*|**Total Active Tasks:** $ACTIVE_COUNT|" "$TASKS_FILE"
sed -i "6s|^**Pending:.*|**Pending:** $PENDING_COUNT ($(awk "BEGIN {printf \"%.0f\", ($PENDING_COUNT / $ACTIVE_COUNT) * 100}")%)|" "$TASKS_FILE" 2>/dev/null || true
sed -i "7s|^**Blocked:.*|**Blocked:** $BLOCKED_COUNT ($(awk "BEGIN {printf \"%.0f\", ($BLOCKED_COUNT / $ACTIVE_COUNT) * 100}")%)|" "$TASKS_FILE" 2>/dev/null || true
sed -i "8s|^**Completed:.*|**Completed:** See [completedtasks.md](./completedtasks.md) ($COMPLETED_COUNT tasks archived)|" "$TASKS_FILE"

echo -e "  ${GREEN}✓${NC} tasks.md header updated"

# Update completedtasks.md header
sed -i "3s|^**Last Updated:.*|**Last Updated:** $CURRENT_DATE|" "$COMPLETED_FILE"
sed -i "4s|^**Total Completed:.*|**Total Completed:** $COMPLETED_COUNT tasks (${COMPLETION_PCT}% of all tasks)|" "$COMPLETED_FILE"

echo -e "  ${GREEN}✓${NC} completedtasks.md header updated"

# Update TODO.md header
sed -i "3s|^**Last Updated:.*|**Last Updated:** $CURRENT_DATE|" "$TODO_FILE"
sed -i "4s|^**Overall Completion:.*|**Overall Completion:** ${COMPLETION_PCT}%|" "$TODO_FILE"
sed -i "7c\\**Active Tasks:** $ACTIVE_COUNT | **Completed:** $COMPLETED_COUNT | **Blocked:** $BLOCKED_COUNT | **Total:** $TOTAL_TASKS" "$TODO_FILE"

echo -e "  ${GREEN}✓${NC} TODO.md header updated"

echo ""
echo -e "${GREEN}✓ Task archived successfully!${NC}"
echo ""
echo "Summary:"
echo "  - Completed tasks: $COMPLETED_COUNT (${COMPLETION_PCT}%)"
echo "  - Active tasks: $ACTIVE_COUNT ($PENDING_COUNT pending, $BLOCKED_COUNT blocked)"
echo "  - Total tasks: $TOTAL_TASKS"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add tasks.md completedtasks.md TODO.md && git commit -m 'Archive $TASK_ID'"
echo ""
