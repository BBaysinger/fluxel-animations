#!/bin/bash

INPUT_DIR="_sequences"
OUTPUT_DIR="_spritesheets"
WIDTH=16
HEIGHT=12
MAX_WIDTH=4096   # Max sprite sheet width (pixels)
MATTE_COLOR="0x1f1f1fff"
FPS=10
LOOP=1

mkdir -p "$OUTPUT_DIR"

cd "$INPUT_DIR" || exit

for prefix in $(ls *.png | sed -E 's/[0-9]+\.png$//' | sort | uniq); do
  echo "Processing sequence: $prefix"

  NUM_FRAMES=$(ls ${prefix}*.png | wc -l)
  CLEAN_PREFIX=$(echo "$prefix" | sed 's/[^a-zA-Z0-9_-]//g')

  # Calculate ideal columns per row based on width limit
  MAX_COLUMNS=$((MAX_WIDTH / WIDTH))
  if [ "$NUM_FRAMES" -le "$MAX_COLUMNS" ]; then
    TILE_COLUMNS=$NUM_FRAMES
    TILE_ROWS=1
  else
    TILE_COLUMNS=$MAX_COLUMNS
    TILE_ROWS=$(( (NUM_FRAMES + MAX_COLUMNS - 1) / MAX_COLUMNS ))  # ceiling division
  fi

  SPRITE_WIDTH=$((TILE_COLUMNS * WIDTH))
  SPRITE_HEIGHT=$((TILE_ROWS * HEIGHT))

  echo " → Layout: ${TILE_COLUMNS}x${TILE_ROWS} (${SPRITE_WIDTH}x${SPRITE_HEIGHT})"

  # Construct metadata-rich filename
  OUTPUT_NAME="${CLEAN_PREFIX}_w${WIDTH}h${HEIGHT}f${NUM_FRAMES}r${FPS}l${LOOP}.webp"
  OUTPUT_PATH="../$OUTPUT_DIR/$OUTPUT_NAME"

  # Build sprite sheet
  ffmpeg -framerate "$FPS" -pattern_type glob -i "${prefix}*.png" \
    -filter_complex "[0:v]format=rgba,colorchannelmixer=aa=0.4[fg];\
                     color=${MATTE_COLOR}:s=${SPRITE_WIDTH}x${SPRITE_HEIGHT}[bg];\
                     [bg][fg]overlay=format=rgb,tile=${TILE_COLUMNS}x${TILE_ROWS}" \
    -lossless 1 -compression_level 6 -frames:v 1 "$OUTPUT_PATH"
done