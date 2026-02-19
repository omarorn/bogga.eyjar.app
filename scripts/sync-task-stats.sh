#!/bin/bash

# sync-task-stats.sh
# Synchronize task statistics across completedtasks.md, tasks.md, and TODO.md
# Prevents statistical drift and ensures consistency

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root (script location)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}Task Statistics Synchronization${NC}"
echo "Project: $PROJECT_ROOT"
echo ""

# Files to sync
COMPLETED_FILE="$PROJECT_ROOT/completedtasks.md"
TASKS_FILE="$PROJECT_ROOT/tasks.md"
TODO_FILE="$PROJECT_ROOT/TODO.md"

# Verify files exist
if [[ ! -f "$COMPLETED_FILE" ]]; then
    echo -e "${RED}Error: completedtasks.md not found${NC}"
    exit 1
fi

if [[ ! -f "$TASKS_FILE" ]]; then
    echo -e "${RED}Error: tasks.md not found${NC}"
    exit 1
fi

if [[ ! -f "$TODO_FILE" ]]; then
    echo -e "${RED}Error: TODO.md not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Counting tasks...${NC}"

# Count completed tasks (exclude header line and section headers)
# Look for lines starting with "- **TASK-" or "### TASK-"
COMPLETED_COUNT=$(grep -E "^(- \*\*TASK-|### TASK-)" "$COMPLETED_FILE" | wc -l)

# Count active tasks in tasks.md
# Look for "#### TASK-" headers (each task has one header)
ACTIVE_COUNT=$(grep -E "^#### TASK-" "$TASKS_FILE" | wc -l)

# Count blocked tasks (marked with 🚫)
BLOCKED_COUNT=$(grep -E "^#### TASK-.*🚫" "$TASKS_FILE" | wc -l)

# Count pending tasks (active - blocked)
PENDING_COUNT=$((ACTIVE_COUNT - BLOCKED_COUNT))

# Calculate total tasks
TOTAL_TASKS=$((COMPLETED_COUNT + ACTIVE_COUNT))

# Calculate completion percentage (rounded)
if [[ $TOTAL_TASKS -gt 0 ]]; then
    COMPLETION_PCT=$(awk "BEGIN {printf \"%.0f\", ($COMPLETED_COUNT / $TOTAL_TASKS) * 100}")
else
    COMPLETION_PCT=0
fi

# Display findings
echo ""
echo -e "${GREEN}Current Statistics:${NC}"
echo "  Completed Tasks: $COMPLETED_COUNT"
echo "  Active Tasks: $ACTIVE_COUNT"
echo "    - Pending: $PENDING_COUNT"
echo "    - Blocked: $BLOCKED_COUNT"
echo "  Total Tasks: $TOTAL_TASKS"
echo "  Completion: ${COMPLETION_PCT}%"
echo ""

# Get current date for timestamp
CURRENT_DATE=$(date -u +"%B %d, %Y - %H:%M UTC")

# Ask for confirmation
read -p "Update all files with these statistics? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo -e "${YELLOW}Aborted.${NC}"
    exit 0
fi

echo -e "${YELLOW}Updating files...${NC}"

# Update tasks.md header (Icelandic format)
# Line 3: Last updated date
# Line 4: Statistics in compact format (Heildarverkefni | Lokið | Eftirstöðvar | Framvinda)
sed -i "4c\\**Heildarverkefni:** $TOTAL_TASKS | **Lokið:** $COMPLETED_COUNT | **Eftirstöðvar:** $ACTIVE_COUNT | **Framvinda:** ${COMPLETION_PCT}%" "$TASKS_FILE"
# Line 7: Update completedtasks.md reference with current count
sed -i "7s|Lokin verkefni ([0-9]* verkefni)|Lokin verkefni ($COMPLETED_COUNT verkefni)|" "$TASKS_FILE"

echo -e "  ${GREEN}✓${NC} tasks.md updated"

# Update TODO.md header
sed -i "3s|^**Last Updated:.*|**Last Updated:** $CURRENT_DATE|" "$TODO_FILE"
sed -i "4s|^**Overall Completion:.*|**Overall Completion:** ${COMPLETION_PCT}%|" "$TODO_FILE"
# Use change command for line with pipe characters in content
sed -i "7c\**Active Tasks:** $ACTIVE_COUNT | **Completed:** $COMPLETED_COUNT | **Blocked:** $BLOCKED_COUNT | **Total:** $TOTAL_TASKS" "$TODO_FILE"

# Update quick reference in TODO.md (line 16-17)
# Use different approach to avoid sed delimiter issues with pipe characters
sed -i "16c\| **[tasks.md](./tasks.md)** | Active tasks with detailed specifications ($ACTIVE_COUNT tasks) |" "$TODO_FILE"
sed -i "17c\| **[completedtasks.md](./completedtasks.md)** | Completed task archive ($COMPLETED_COUNT tasks) |" "$TODO_FILE"

echo -e "  ${GREEN}✓${NC} TODO.md updated"

# Update completedtasks.md header (Total Completed count and percentage)
sed -i "4s|^**Total Completed:.*|**Total Completed:** $COMPLETED_COUNT tasks (${COMPLETION_PCT}% of $TOTAL_TASKS total tasks)|" "$COMPLETED_FILE"

echo -e "  ${GREEN}✓${NC} completedtasks.md updated"

echo ""
echo -e "${GREEN}✓ All files synchronized successfully!${NC}"
echo ""
echo "Summary:"
echo "  - $COMPLETED_COUNT completed tasks ($COMPLETION_PCT%)"
echo "  - $ACTIVE_COUNT active tasks ($PENDING_COUNT pending, $BLOCKED_COUNT blocked)"
echo "  - $TOTAL_TASKS total tasks"
echo ""
echo -e "${BLUE}Tip:${NC} Run this script after completing tasks or agents finish to keep stats in sync."
