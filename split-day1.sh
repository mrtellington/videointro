#!/bin/bash
set -e

# ─── Operations Summit Day 1 — Split into Individual Session Videos ─────────
#
# 6 videos, each with custom opener + studio sound + outro:
#   1. Welcome & Framing
#   2. Empowered Decision Making
#   3. Communication That Builds Trust
#   4. Customer Obsessed Operations
#   5. Operational Impact
#   6. Ownership Commitments & Wrap-Up

SRC="/Users/todellington/Downloads/Operations Summit_ The Engine behind the Experience Day 1 - 2026_03_24 09_41 EDT - Recording.mp4"
WORKDIR="/Users/todellington/videointro/work/day1-split"
OUTDIR="/Users/todellington/videointro/out"
SUBTITLE="2026 Operations Summit: Engine Behind the Experience"
DATE="Day 1  ·  March 24, 2026"

AUDIO_FILTER="highpass=f=80,afftdn=nt=w:om=o,equalizer=f=180:t=q:w=1:g=-3,equalizer=f=3500:t=q:w=1.5:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200,loudnorm=I=-14:LRA=7:TP=-2"

mkdir -p "$WORKDIR" "$OUTDIR"

START_TIME=$(date +%s)

echo "════════════════════════════════════════════════════════════"
echo " Operations Summit Day 1 — Splitting into 6 videos"
echo "════════════════════════════════════════════════════════════"

# ── Helper: render opener + outro for a section ──
render_bookends() {
  local TITLE="$1"
  local SLUG="$2"
  local PROPS="{\"title\":\"${TITLE}\",\"subtitle\":\"${SUBTITLE}\",\"date\":\"${DATE}\"}"

  echo "  Rendering opener + outro for: $TITLE"
  npx remotion render Opener "$WORKDIR/${SLUG}-opener.mp4" --props="$PROPS" 2>&1 | grep -q "Encoded" && echo "    ✓ opener"
  npx remotion render Outro "$WORKDIR/${SLUG}-outro.mp4" --props="$PROPS" 2>&1 | grep -q "Encoded" && echo "    ✓ outro"
}

# ── Helper: extract a single segment with studio sound ──
extract_segment() {
  local START="$1"
  local DUR="$2"
  local OUT="$3"

  ffmpeg -y -loglevel warning -stats \
    -ss "$START" -t "$DUR" -i "$SRC" \
    -vf "fps=24,format=yuv420p,setpts=PTS-STARTPTS" \
    -af "aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS,${AUDIO_FILTER}" \
    -c:v libx264 -preset medium -crf 20 \
    -c:a aac -ar 48000 -b:a 192k \
    "$OUT"
}

