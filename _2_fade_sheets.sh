#!/bin/bash

INPUT_DIR="_spritesheets1_raw"
OUTPUT_DIR="_spritesheets2_faded"
OPACITY_PERCENT=30

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
  echo " ❌ ERROR: 'magick' (ImageMagick) not installed."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

for input_path in "$INPUT_DIR"/*.webp; do
  [ -e "$input_path" ] || continue  # Skip if no matching files

  filename=$(basename "$input_path")
  output_path="$OUTPUT_DIR/$filename"

  echo "Fading $filename to ${OPACITY_PERCENT}% opacity..."

  magick "$input_path" -alpha on -channel A -evaluate multiply $(echo "$OPACITY_PERCENT / 100" | bc -l) +channel "$output_path"
done