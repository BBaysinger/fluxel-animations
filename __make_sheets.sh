#!/bin/bash

INPUT_DIR="${1:-_input}"
OUTPUT_DIR="${2:-_output}"
MAX_WIDTH=4096   # Max sprite sheet width (pixels)
FPS=10

# Checks
if ! command -v ffmpeg &> /dev/null; then
  echo " ❌ ERROR: 'ffmpeg' not installed."
  exit 1
fi

if ! command -v magick &> /dev/null; then
  echo " ❌ ERROR: 'magick' (ImageMagick) not installed."
  exit 1
fi

echo " ⚠️  Clearing output directory: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"/*
mkdir -p "$OUTPUT_DIR"
cd "$INPUT_DIR" || exit 1

for prefix in $(ls *[0-9].png 2>/dev/null | sed -E 's/[0-9]+\.png$//' | sort | uniq); do
  echo "Processing sequence: $prefix"

  NUM_FRAMES=$(ls ${prefix}*.png | wc -l | tr -d '[:space:]')
  CLEAN_PREFIX=$(echo "$prefix" | sed 's/[^a-zA-Z0-9_-]//g')

  # Detect dimensions from first frame
  FIRST_FRAME=$(ls ${prefix}*.png | head -n 1)
  if [ ! -f "$FIRST_FRAME" ]; then
    echo " ❌ ERROR: No frame found for $prefix"
    continue
  fi

  DIMENSIONS=$(magick identify -format "%w %h" "$FIRST_FRAME")
  WIDTH=$(echo "$DIMENSIONS" | cut -d' ' -f1)
  HEIGHT=$(echo "$DIMENSIONS" | cut -d' ' -f2)

  echo " → Frame size: ${WIDTH}x${HEIGHT}"

  MAX_COLUMNS=$((MAX_WIDTH / WIDTH))
  if [ "$NUM_FRAMES" -le "$MAX_COLUMNS" ]; then
    TILE_COLUMNS=$NUM_FRAMES
    TILE_ROWS=1
  else
    TILE_COLUMNS=$MAX_COLUMNS
    TILE_ROWS=$(( (NUM_FRAMES + MAX_COLUMNS - 1) / MAX_COLUMNS ))
  fi

  SPRITE_WIDTH=$((TILE_COLUMNS * WIDTH))
  SPRITE_HEIGHT=$((TILE_ROWS * HEIGHT))

  echo " → Layout: ${TILE_COLUMNS}x${TILE_ROWS} (${SPRITE_WIDTH}x${SPRITE_HEIGHT})"

  if [ "$SPRITE_WIDTH" -gt 16383 ] || [ "$SPRITE_HEIGHT" -gt 16383 ]; then
    echo " ❌ ERROR: Skipping $prefix — exceeds WebP max size"
    continue
  fi

  OUTPUT_NAME="${CLEAN_PREFIX}_w${WIDTH}h${HEIGHT}f${NUM_FRAMES}.png"
  OUTPUT_PATH="../$OUTPUT_DIR/$OUTPUT_NAME"

  # Generate sprite sheet directly as PNG with unaltered RGBA
  ffmpeg -y -framerate "$FPS" -pattern_type glob -i "${prefix}*.png" \
    -filter_complex "[0:v] tile=${TILE_COLUMNS}x${TILE_ROWS}" \
    -frames:v 1 -pix_fmt rgba "$OUTPUT_PATH"
done
