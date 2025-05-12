#!/bin/bash

set -e  # Exit immediately on error

echo -e "\n\033[1;36m============================================"
echo    "🚀 STARTING SPRITE GENERATION SHEET PIPELINE"
echo -e "============================================\033[0m\n"

# Ordered processing scripts
SCRIPTS=(
  "_1_make_sheets.sh"
  "_2_fade_sheets.sh"
  "_3_matte_sheets.sh"
)

echo "🚀 Starting sprite sheet pipeline..."

for script in "${SCRIPTS[@]}"; do
  if [[ -x "$script" ]]; then
    echo "🔧 Running $script..."
    ./"$script"
  else
    echo "❌ ERROR: $script not found or not executable"
    exit 1
  fi
done

echo "✅ All steps completed successfully."
