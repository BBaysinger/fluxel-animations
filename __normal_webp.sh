#!/bin/bash

INPUT_DIR="${1:-_input}"
OUTPUT_DIR="${2:-_output}"

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
  echo " ❌ ERROR: 'magick' (ImageMagick) not installed."
  exit 1
fi

echo " ⚠️  Clearing output directory: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"/*
mkdir -p "$OUTPUT_DIR"

for INPUT in "$INPUT_DIR"/*.png; do
  [ -e "$INPUT" ] || continue  # Skip if no files

  FILENAME=$(basename "$INPUT")
  BASENAME="${FILENAME%.*}"
  OUTPUT="$OUTPUT_DIR/${BASENAME}.webp"

  echo "Converting $FILENAME to WebP..."

  # Convert PNG to WebP, preserving alpha channel (lossless)
  magick "$INPUT" -define webp:lossless=true "$OUTPUT"
done

echo "✅ WebP conversion complete for all files in $INPUT_DIR."
