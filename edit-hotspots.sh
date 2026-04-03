#!/bin/bash
set -e

# ─── Hot Spots Activity Summary — Full Edit ─────────────────────────────────
# Opener (20s) → Full recording (studio sound, pillarboxed) → Outro (18s)
# No trims — the recording is used in its entirety (~11 min)

SRC="/Users/todellington/Downloads/2026 Ops Summit - _Hot Spots_ Exercise Overview.mp4"
OPENER="/Users/todellington/videointro/out/hotspots-opener.mp4"
OUTRO="/Users/todellington/videointro/out/hotspots-outro.mp4"
OUTPUT="/Users/todellington/videointro/out/hotspots.mp4"
WORKDIR="/Users/todellington/videointro/work"

mkdir -p "$WORKDIR"

AUDIO_FILTER="highpass=f=80,afftdn=nt=w:om=o,equalizer=f=180:t=q:w=1:g=-3,equalizer=f=3500:t=q:w=1.5:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200,loudnorm=I=-14:LRA=7:TP=-2"

echo "════════════════════════════════════════════════════════════"
echo " Hot Spots Activity Summary — Full Edit"
echo "════════════════════════════════════════════════════════════"
START_TIME=$(date +%s)

# ── Pass 1: Extract + studio sound + pillarbox to 1920x1080 ──
echo ""
echo "Pass 1: Processing recording (studio sound + pillarbox)..."

ffmpeg -y -loglevel warning -stats \
  -i "$SRC" \
  -vf "fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:color=0x0e1237,setsar=1,format=yuv420p,setpts=PTS-STARTPTS" \
  -af "aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS,${AUDIO_FILTER}" \
  -c:v libx264 -preset medium -crf 20 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/hotspots-content.mp4"

CONTENT_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WORKDIR/hotspots-content.mp4")
echo "  Content: ${CONTENT_DUR}s"

# ── Pass 2: Opener + Content + Outro with crossfades ──
echo ""
echo "Pass 2: Assembling with opener + outro..."

WITH_OPENER=$(echo "20 + $CONTENT_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
OUTRO_OFFSET=$(echo "$WITH_OPENER - 1" | bc | sed 's/^\./0./;s/^-\./-0./')

ffmpeg -y -loglevel warning -stats \
  -i "$OPENER" \
  -i "$WORKDIR/hotspots-content.mp4" \
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

END_TIME=$(date +%s)
ELAPSED=$(( (END_TIME - START_TIME) / 60 ))
echo ""
echo "════════════════════════════════════════════════════════════"
echo " ✓ Done in ${ELAPSED}m"
ls -lh "$OUTPUT"
echo "════════════════════════════════════════════════════════════"
