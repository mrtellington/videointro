#!/bin/bash
# Usage: ./render.sh "Title" "Subtitle" "Date" output-name
#
# Example:
#   ./render.sh \
#     "2026 Operations Summit" \
#     "Engine Behind the Experience" \
#     "Day 1  ·  March 24, 2026" \
#     summit-day1

TITLE="${1:?Usage: ./render.sh TITLE SUBTITLE DATE [output-name]}"
SUBTITLE="${2:?Missing subtitle}"
DATE="${3:?Missing date}"
OUTNAME="${4:-opener}"

mkdir -p out

npx remotion render Opener "out/${OUTNAME}.mp4" \
  --props="{\"title\":\"${TITLE}\",\"subtitle\":\"${SUBTITLE}\",\"date\":\"${DATE}\"}"

echo ""
echo "✓  Saved to out/${OUTNAME}.mp4"