# ── Helper: assemble opener (20s) + content + outro (18s) with 1s crossfades ──
assemble() {
  local SLUG="$1"
  local OPENER="$WORKDIR/${SLUG}-opener.mp4"
  local CONTENT="$WORKDIR/${SLUG}-content.mp4"
  local OUTRO="$WORKDIR/${SLUG}-outro.mp4"
  local OUTPUT="$OUTDIR/day1-${SLUG}.mp4"

  local CONTENT_DUR
  CONTENT_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$CONTENT")
  local WITH_OPENER
  WITH_OPENER=$(echo "20 + $CONTENT_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
  local OUTRO_OFFSET
  OUTRO_OFFSET=$(echo "$WITH_OPENER - 1" | bc | sed 's/^\./0./;s/^-\./-0./')

  echo "  Assembling: $OUTPUT (content: ${CONTENT_DUR}s)"

  ffmpeg -y -loglevel warning -stats \
    -i "$OPENER" \
    -i "$CONTENT" \
    -i "$OUTRO" \
    -filter_complex "
      [0:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v0];
      [0:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a0];
      [1:v]settb=1/24,fps=24,format=yuv420p[vc];
      [1:a]asetpts=PTS-STARTPTS[ac];
      [2:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v2];
      [2:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a2];
      [v0][vc]xfade=transition=fade:duration=1:offset=19[vx1];
      [vx1]settb=1/24,fps=24[vn];
      [vn][v2]xfade=transition=fade:duration=1:offset=${OUTRO_OFFSET}[vout];
      [a0][ac]acrossfade=d=1:c1=tri:c2=tri[ax1];
      [ax1][a2]acrossfade=d=1:c1=tri:c2=tri[aout]
    " \
    -map "[vout]" -map "[aout]" \
    -c:v libx264 -preset medium -crf 20 \
    -c:a aac -ar 48000 -b:a 192k \
    -movflags +faststart \
    "$OUTPUT"

  echo "  ✓ $(ls -lh "$OUTPUT" | awk '{print $5}')  $OUTPUT"
}

# ════════════════════════════════════════════════════════════════════════════
# 1. Welcome & Framing — with word edit at ~36s
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 1/6: Welcome & Framing ───"
render_bookends "Welcome & Framing" "welcome"

# Word edit: "we [are going to] spend a lot of [the] time..."
WE_END=35.7; SPEND_START=36.4; OF_END=37.3; TIME_START=37.5
S1A_DUR=$(echo "$WE_END - 6.8" | bc | sed 's/^\./0./;s/^-\./-0./')
S1B_DUR=$(echo "$OF_END - $SPEND_START" | bc | sed 's/^\./0./;s/^-\./-0./')
S1C_DUR=$(echo "2115 - $TIME_START" | bc | sed 's/^\./0./;s/^-\./-0./')
XF=0.06
XF1=$(echo "$S1A_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XF2=$(echo "$S1A_DUR + $S1B_DUR - 2 * $XF" | bc | sed 's/^\./0./;s/^-\./-0./')

echo "  Extracting with word edit..."
ffmpeg -y -loglevel warning -stats \
  -ss 6.8 -t "$S1A_DUR" -i "$SRC" \
  -ss "$SPEND_START" -t "$S1B_DUR" -i "$SRC" \
  -ss "$TIME_START" -t "$S1C_DUR" -i "$SRC" \
  -filter_complex "
    [0:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[va];
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[aa];
    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[vb];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[ab];
    [2:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[vc];
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[ac];
    [va][vb]xfade=transition=fade:duration=$XF:offset=$XF1[xv1];
    [xv1][vc]xfade=transition=fade:duration=$XF:offset=$XF2[vout];
    [aa][ab]acrossfade=d=$XF[xa1];
    [xa1][ac]acrossfade=d=$XF[a_raw];
    [a_raw]${AUDIO_FILTER}[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 18 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/welcome-content.mp4"

assemble "welcome"

# ════════════════════════════════════════════════════════════════════════════
# 2. Empowered Decision Making — two sub-segments with crossfade
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 2/6: Empowered Decision Making ───"
render_bookends "Empowered Decision Making" "decision-making"

S2A_START=2754.2; S2A_DUR=351.8   # 45:54.2 → 51:46
S2B_START=3715;   S2B_DUR=52.7    # 1:01:55 → 1:02:47.7
XF2_OFFSET=$(echo "$S2A_DUR - 2" | bc | sed 's/^\./0./;s/^-\./-0./')

echo "  Extracting 2 sub-segments with crossfade..."
ffmpeg -y -loglevel warning -stats \
  -ss $S2A_START -t $S2A_DUR -i "$SRC" \
  -ss $S2B_START -t $S2B_DUR -i "$SRC" \
  -filter_complex "
    [0:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[va];
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[aa];
    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[vb];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[ab];
    [va][vb]xfade=transition=fade:duration=2:offset=$XF2_OFFSET[vout];
    [aa][ab]acrossfade=d=2:c1=tri:c2=tri[a_raw];
    [a_raw]${AUDIO_FILTER}[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 20 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/decision-making-content.mp4"

assemble "decision-making"

# ════════════════════════════════════════════════════════════════════════════
# 3. Communication That Builds Trust — single segment
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 3/6: Communication That Builds Trust ───"
render_bookends "Communication That Builds Trust" "communication"

echo "  Extracting segment..."
extract_segment 4340.2 877.7 "$WORKDIR/communication-content.mp4"

assemble "communication"

# ════════════════════════════════════════════════════════════════════════════
# 4. Customer Obsessed Operations — single segment
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 4/6: Customer Obsessed Operations ───"
render_bookends "Customer Obsessed Operations" "customer-ops"

echo "  Extracting segment..."
extract_segment 6214.9 408.4 "$WORKDIR/customer-ops-content.mp4"

assemble "customer-ops"

# ════════════════════════════════════════════════════════════════════════════
# 5. Operational Impact — single segment
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 5/6: Operational Impact ───"
render_bookends "Operational Impact" "operational-impact"

echo "  Extracting segment..."
extract_segment 7720.5 2338.9 "$WORKDIR/operational-impact-content.mp4"

assemble "operational-impact"

# ════════════════════════════════════════════════════════════════════════════
# 6. Ownership Commitments & Wrap-Up — single segment (trimmed end)
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "─── 6/6: Ownership Commitments & Wrap-Up ───"
render_bookends "Ownership Commitments & Wrap-Up" "ownership"

echo "  Extracting segment..."
extract_segment 10342.8 4007.3 "$WORKDIR/ownership-content.mp4"

assemble "ownership"

# ════════════════════════════════════════════════════════════════════════════
END_TIME=$(date +%s)
ELAPSED=$(( (END_TIME - START_TIME) / 60 ))
echo ""
echo "════════════════════════════════════════════════════════════"
echo " ✓ All 6 videos complete in ${ELAPSED}m"
echo ""
ls -lh "$OUTDIR"/day1-*.mp4
echo "════════════════════════════════════════════════════════════"
