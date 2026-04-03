#!/bin/bash
# Render both opener and outro with matching props.
# Usage: ./render-all.sh "Title" "Subtitle" "Date" output-name
#
# Example:
#   ./render-all.sh \
#     "2026 Operations Summit" \
#     "Engine Behind the Experience" \
#     "Day 1  ·  March 24, 2026" \
#     summit-day1

TITLE="${1:?Usage: ./render-all.sh TITLE SUBTITLE DATE [output-name]}"
SUBTITLE="${2:?Missing subtitle}"
DATE="${3:?Missing date}"
OUTNAME="${4:-video}"

PROPS="{\"title\":\"${TITLE}\",\"subtitle\":\"${SUBTITLE}\",\"date\":\"${DATE}\"}"

mkdir -p out

echo "Rendering opener..."
npx remotion render Opener "out/${OUTNAME}-opener.mp4" --props="$PROPS"

echo ""
echo "Rendering outro..."
npx remotion render Outro "out/${OUTNAME}-outro.mp4" --props="$PROPS"

echo ""
echo "✓  Opener: out/${OUTNAME}-opener.mp4"
echo "✓  Outro:  out/${OUTNAME}-outro.mp4"
