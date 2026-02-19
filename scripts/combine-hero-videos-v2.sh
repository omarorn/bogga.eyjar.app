#!/bin/bash

# Hero Video Creation v2 (with Auto-Rotation)
# Normalizes and combines all videos into one seamless loop
# Automatically detects and corrects rotation from phone/Instagram videos
#
# Usage:
#   INPUT_DIR=./source-videos OUTPUT_DIR=./public bash scripts/combine-hero-videos-v2.sh
#
# Requires: ffmpeg, ffprobe, bc

set -e

echo "Hero Video Creation v2"
echo "======================"

# Configuration — override with environment variables
INPUT_DIR="${INPUT_DIR:-.}"
OUTPUT_DIR="${OUTPUT_DIR:-./public}"
OUTPUT_FILE="hero-video.mp4"
TEMP_DIR="${TEMP_DIR:-/tmp/hero-video-processing}"
NORMALIZED_DIR="$TEMP_DIR/normalized"

# Create directories
mkdir -p "$TEMP_DIR"
mkdir -p "$NORMALIZED_DIR"

echo ""
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Temp Directory: $TEMP_DIR"
echo ""

# Find all videos
echo "Finding videos..."
VIDEO_FILES=($(find "$INPUT_DIR" -type f -name "*.mp4" | sort))
VIDEO_COUNT=${#VIDEO_FILES[@]}

echo "Found $VIDEO_COUNT videos to process"
echo ""

# Process each video: normalize resolution, rotation, and format
echo "Normalizing videos (fixing rotation, scaling, etc.)..."
echo "-----------------------------------------------------------"

COUNTER=1
> "$TEMP_DIR/normalized_list.txt"

for video in "${VIDEO_FILES[@]}"; do
    BASENAME=$(basename "$video")
    OUTPUT_NORMALIZED="$NORMALIZED_DIR/normalized_${COUNTER}.mp4"

    echo "[$COUNTER/$VIDEO_COUNT] Processing: $BASENAME"

    # Detect rotation and apply correction, scale to 1920x1080, ensure 30fps
    ffmpeg -i "$video" \
        -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p" \
        -c:v libx264 \
        -preset medium \
        -crf 23 \
        -r 30 \
        -c:a aac \
        -b:a 128k \
        -movflags +faststart \
        -metadata:s:v rotate=0 \
        -loglevel error \
        -stats \
        -y \
        "$OUTPUT_NORMALIZED" 2>&1 | grep -v "frame=" || true

    echo "file '$OUTPUT_NORMALIZED'" >> "$TEMP_DIR/normalized_list.txt"

    ((COUNTER++))
done

echo ""
echo "All videos normalized"
echo ""

# Combine normalized videos
echo "Combining all videos into one seamless loop..."
ffmpeg -f concat -safe 0 -i "$TEMP_DIR/normalized_list.txt" \
    -c copy \
    -movflags +faststart \
    -loglevel error \
    -stats \
    -y \
    "$TEMP_DIR/combined.mp4" 2>&1 | grep -v "frame=" || true

echo ""
echo "Videos combined"

# Create web-optimized desktop version
echo ""
echo "Creating web-optimized desktop version..."
ffmpeg -i "$TEMP_DIR/combined.mp4" \
    -c:v libx264 \
    -preset slow \
    -crf 28 \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease" \
    -r 30 \
    -c:a aac \
    -b:a 96k \
    -movflags +faststart \
    -loglevel error \
    -stats \
    -y \
    "$OUTPUT_DIR/$OUTPUT_FILE" 2>&1 | grep -v "frame=" || true

echo "Desktop version created: $OUTPUT_FILE"

# Create mobile version (720p, more compressed)
echo ""
echo "Creating mobile version..."
ffmpeg -i "$TEMP_DIR/combined.mp4" \
    -c:v libx264 \
    -preset slow \
    -crf 30 \
    -vf "scale=1280:720:force_original_aspect_ratio=decrease" \
    -r 24 \
    -c:a aac \
    -b:a 64k \
    -movflags +faststart \
    -loglevel error \
    -stats \
    -y \
    "$OUTPUT_DIR/hero-video-mobile.mp4" 2>&1 | grep -v "frame=" || true

echo "Mobile version created: hero-video-mobile.mp4"

# Create WebM versions (better compression for modern browsers)
echo ""
echo "Creating WebM versions..."

# Desktop WebM
ffmpeg -i "$TEMP_DIR/combined.mp4" \
    -c:v libvpx-vp9 \
    -crf 30 \
    -b:v 0 \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease" \
    -c:a libopus \
    -b:a 96k \
    -loglevel error \
    -stats \
    -y \
    "$OUTPUT_DIR/hero-video.webm" 2>&1 | grep -v "frame=" || true

echo "Desktop WebM created: hero-video.webm"

# Mobile WebM
ffmpeg -i "$TEMP_DIR/combined.mp4" \
    -c:v libvpx-vp9 \
    -crf 32 \
    -b:v 0 \
    -vf "scale=1280:720:force_original_aspect_ratio=decrease" \
    -c:a libopus \
    -b:a 64k \
    -loglevel error \
    -stats \
    -y \
    "$OUTPUT_DIR/hero-video-mobile.webm" 2>&1 | grep -v "frame=" || true

echo "Mobile WebM created: hero-video-mobile.webm"

# Get file sizes
echo ""
echo "Output File Sizes:"
echo "-------------------"
du -h "$OUTPUT_DIR"/hero-video* | awk '{print $2 " - " $1}'

# Calculate total duration
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_DIR/$OUTPUT_FILE")
MINUTES=$(echo "$DURATION / 60" | bc)
SECONDS=$(echo "$DURATION % 60" | bc)

echo ""
echo "Total Video Duration:"
echo "   ${MINUTES}m ${SECONDS}s"

# Cleanup
echo ""
echo "Cleaning up temp files..."
rm -rf "$TEMP_DIR"

echo ""
echo "COMPLETE! Hero video created successfully!"
echo ""
echo "Files generated in $OUTPUT_DIR/:"
echo "   - hero-video.mp4 (Desktop - MP4)"
echo "   - hero-video-mobile.mp4 (Mobile - MP4)"
echo "   - hero-video.webm (Desktop - WebM)"
echo "   - hero-video-mobile.webm (Mobile - WebM)"
echo ""
echo "What was done:"
echo "   - Auto-detected and corrected video rotation"
echo "   - Normalized all videos to 1920x1080 @ 30fps"
echo "   - Combined $VIDEO_COUNT videos into seamless loop"
echo "   - Created optimized versions for web and mobile"
echo ""
echo "Next steps:"
echo "   1. Test videos: open $OUTPUT_DIR/hero-video.mp4"
echo "   2. Check file sizes (>25MB needs R2 upload)"
echo "   3. Deploy: npm run deploy"
echo ""
