#!/bin/bash

INPUT_DIR="_sequences"
OUTPUT_DIR="_spritesheets"
WIDTH=16
HEIGHT=12
MATTE_COLOR="0x1e1e1eff"

mkdir -p "$OUTPUT_DIR"

# Group files by prefix (everything before the frame number)
cd "$INPUT_DIR" || exit

# Find all unique prefixes
for prefix in $(ls *.png | sed -E 's/[0-9]+\.png$//' | sort | uniq); do
  echo "Processing sequence: $prefix"

  # Count matching frames
  NUM_FRAMES=$(ls ${prefix}*.png | wc -l)
  SPRITE_WIDTH=$((WIDTH * NUM_FRAMES))

  # Output filename
  CLEAN_PREFIX=$(echo "$prefix" | sed 's/[^a-zA-Z0-9_-]//g') # sanitize
  OUTPUT_PATH="../$OUTPUT_DIR/${CLEAN_PREFIX}.webp"

  # Run FFmpeg
  ffmpeg -framerate 10 -pattern_type glob -i "${prefix}*.png" \
    -filter_complex "[0:v]format=rgba,colorchannelmixer=aa=0.5[fg];\
                     color=${MATTE_COLOR}:s=${SPRITE_WIDTH}x${HEIGHT}[bg];\
                     [bg][fg]overlay=format=rgb,tile=${NUM_FRAMES}x1" \
    -lossless 1 -compression_level 6 -frames:v 1 "$OUTPUT_PATH"
done