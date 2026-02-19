#!/bin/bash

# Upload Tutorial Videos to Cloudflare R2
# Usage: bash scripts/upload-tutorial-videos.sh

set -e

BUCKET_NAME="litla-gamaleigan-images"
R2_PATH="videos/tutorials/"
LOCAL_PATH="assets/video-tutorials/"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Upload Tutorial Videos to R2"
echo "=========================================="
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}Error: wrangler CLI not installed${NC}"
    echo "Install with: npm install -g wrangler"
    exit 1
fi

# Check if local directory exists
if [ ! -d "$LOCAL_PATH" ]; then
    echo -e "${YELLOW}Warning: Local directory not found: $LOCAL_PATH${NC}"
    echo "Creating directory..."
    mkdir -p "$LOCAL_PATH"
    echo ""
    echo "Please place your video files in: $LOCAL_PATH"
    echo ""
    echo "Expected files:"
    echo "  - admin-container-management.mp4"
    echo "  - admin-order-management.mp4"
    echo "  - driver-gps-navigation.mp4"
    echo "  - driver-completing-pickups.mp4"
    echo "  - customer-portal-guide.mp4"
    exit 1
fi

# List of videos to upload
VIDEOS=(
    "admin-container-management.mp4"
    "admin-order-management.mp4"
    "driver-gps-navigation.mp4"
    "driver-completing-pickups.mp4"
    "customer-portal-guide.mp4"
)

# Track upload statistics
TOTAL=${#VIDEOS[@]}
UPLOADED=0
SKIPPED=0
FAILED=0

echo "Bucket: $BUCKET_NAME"
echo "R2 Path: $R2_PATH"
echo "Local Path: $LOCAL_PATH"
echo ""
echo "Videos to upload: $TOTAL"
echo ""

# Upload each video
for video in "${VIDEOS[@]}"; do
    LOCAL_FILE="${LOCAL_PATH}${video}"
    R2_KEY="${R2_PATH}${video}"

    echo "----------------------------------------"
    echo "Video: $video"

    # Check if file exists locally
    if [ ! -f "$LOCAL_FILE" ]; then
        echo -e "${YELLOW}⊘ Skipped: File not found${NC}"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Get file size
    FILE_SIZE=$(du -h "$LOCAL_FILE" | cut -f1)
    echo "Size: $FILE_SIZE"

    # Upload to R2
    echo "Uploading to R2..."

    if wrangler r2 object put "${BUCKET_NAME}/${R2_KEY}" \
        --file="$LOCAL_FILE" \
        --content-type="video/mp4" 2>&1; then

        echo -e "${GREEN}✓ Uploaded successfully${NC}"
        UPLOADED=$((UPLOADED + 1))
    else
        echo -e "${RED}✗ Upload failed${NC}"
        FAILED=$((FAILED + 1))
    fi

    echo ""
done

# Upload thumbnails if they exist
echo "=========================================="
echo "  Uploading Thumbnails (if available)"
echo "=========================================="
echo ""

THUMBNAILS=(
    "admin-container-management-thumbnail.jpg"
    "admin-order-management-thumbnail.jpg"
    "driver-gps-navigation-thumbnail.jpg"
    "driver-completing-pickups-thumbnail.jpg"
    "customer-portal-guide-thumbnail.jpg"
)

for thumbnail in "${THUMBNAILS[@]}"; do
    LOCAL_FILE="${LOCAL_PATH}${thumbnail}"
    R2_KEY="${R2_PATH}${thumbnail}"

    if [ -f "$LOCAL_FILE" ]; then
        echo "Uploading thumbnail: $thumbnail"

        if wrangler r2 object put "${BUCKET_NAME}/${R2_KEY}" \
            --file="$LOCAL_FILE" \
            --content-type="image/jpeg" 2>&1; then

            echo -e "${GREEN}✓ Uploaded thumbnail${NC}"
        else
            echo -e "${YELLOW}⊘ Thumbnail upload failed${NC}"
        fi
        echo ""
    fi
done

# Summary
echo "=========================================="
echo "  Upload Summary"
echo "=========================================="
echo ""
echo "Total videos: $TOTAL"
echo -e "${GREEN}Uploaded: $UPLOADED${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

# Verify uploads
echo "=========================================="
echo "  Verifying Uploads"
echo "=========================================="
echo ""

echo "Listing files in R2 bucket..."
wrangler r2 object list "$BUCKET_NAME" --prefix="$R2_PATH" 2>&1 || true

echo ""
echo "=========================================="
echo "  Public URLs"
echo "=========================================="
echo ""

R2_PUBLIC_URL="https://pub-f803b94d3cea4783afd4aa1f0dde6e56.r2.dev"

for video in "${VIDEOS[@]}"; do
    echo "${R2_PUBLIC_URL}/${R2_PATH}${video}"
done

echo ""
echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""
echo "1. Test video URLs in browser"
echo "2. Update Help pages with video embeds"
echo "3. Generate thumbnails if not already created"
echo "4. Test video playback in all apps"
echo ""

if [ $UPLOADED -eq $TOTAL ]; then
    echo -e "${GREEN}✓ All videos uploaded successfully!${NC}"
    exit 0
elif [ $FAILED -gt 0 ]; then
    echo -e "${RED}⚠ Some uploads failed. Check errors above.${NC}"
    exit 1
else
    echo -e "${YELLOW}⊘ Some videos were skipped. Place videos in $LOCAL_PATH${NC}"
    exit 0
fi
