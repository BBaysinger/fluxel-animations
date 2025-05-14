#!/bin/bash

INPUT_DIR="_sequences"
OUTPUT_DIR="_spritesheets1_raw"
WIDTH=16
HEIGHT=12
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

mkdir -p "$OUTPUT_DIR"
cd "$INPUT_DIR" || exit

for prefix in $(ls *[0-9].png 2>/dev/null | sed -E 's/[0-9]+\.png$//' | sort | uniq); do
  echo "Processing sequence: $prefix"

  NUM_FRAMES=$(ls ${prefix}*.png | wc -l | tr -d '[:space:]')
  CLEAN_PREFIX=$(echo "$prefix" | sed 's/[^a-zA-Z0-9_-]//g')

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

  TMP_PNG="../tmp_${CLEAN_PREFIX}.png"
  OUTPUT_NAME="${CLEAN_PREFIX}_w${WIDTH}h${HEIGHT}f${NUM_FRAMES}.webp"
  OUTPUT_PATH="../$OUTPUT_DIR/$OUTPUT_NAME"

  # Step 1: Generate raw sprite sheet as PNG with unaltered RGBA
  ffmpeg -y -framerate "$FPS" -pattern_type glob -i "${prefix}*.png" \
    -filter_complex "[0:v] tile=${TILE_COLUMNS}x${TILE_ROWS}" \
    -frames:v 1 -pix_fmt rgba -update 1 "$TMP_PNG"

  # Step 2: Convert to WebP with full alpha preserved
  magick "$TMP_PNG" -define webp:lossless=true "$OUTPUT_PATH"

  # Clean up
  rm -f "$TMP_PNG"
done
