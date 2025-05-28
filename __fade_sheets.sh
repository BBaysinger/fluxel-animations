#!/bin/bash

INPUT_DIR="grid_sheets1_raw"
OUTPUT_DIR="grid_sheets2_faded"
OPACITY_PERCENT=15

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
  echo " ❌ ERROR: 'magick' (ImageMagick) not installed."
  exit 1
fi

echo " ⚠️  Clearing output directory: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"/*

for input_path in "$INPUT_DIR"/*.png; do
  [ -e "$input_path" ] || continue  # Skip if no matching files

  filename=$(basename "$input_path")
  output_path="$OUTPUT_DIR/${filename%.png}.png"

  echo "Fading $filename to ${OPACITY_PERCENT}% opacity..."

magick "$input_path" -strip -alpha on -channel A \
  -evaluate multiply $(echo "$OPACITY_PERCENT / 100" | bc -l) +channel \
  "$output_path"
done