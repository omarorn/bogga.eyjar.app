#!/bin/bash
# Agent Results Collection Helper
# Automates the 7-step workflow for collecting results from parallel agents

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Agent Results Collection Helper ===${NC}\n"

# Step 1: List completed agents
echo -e "${YELLOW}Step 1: Listing completed agents...${NC}"
echo "Run: /tasks"
echo "Look for: Task [id] (type: local_agent) (status: completed)"
echo ""
read -p "Enter agent IDs (space-separated, e.g., a123456 a789012): " AGENT_IDS

if [ -z "$AGENT_IDS" ]; then
    echo -e "${RED}No agent IDs provided. Exiting.${NC}"
    exit 1
fi

# Convert to array
IFS=' ' read -ra AGENTS <<< "$AGENT_IDS"
AGENT_COUNT=${#AGENTS[@]}

echo -e "${GREEN}Found ${AGENT_COUNT} agents to collect${NC}\n"

# Step 2: Retrieve outputs
echo -e "${YELLOW}Step 2: Retrieving agent outputs...${NC}"
echo "Use in Claude Code:"
echo ""
for agent_id in "${AGENTS[@]}"; do
    echo "TaskOutput(\"$agent_id\", block=true, timeout=240000)"
done
echo ""
echo -e "${BLUE}Tip: Use extended timeout (240s) for comprehensive deliverables${NC}"
echo ""

# Step 3: Verification checklist
echo -e "${YELLOW}Step 3: Verify deliverables for each agent${NC}"
echo ""
echo "For each agent, check:"
echo "  [ ] Files exist (ls -la expected/files)"
echo "  [ ] Implementation depth (wc -l files, check for stubs)"
echo "  [ ] Scripts work (bash script.sh --dry-run)"
echo "  [ ] Metrics have evidence (not just claims)"
echo "  [ ] No TODO/FIXME/placeholder content"
echo ""
read -p "Press Enter when verification is complete..."

# Step 4: Collect task information
echo ""
echo -e "${YELLOW}Step 4: Collect task information${NC}"
echo "Which tasks were completed by these agents?"
echo "Example: TASK-110A TASK-123 TASK-135D TASK-135E TASK-143 TASK-151"
echo ""
read -p "Enter completed task IDs (space-separated): " COMPLETED_TASKS

if [ -z "$COMPLETED_TASKS" ]; then
    echo -e "${RED}No task IDs provided. Skipping task updates.${NC}"
else
    IFS=' ' read -ra TASKS <<< "$COMPLETED_TASKS"
    TASK_COUNT=${#TASKS[@]}
    echo -e "${GREEN}Will mark ${TASK_COUNT} tasks as complete${NC}"
fi

# Step 5: Documentation updates
echo ""
echo -e "${YELLOW}Step 5: Update documentation files${NC}"
echo ""
echo "Update order (important!):"
echo "  1. tasks.md (mark tasks complete, update statistics)"
echo "  2. TODO.md (mirror statistics, add session summary)"
echo "  3. completedtasks.md (append completed tasks with details)"
echo ""
echo "Use: Read → Edit → TodoWrite pattern"
echo ""

# Step 6: Statistics calculation helper
if [ ! -z "$COMPLETED_TASKS" ]; then
    echo -e "${YELLOW}Step 6: Calculate new statistics${NC}"
    echo ""
    read -p "Current 'Lokið' (completed) count: " CURRENT_COMPLETED
    read -p "Current 'Eftirstöðvar' (remaining) count: " CURRENT_REMAINING

    NEW_COMPLETED=$((CURRENT_COMPLETED + TASK_COUNT))
    NEW_REMAINING=$((CURRENT_REMAINING - TASK_COUNT))
    TOTAL=$((NEW_COMPLETED + NEW_REMAINING))
    NEW_PROGRESS=$(echo "scale=0; ($NEW_COMPLETED * 100) / $TOTAL" | bc)

    echo ""
    echo -e "${GREEN}New Statistics:${NC}"
    echo "  Lokið (Completed): $CURRENT_COMPLETED → $NEW_COMPLETED (+$TASK_COUNT)"
    echo "  Eftirstöðvar (Remaining): $CURRENT_REMAINING → $NEW_REMAINING (-$TASK_COUNT)"
    echo "  Framvinda (Progress): ${NEW_PROGRESS}%"
    echo ""
    echo "Use these values in tasks.md and TODO.md updates"
    echo ""
fi

# Step 7: Final checklist
echo -e "${YELLOW}Step 7: Final TodoWrite update${NC}"
echo ""
echo "After updating all documentation:"
echo ""
echo "TodoWrite(["
echo "  {content: \"...\", status: \"completed\", activeForm: \"...\"},"
echo "  ..."
echo "])"
echo ""

# Summary
echo ""
echo -e "${GREEN}=== Collection Summary ===${NC}"
echo "Agents collected: ${AGENT_COUNT}"
if [ ! -z "$COMPLETED_TASKS" ]; then
    echo "Tasks marked complete: ${TASK_COUNT}"
    echo "New progress: ${NEW_PROGRESS}%"
fi
echo ""
echo -e "${BLUE}Next: Update TODO.md with session summary${NC}"
echo ""

# Deliverables template
echo -e "${YELLOW}Optional: Deliverables Summary Template${NC}"
echo ""
echo "### Agent Results Collection Session #N"
echo ""
echo "**Date:** $(date +%Y-%m-%d)"
echo "**Agents Collected:** ${AGENT_COUNT}"
if [ ! -z "$COMPLETED_TASKS" ]; then
    echo "**Tasks Completed:** ${TASK_COUNT}"
fi
echo "**Method:** Parallel delegation + systematic verification"
echo ""
echo "**Agent Results:**"
for agent_id in "${AGENTS[@]}"; do
    echo "- Agent $agent_id: [Task description] ([Token count])"
done
echo ""
echo "**Deliverables:**"
echo "- [Count] files created"
echo "- [Count] lines of documentation"
echo "- [Count] automation scripts"
echo "- [Metrics/results summary]"
echo ""
echo "**Time Savings:** [Estimated] hours → [Actual] hours ([X]% reduction)"
echo ""

echo -e "${GREEN}Done! All steps completed.${NC}"
