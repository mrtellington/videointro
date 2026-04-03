#!/bin/bash
# Render the Whitestone outro (20s, "Thank You" → logo)
# Usage: ./render-outro.sh [output-name] [--no-music]
#
# Examples:
#   ./render-outro.sh outro-summit-day1
#   ./render-outro.sh outro-no-music --no-music

OUTNAME="${1:-outro}"
MUSIC="true"
[[ "$2" == "--no-music" || "$1" == "--no-music" ]] && MUSIC="false"
[[ "$1" == "--no-music" ]] && OUTNAME="outro"

mkdir -p out

npx remotion render Outro "out/${OUTNAME}.mp4" \
  --props="{\"music\":${MUSIC}}"

echo ""
echo "✓  Saved to out/${OUTNAME}.mp4"
