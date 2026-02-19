#!/bin/bash

# Hero Video Creation Script (v1 - Simple)
# Combines all videos into one seamless loop for hero background
# Requires: ffmpeg
#
# Usage:
#   INPUT_DIR=./source-videos OUTPUT_DIR=./public bash scripts/combine-hero-videos.sh

set -e

echo "Hero Video Creation"
echo "==================="

# Configuration — override with environment variables
INPUT_DIR="${INPUT_DIR:-.}"
OUTPUT_DIR="${OUTPUT_DIR:-./public}"
OUTPUT_FILE="hero-video.mp4"
TEMP_DIR="${TEMP_DIR:-/tmp/hero-video-processing}"

# Create temp directory
mkdir -p "$TEMP_DIR"

echo ""
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Temp Directory: $TEMP_DIR"
echo ""

# List all video files
echo "Found videos:"
find "$INPUT_DIR" -type f -name "*.mp4" | sort

# Create file list for concatenation
echo ""
echo "Creating video list..."
find "$INPUT_DIR" -type f -name "*.mp4" | sort > "$TEMP_DIR/video_list.txt"

# Count videos
VIDEO_COUNT=$(cat "$TEMP_DIR/video_list.txt" | wc -l)
echo "Found $VIDEO_COUNT videos to combine"

echo ""
echo "Combining videos using FFmpeg..."

# Convert list to FFmpeg concat format
> "$TEMP_DIR/concat_list.txt"
while IFS= read -r video; do
    echo "file '$video'" >> "$TEMP_DIR/concat_list.txt"
done < "$TEMP_DIR/video_list.txt"

# Combine videos with re-encoding for consistency and auto-rotation
ffmpeg -f concat -safe 0 -i "$TEMP_DIR/concat_list.txt" \
    -c:v libx264 \
    -preset medium \
    -crf 23 \
    -vf "transpose=2,transpose=2,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" \
    -metadata:s:v rotate=0 \
    -r 30 \
    -c:a aac \
    -b:a 128k \
    -movflags +faststart \
    -y \
    "$TEMP_DIR/combined.mp4"

echo "Videos combined with auto-rotation applied"

# Create web-optimized version (compressed)
echo ""
echo "Creating web-optimized version..."
ffmpeg -i "$TEMP_DIR/combined.mp4" \
    -c:v libx264 \
    -preset slow \
    -crf 28 \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease" \
    -r 30 \
    -c:a aac \
    -b:a 96k \
    -movflags +faststart \
    -y \
    "$OUTPUT_DIR/$OUTPUT_FILE"

echo "Web-optimized version created"

# Create mobile version (smaller, faster)
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
    -y \
    "$OUTPUT_DIR/hero-video-mobile.mp4"

echo "Mobile version created"

# Create WebM versions for better web compatibility
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
    -y \
    "$OUTPUT_DIR/hero-video.webm"

# Mobile WebM
ffmpeg -i "$TEMP_DIR/combined.mp4" \
    -c:v libvpx-vp9 \
    -crf 32 \
    -b:v 0 \
    -vf "scale=1280:720:force_original_aspect_ratio=decrease" \
    -c:a libopus \
    -b:a 64k \
    -y \
    "$OUTPUT_DIR/hero-video-mobile.webm"

echo "WebM versions created"

# Get file sizes
echo ""
echo "Output File Sizes:"
echo "-------------------"
ls -lh "$OUTPUT_DIR/hero-video"* | awk '{print $9 " - " $5}'

# Cleanup
echo ""
echo "Cleaning up temp files..."
rm -rf "$TEMP_DIR"

echo ""
echo "COMPLETE! Hero video files created in:"
echo "   $OUTPUT_DIR/"
echo ""
echo "Files generated:"
echo "   - hero-video.mp4 (Desktop - MP4)"
echo "   - hero-video-mobile.mp4 (Mobile - MP4)"
echo "   - hero-video.webm (Desktop - WebM)"
echo "   - hero-video-mobile.webm (Mobile - WebM)"
echo ""
echo "Next steps:"
echo "   1. Review the videos in $OUTPUT_DIR/"
echo "   2. Test playback in browser"
echo "   3. Deploy with: npm run deploy"
echo ""
