#!/bin/bash
set -e

# ─── Operations Summit Day 1 — Re-Split from opssummit1.mp4 ─────────────────
#
# Source is the fully-edited opssummit1.mp4 (audio already mastered).
# Timestamps are relative to that file.
# Each section gets its own branded opener + outro.

SRC="/Users/todellington/videointro/out/opssummit1.mp4"
WORKDIR="/Users/todellington/videointro/work/day1-v2"
OUTDIR="/Users/todellington/videointro/out"
SUBTITLE="2026 Operations Summit: Engine Behind the Experience"
DATE="Day 1  ·  March 24, 2026"

mkdir -p "$WORKDIR" "$OUTDIR"

START_TIME=$(date +%s)

echo "════════════════════════════════════════════════════════════"
echo " Operations Summit Day 1 — Re-Split from opssummit1.mp4"
echo "════════════════════════════════════════════════════════════"

# ── Helper: render opener + outro for a section ──
render_bookends() {
  local TITLE="$1"
  local SLUG="$2"
  local PROPS="{\"title\":\"${TITLE}\",\"subtitle\":\"${SUBTITLE}\",\"date\":\"${DATE}\"}"

  echo "  Rendering opener + outro for: $TITLE"
  npx remotion render Opener "$WORKDIR/${SLUG}-opener.mp4" --props="$PROPS" 2>&1 | grep -q "Encoded" && echo "    ✓ opener"
  npx remotion render Outro  "$WORKDIR/${SLUG}-outro.mp4"  --props="$PROPS" 2>&1 | grep -q "Encoded" && echo "    ✓ outro"
}

# ── Helper: extract a segment from opssummit1.mp4 (no audio re-processing) ──
extract_segment() {
  local START="$1"
  local END="$2"
  local OUT="$3"
  local DUR
  DUR=$(echo "$END - $START" | bc | sed 's/^\./0./;s/^-\./-0./')

  ffmpeg -y -loglevel warning -stats \
    -ss "$START" -to "$END" -i "$SRC" \
    -vf "fps=24,format=yuv420p,setpts=PTS-STARTPTS" \
    -af "aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS" \
    -c:v libx264 -preset medium -crf 20 \
    -c:a aac -ar 48000 -b:a 192k \
    "$OUT"
}

# ── Helper: assemble opener (20s) + content + outro (18s) with 1s crossfades ──
assemble() {
  local SLUG="$1"
  local TITLE="$2"
  local OPENER="$WORKDIR/${SLUG}-opener.mp4"
  local CONTENT="$WORKDIR/${SLUG}-content.mp4"
  local OUTRO="$WORKDIR/${SLUG}-outro.mp4"
  local OUTPUT="$OUTDIR/day1-v2-${SLUG}.mp4"

  local CONTENT_DUR
  CONTENT_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$CONTENT")
  local OUTRO_OFFSET
  OUTRO_OFFSET=$(echo "20 + $CONTENT_DUR - 1 - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
  local FINAL_DUR
  FINAL_DUR=$(echo "20 + $CONTENT_DUR - 1 + 18 - 1" | bc | sed 's/^\./0./;s/^-\./-0./')

  echo "  Assembling: $OUTPUT (content: ${CONTENT_DUR}s, total: ${FINAL_DUR}s)"

  ffmpeg -y -loglevel warning -stats \
    -i "$OPENER" \
    -i "$CONTENT" \
    -i "$OUTRO" \
    -filter_complex "
      [0:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v0];
      [0:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a0];
      [1:v]settb=1/24,fps=24,format=yuv420p,setpts=PTS-STARTPTS[vc];
      [1:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[ac];
      [2:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v2];
      [2:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a2];
      [v0][vc]xfade=transition=fade:duration=1:offset=19[vx1];
      [vx1]settb=1/24,fps=24,setpts=PTS-STARTPTS[vn];
      [vn][v2]xfade=transition=fade:duration=1:offset=${OUTRO_OFFSET}[vout];
      [a0][ac]acrossfade=d=1:c1=tri:c2=tri[ax1];
      [ax1][a2]acrossfade=d=1:c1=tri:c2=tri[aout]
    " \
    -map "[vout]" -map "[aout]" \
    -t "$FINAL_DUR" \
    -c:v libx264 -preset medium -crf 20 \
    -c:a aac -ar 48000 -b:a 192k \
    -movflags +faststart \
    "$OUTPUT"

  echo "  ✓ $(ls -lh "$OUTPUT" | awk '{print $5}')  $OUTPUT"
}

# ════════════════════════════════════════════════════════════════════════════
# 1. Welcome & Framing
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 1: Welcome & Framing ───"
render_bookends "Welcome & Framing" "welcome"

# Word edits (all timestamps in opssummit1.mp4):
#   Cut 1: 28.0 → 32.0  "um, thinking about how we can make operations great and,"
#   Cut 2: 35.5 → 36.0  "'re gonna" (we're gonna → we)
#   Cut 3: 45.0 → 46.0  "uh, or we do that now"
XF=0.06
SA_DUR=8.0     # 20→28
SB_DUR=3.5     # 32→35.5
SC_DUR=9.0     # 36→45
SD_DUR=928.0   # 46→974

XO1=$(echo "$SA_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO2=$(echo "$SA_DUR + $SB_DUR - 2*$XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO3=$(echo "$SA_DUR + $SB_DUR + $SC_DUR - 3*$XF" | bc | sed 's/^\./0./;s/^-\./-0./')

echo "  Extracting with 3 word edits..."
ffmpeg -y -loglevel warning -stats \
  -ss 20   -t $SA_DUR -i "$SRC" \
  -ss 32   -t $SB_DUR -i "$SRC" \
  -ss 36   -t $SC_DUR -i "$SRC" \
  -ss 46   -t $SD_DUR -i "$SRC" \
  -filter_complex "
    [0:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v0];
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a0];
    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v1];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a1];
    [2:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v2];
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a2];
    [3:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v3];
    [3:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a3];
    [v0][v1]xfade=transition=fade:duration=${XF}:offset=${XO1}[x1];
    [x1][v2]xfade=transition=fade:duration=${XF}:offset=${XO2}[x2];
    [x2][v3]xfade=transition=fade:duration=${XF}:offset=${XO3}[vout];
    [a0][a1]acrossfade=d=${XF}:c1=tri:c2=tri[xa1];
    [xa1][a2]acrossfade=d=${XF}:c1=tri:c2=tri[xa2];
    [xa2][a3]acrossfade=d=${XF}:c1=tri:c2=tri[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 20 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/welcome-content.mp4"

assemble "welcome" "Welcome & Framing"

# ════════════════════════════════════════════════════════════════════════════
END_TIME=$(date +%s)
ELAPSED=$(( (END_TIME - START_TIME) / 60 ))
echo ""
echo "════════════════════════════════════════════════════════════"
echo " ✓ Done in ${ELAPSED}m"
ls -lh "$OUTDIR"/day1-v2-*.mp4 2>/dev/null
echo "════════════════════════════════════════════════════════════"
