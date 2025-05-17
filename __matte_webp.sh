#!/bin/bash

INPUT_DIR="${1:-_input}"
OUTPUT_DIR="${2:-_output}"
MATTE="#1f1f1f"

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

  echo "Applying matte to $FILENAME..."

  TMP_ALPHA="_tmp_alpha.png"
  TMP_MASK="_tmp_mask.png"
  TMP_FLATTENED="_tmp_flattened.png"
  TMP_COLORED="_tmp_colored.png"

  # 1. Extract alpha channel
  magick "$INPUT" -alpha extract "$TMP_ALPHA"

  # 2. Create a mask for semi-transparent pixels
  magick "$TMP_ALPHA" -threshold 1% "$TMP_MASK"

  # 3. Flatten against matte color
  magick "$INPUT" -background "$MATTE" -alpha remove -alpha off "$TMP_FLATTENED"

  # 4. Apply mask to restore transparency (matte coloring only on semi-transp)
  magick "$TMP_FLATTENED" "$TMP_MASK" -alpha off -compose CopyOpacity -composite "$TMP_COLORED"

  # 5. Overlay matted semi-transp pixels over original and export as WebP
  magick "$INPUT" "$TMP_COLORED" -compose Dst_Over -composite -define webp:lossless=true "$OUTPUT"

  # 6. Clean up
  rm -f "$TMP_ALPHA" "$TMP_MASK" "$TMP_FLATTENED" "$TMP_COLORED"
done

echo "✅ Matte compositing complete for all files in $INPUT_DIR."
