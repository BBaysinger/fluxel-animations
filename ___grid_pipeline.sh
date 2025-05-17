#!/bin/bash
set -e

echo -e "\n\033[1;36m============================================"
echo    "🚀 STARTING SPRITE GENERATION SHEET PIPELINE"
echo -e "============================================\033[0m\n"

SCRIPTS=(
  "__make_sheets.sh _sequences-grid grid_sheets1_raw"
  "__fade_sheets.sh"
  "__matte_webp.sh grid_sheets2_faded grid_sheets3_webp"
)

echo "🚀 Starting sprite sheet pipeline..."

for script in "${SCRIPTS[@]}"; do
  echo "🔧 Running: $script"
  bash $script
done

echo "✅ All steps completed successfully."
