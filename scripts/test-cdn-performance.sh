#!/bin/bash

##
# CDN Performance Testing Script
#
# This script tests CDN performance by measuring load times
# for assets from both local server and CDN.
#
# Usage:
#   bash scripts/test-cdn-performance.sh
#
# Requirements:
#   - curl (for HTTP requests)
#   - bc (for calculations)
##

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CDN_URL="https://images.gamaleigan.is"
LOCAL_URL="https://litla.gamaleigan.is"
ITERATIONS=5

# Test assets
declare -a TEST_ASSETS=(
  "images/branding/logo.png"
  "images/branding/litla2.png"
  "videos/hero/desktop/hero-video-compressed.mp4"
  "videos/hero/mobile/hero-video-mobile.mp4"
  "images/containers/halfur-opin.jpg"
)

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  CDN Performance Testing - Litla Gámaleigan${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "📊 Configuration:"
echo -e "   CDN URL: ${GREEN}${CDN_URL}${NC}"
echo -e "   Local URL: ${YELLOW}${LOCAL_URL}${NC}"
echo -e "   Iterations: ${ITERATIONS} per asset"
echo -e "   Test Assets: ${#TEST_ASSETS[@]}\n"

# Function to test single asset
test_asset() {
  local url=$1
  local asset=$2
  local full_url="${url}/${asset}"

  # Use curl to measure time
  local time_total=$(curl -o /dev/null -s -w '%{time_total}' "$full_url")

  echo "$time_total"
}

# Function to calculate average
calculate_average() {
  local sum=0
  local count=$#

  for time in "$@"; do
    sum=$(echo "$sum + $time" | bc)
  done

  echo "scale=3; $sum / $count" | bc
}

# Function to get cache status
get_cache_status() {
  local url=$1
  local asset=$2
  local full_url="${url}/${asset}"

  # Get CF-Cache-Status header
  local cache_status=$(curl -s -I "$full_url" | grep -i "cf-cache-status" | awk '{print $2}' | tr -d '\r')

  if [ -z "$cache_status" ]; then
    echo "UNKNOWN"
  else
    echo "$cache_status"
  fi
}

# Test each asset
echo -e "${BLUE}─────────────────────────────────────────────────────────${NC}\n"

for asset in "${TEST_ASSETS[@]}"; do
  echo -e "${YELLOW}Testing: ${asset}${NC}"

  # Get asset size
  asset_size=$(curl -sI "${CDN_URL}/${asset}" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
  if [ -n "$asset_size" ]; then
    asset_size_mb=$(echo "scale=2; $asset_size / 1024 / 1024" | bc)
    echo -e "   Size: ${asset_size_mb} MB"
  fi

  # Test CDN
  echo -ne "   CDN: "
  cdn_times=()
  for i in $(seq 1 $ITERATIONS); do
    echo -n "."
    cdn_times+=( $(test_asset "$CDN_URL" "$asset") )
  done
  cdn_avg=$(calculate_average "${cdn_times[@]}")
  cdn_cache=$(get_cache_status "$CDN_URL" "$asset")
  echo -e " ${GREEN}${cdn_avg}s${NC} (avg) - Cache: ${cdn_cache}"

  # Test Local (if accessible)
  echo -ne "   Local: "
  local_times=()
  for i in $(seq 1 $ITERATIONS); do
    echo -n "."
    local_time=$(test_asset "$LOCAL_URL" "$asset" 2>/dev/null || echo "0")
    if [ "$local_time" != "0" ]; then
      local_times+=( "$local_time" )
    fi
  done

  if [ ${#local_times[@]} -eq 0 ]; then
    echo -e " ${YELLOW}N/A${NC} (not accessible)"
  else
    local_avg=$(calculate_average "${local_times[@]}")
    echo -e " ${YELLOW}${local_avg}s${NC} (avg)"

    # Calculate improvement
    improvement=$(echo "scale=1; (($local_avg - $cdn_avg) / $local_avg) * 100" | bc)
    if (( $(echo "$improvement > 0" | bc -l) )); then
      echo -e "   ${GREEN}Improvement: ${improvement}% faster via CDN${NC}"
    elif (( $(echo "$improvement < 0" | bc -l) )); then
      abs_improvement=$(echo "${improvement#-}" | bc)
      echo -e "   ${RED}Degradation: ${abs_improvement}% slower via CDN${NC}"
    else
      echo -e "   Equal performance"
    fi
  fi

  echo ""
done

echo -e "${BLUE}─────────────────────────────────────────────────────────${NC}\n"

# Summary
echo -e "${GREEN}✅ Performance testing complete!${NC}\n"

echo -e "📋 Analysis Notes:"
echo -e "   • First request: May show MISS (not cached yet)"
echo -e "   • Subsequent requests: Should show HIT (served from edge)"
echo -e "   • Edge cache: Typically 30-100ms response time"
echo -e "   • Origin: Typically 200-500ms response time"
echo -e "   • Target improvement: 40-70% faster via CDN\n"

echo -e "🔍 Next Steps:"
echo -e "   1. If cache status shows MISS: Wait 30s and retest"
echo -e "   2. If CDN slower than local: Check Cloudflare cache rules"
echo -e "   3. If HIT but slow: May be far from edge location"
echo -e "   4. Run from different locations for full picture\n"

# Cleanup
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
