#!/usr/bin/env bash
#
# Uptime Monitoring Setup Script
#
# Automatically creates UptimeRobot monitors for all Litla Gámaleigan production URLs.
# Requires UptimeRobot API key (get from: https://uptimerobot.com/dashboard#mySettings)
#
# Usage:
#   export UPTIMEROBOT_API_KEY="your-api-key-here"
#   bash scripts/setup-uptime-monitoring.sh
#
# Or:
#   UPTIMEROBOT_API_KEY="your-key" bash scripts/setup-uptime-monitoring.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# UptimeRobot API endpoint
API_URL="https://api.uptimerobot.com/v2"

# Check for API key
if [ -z "${UPTIMEROBOT_API_KEY:-}" ]; then
  echo -e "${RED}ERROR: UPTIMEROBOT_API_KEY environment variable not set${NC}"
  echo ""
  echo "To get your API key:"
  echo "1. Log in to https://uptimerobot.com"
  echo "2. Go to Settings → API Settings"
  echo "3. Create a Main API Key"
  echo "4. Export it: export UPTIMEROBOT_API_KEY='your-key-here'"
  echo ""
  exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Litla Gámaleigan - Uptime Monitoring Setup                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Monitors to create
declare -a MONITORS=(
  # Format: "FRIENDLY_NAME|URL|CHECK_INTERVAL_SECONDS|TYPE"
  "Litla Landing Page|https://litla.gamaleigan.is|300|http"
  "Admin Dashboard|https://admin.gamaleigan.is|300|http"
  "Driver App|https://okumenn.gamaleigan.is|300|http"
  "Backend API|https://api.gamaleigan.is/health|180|http"
  "WebSocket|wss://ws.gamaleigan.is|600|port"
)

# Alert contacts (email/SMS)
# Modify these with your actual contact methods
ALERT_EMAIL="${ALERT_EMAIL:-omar@vertis.is}"

echo -e "${YELLOW}Monitors to be created:${NC}"
for monitor in "${MONITORS[@]}"; do
  IFS='|' read -r name url interval type <<< "$monitor"
  echo -e "  • ${GREEN}$name${NC} - $url (every $interval seconds)"
done
echo ""

# Function to create monitor
create_monitor() {
  local friendly_name="$1"
  local url="$2"
  local interval="$3"
  local type="$4"

  echo -e "${BLUE}Creating monitor:${NC} $friendly_name"

  # Determine monitor type code
  local type_code
  case "$type" in
    http)   type_code=1 ;;
    keyword) type_code=2 ;;
    ping)   type_code=3 ;;
    port)   type_code=4 ;;
    *)      type_code=1 ;;
  esac

  # Create monitor via API
  response=$(curl -s -X POST "$API_URL/newMonitor" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "api_key=$UPTIMEROBOT_API_KEY" \
    -d "format=json" \
    -d "type=$type_code" \
    -d "url=$url" \
    -d "friendly_name=$friendly_name" \
    -d "interval=$interval")

  # Check response
  status=$(echo "$response" | grep -o '"stat":"[^"]*"' | cut -d'"' -f4)

  if [ "$status" = "ok" ]; then
    monitor_id=$(echo "$response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo -e "  ${GREEN}✓${NC} Monitor created (ID: $monitor_id)"
  else
    error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    echo -e "  ${RED}✗${NC} Failed: $error_msg"
  fi

  echo ""
}

# Function to list existing monitors
list_monitors() {
  echo -e "${BLUE}Fetching existing monitors...${NC}"

  response=$(curl -s -X POST "$API_URL/getMonitors" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "api_key=$UPTIMEROBOT_API_KEY" \
    -d "format=json")

  status=$(echo "$response" | grep -o '"stat":"[^"]*"' | cut -d'"' -f4)

  if [ "$status" = "ok" ]; then
    monitor_count=$(echo "$response" | grep -o '"limit":[0-9]*' | cut -d':' -f2 | head -1)
    echo -e "${GREEN}Found $monitor_count existing monitors${NC}"
    echo ""
  else
    echo -e "${YELLOW}Could not fetch monitors (API key may not have read permissions)${NC}"
    echo ""
  fi
}

# Function to create alert contact
create_alert_contact() {
  local email="$1"

  echo -e "${BLUE}Creating alert contact:${NC} $email"

  response=$(curl -s -X POST "$API_URL/newAlertContact" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "api_key=$UPTIMEROBOT_API_KEY" \
    -d "format=json" \
    -d "type=2" \
    -d "value=$email" \
    -d "friendly_name=Email Alerts")

  status=$(echo "$response" | grep -o '"stat":"[^"]*"' | cut -d'"' -f4)

  if [ "$status" = "ok" ]; then
    contact_id=$(echo "$response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo -e "  ${GREEN}✓${NC} Alert contact created (ID: $contact_id)"
  else
    error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    echo -e "  ${YELLOW}!${NC} Note: $error_msg (may already exist)"
  fi

  echo ""
}

# Main execution
echo -e "${YELLOW}Step 1: List existing monitors${NC}"
list_monitors

echo -e "${YELLOW}Step 2: Create alert contact${NC}"
create_alert_contact "$ALERT_EMAIL"

echo -e "${YELLOW}Step 3: Create monitors${NC}"
for monitor in "${MONITORS[@]}"; do
  IFS='|' read -r name url interval type <<< "$monitor"
  create_monitor "$name" "$url" "$interval" "$type"
  sleep 1 # Rate limiting
done

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Setup Complete!                                             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Log in to https://uptimerobot.com/dashboard"
echo "2. Verify monitors are active"
echo "3. Configure alert thresholds (Settings → Alert Contacts)"
echo "4. Set up status page (optional): https://uptimerobot.com/statusPages"
echo ""
echo -e "${YELLOW}Recommended Alert Settings:${NC}"
echo "• Alert when down for: 2 minutes"
echo "• Re-alert every: 30 minutes"
echo "• Send alerts via: Email + SMS (configure in dashboard)"
echo ""
echo -e "${GREEN}Monitoring is now active!${NC}"
