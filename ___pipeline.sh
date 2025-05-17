#!/bin/bash
set -e

echo -e "\n\033[1;36m============================================"
echo    "🚀 STARTING SPRITE GENERATION SHEET PIPELINE"
echo -e "============================================\033[0m\n"

SCRIPTS=(
  "__make_sheets.sh _sequences sheets1_raw"
  "__normal_webp.sh sheets1_raw sheets2_webp"
)

echo "🚀 Starting sprite sheet pipeline..."

for script in "${SCRIPTS[@]}"; do
  echo "🔧 Running: $script"
  bash $script
done

echo "✅ All steps completed successfully."
