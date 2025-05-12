#!/bin/bash

INPUT_DIR="_sequences"
OUTPUT_DIR="_spritesheets"
WIDTH=16
HEIGHT=12
MAX_WIDTH=4096   # Max sprite sheet width (pixels)
MATTE_COLOR="0x1f1f1fff"
FPS=10
LOOP=1

# 🧪 Check for ImageMagick's mogrify command
if ! command -v mogrify &> /dev/null; then
  echo " ❌ ERROR: 'mogrify' (from ImageMagick) is not installed or not in PATH."
  echo "     → Install with: brew install imagemagick"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

cd "$INPUT_DIR" || exit

for prefix in $(ls *.png | sed -E 's/[0-9]+\.png$//' | sort | uniq); do
  echo "Processing sequence: $prefix"

  NUM_FRAMES=$(ls ${prefix}*.png | wc -l | tr -d '[:space:]')
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

  # Skip if result exceeds WebP hard limits
  if [ "$SPRITE_WIDTH" -gt 16383 ] || [ "$SPRITE_HEIGHT" -gt 16383 ]; then
    echo " ❌ ERROR: Skipping $prefix — output image would exceed WebP limit (16383x16383)"
    continue
  fi

  # Construct metadata-rich filename
  OUTPUT_NAME="${CLEAN_PREFIX}_w${WIDTH}h${HEIGHT}f${NUM_FRAMES}r${FPS}l${LOOP}.webp"
  OUTPUT_PATH="../$OUTPUT_DIR/$OUTPUT_NAME"

  # 🔍 Detect and fix paletted PNGs if needed
  NEEDS_CONVERSION=false
  for img in ${prefix}*.png; do
    if ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$img" | grep -q '^pal8'; then
      NEEDS_CONVERSION=true
      break
    fi
  done

  if [ "$NEEDS_CONVERSION" = true ]; then
    echo " 🛠  Detected paletted PNGs — converting to RGBA..."
    mogrify -format png -define png:color-type=6 ${prefix}*.png
  fi

  # ✅ Build sprite sheet with matte compositing and correct alpha
  ffmpeg -framerate "$FPS" -pattern_type glob -i "${prefix}*.png" \
    -filter_complex "\
  [0:v] split=2 [raw][alpha_src]; \
  [raw] tile=${TILE_COLUMNS}x${TILE_ROWS},format=rgba [fg]; \
  color=${MATTE_COLOR}:s=${SPRITE_WIDTH}x${SPRITE_HEIGHT},format=rgba [bg]; \
  [bg][fg] overlay=format=auto [rgbmatte]; \
  [alpha_src] tile=${TILE_COLUMNS}x${TILE_ROWS},alphaextract,format=gray [a]; \
  [rgbmatte][a] alphamerge \
  " \
    -lossless 1 -compression_level 6 -frames:v 1 "$OUTPUT_PATH"
done
