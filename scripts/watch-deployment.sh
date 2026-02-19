#!/bin/bash
# Watch for deployment changes and auto-run verification

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Watcher${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get current bundle hash
get_bundle_hash() {
    curl -s https://admin.gamaleigan.is | grep -o 'src="/assets/index-[^"]*\.js"' | head -1 | sed 's/.*index-\([^"]*\)\.js.*/\1/'
}

CURRENT_HASH=$(get_bundle_hash)
echo -e "${BLUE}Current bundle hash:${NC} $CURRENT_HASH"
echo -e "${YELLOW}Watching for changes... (Ctrl+C to stop)${NC}"
echo ""

CHECK_INTERVAL=30  # seconds
CHECKS=0

while true; do
    sleep $CHECK_INTERVAL
    ((CHECKS++))

    NEW_HASH=$(get_bundle_hash)

    if [ "$NEW_HASH" != "$CURRENT_HASH" ]; then
        echo ""
        echo -e "${GREEN}✓ New deployment detected!${NC}"
        echo -e "  Old: $CURRENT_HASH"
        echo -e "  New: $NEW_HASH"
        echo ""
        echo -e "${BLUE}Running verification tests...${NC}"
        echo ""

        # Run verification script
        bash scripts/verify-production-deployment.sh

        echo ""
        echo -e "${GREEN}✓ Verification complete${NC}"
        echo -e "${YELLOW}Continuing to watch for changes...${NC}"
        echo ""

        CURRENT_HASH=$NEW_HASH
        CHECKS=0
    else
        # Show progress indicator
        echo -ne "\rChecked ${CHECKS} times (last check: $(date +%H:%M:%S))   "
    fi
done
