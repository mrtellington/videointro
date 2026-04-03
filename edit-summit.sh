#!/bin/bash
set -e

# ─── Operations Summit Day 1 — Full Edit ───────────────────────────────────
# Opener (20s) crossfades into content (1s dissolve, music under speaking)
# 7 kept segments with 5 crossfades (2s each) + 1 hard cut
# Studio sound on content audio, chapter markers embedded

SRC="/Users/todellington/Downloads/Operations Summit_ The Engine behind the Experience Day 1 - 2026_03_24 09_41 EDT - Recording.mp4"
OPENER="/Users/todellington/videointro/out/summit-day1.mp4"
OUTPUT="/Users/todellington/videointro/out/opssummit1.mp4"
WORKDIR="/Users/todellington/videointro/work"

mkdir -p "$WORKDIR"

# ── Segment math ──────────────────────────────────────────────────────────
# Seg durations: 2108.2  351.8  52.7  877.7  408.4  2338.9  4017.7
#
# Content xfade offsets (2s crossfades):
#   xf1: 2108.2-2     = 2106.2   → cumul dur = 2458.0
#   xf2: 2458.0-2     = 2456.0   → cumul dur = 2508.7
#   xf3: 2508.7-2     = 2506.7   → cumul dur = 3384.4
#   xf4: 3384.4-2     = 3382.4   → cumul dur = 3790.8
#   xf5: 3790.8-2     = 3788.8   → cumul dur = 6127.7
#   concat seg7:                   → cumul dur = 10145.4
#
# Opener (20s) → content xfade: 1s at offset 19
# Total output: 20 + 10145.4 - 1 = 10164.4s ≈ 2h 49m 24s
#
# Chapter timestamps (output seconds):
#   Intro:                0
#   Welcome:              19.0    (content t=0)
#   Decision Making:      2125.2  (content xf1 = 2106.2 + 19)
#   Communication:        2525.7  (content xf3 = 2506.7 + 19)
#   Customer Ops:         3401.4  (content xf4 = 3382.4 + 19)
#   Operational Impact:   3807.8  (content xf5 = 3788.8 + 19)
#   Wrap-Up:              6146.7  (content concat = 6127.7 + 19)

cat > "$WORKDIR/chapters.txt" << 'FFMETA'
;FFMETADATA1

[CHAPTER]
TIMEBASE=1/1000
START=0
END=18999
title=Intro

[CHAPTER]
TIMEBASE=1/1000
START=19000
END=2125199
title=Welcome & Framing

[CHAPTER]
TIMEBASE=1/1000
START=2125200
END=2525699
title=Empowered Decision Making

[CHAPTER]
TIMEBASE=1/1000
START=2525700
END=3401399
title=Communication That Builds Trust

[CHAPTER]
TIMEBASE=1/1000
START=3401400
END=3807799
title=Customer Obsessed Operations

[CHAPTER]
TIMEBASE=1/1000
START=3807800
END=6146699
title=Operational Impact

[CHAPTER]
TIMEBASE=1/1000
START=6146700
END=10164400
title=Ownership Commitments & Wrap-Up
FFMETA

echo "════════════════════════════════════════════════════════════"
echo " Operations Summit Day 1 — Full Edit"
echo " Output:   $OUTPUT"
echo " Duration: ~2h 49m 24s"
echo " Opener:   20s → 1s crossfade into content"
echo " Breaks:   2s crossfades (5x) + 1 hard cut"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Starting render..."
START_TIME=$(date +%s)

ffmpeg -y \
  -i "$OPENER" \
  -ss 6.8 -t 2108.2 -i "$SRC" \
  -ss 2754.2 -t 351.8 -i "$SRC" \
  -ss 3715.0 -t 52.7 -i "$SRC" \
  -ss 4340.2 -t 877.7 -i "$SRC" \
  -ss 6214.9 -t 408.4 -i "$SRC" \
  -ss 7720.5 -t 2338.9 -i "$SRC" \
  -ss 10342.8 -t 4017.7 -i "$SRC" \
  -i "$WORKDIR/chapters.txt" \
  -filter_complex "
    [0:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v0];
    [0:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a0];

    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v1];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a1];
    [2:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v2];
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a2];
    [3:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v3];
    [3:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a3];
    [4:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v4];
    [4:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a4];
    [5:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v5];
    [5:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a5];
    [6:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v6];
    [6:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a6];
    [7:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v7];
    [7:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a7];

    [v1][v2]xfade=transition=fade:duration=2:offset=2106.2[xv1];
    [xv1][v3]xfade=transition=fade:duration=2:offset=2456.0[xv2];
    [xv2][v4]xfade=transition=fade:duration=2:offset=2506.7[xv3];
    [xv3][v5]xfade=transition=fade:duration=2:offset=3382.4[xv4];
    [xv4][v6]xfade=transition=fade:duration=2:offset=3788.8[xv5];
    [xv5][v7]concat=n=2:v=1:a=0,settb=1/24,fps=24[vcontent];
    [v0][vcontent]xfade=transition=fade:duration=1:offset=19[vout];

    [a1][a2]acrossfade=d=2:c1=tri:c2=tri[xa1];
    [xa1][a3]acrossfade=d=2:c1=tri:c2=tri[xa2];
    [xa2][a4]acrossfade=d=2:c1=tri:c2=tri[xa3];
    [xa3][a5]acrossfade=d=2:c1=tri:c2=tri[xa4];
    [xa4][a6]acrossfade=d=2:c1=tri:c2=tri[xa5];
    [xa5][a7]concat=n=2:v=0:a=1[acontent_raw];
    [acontent_raw]highpass=f=80,afftdn=nt=w:om=o,equalizer=f=180:t=q:w=1:g=-3,equalizer=f=3500:t=q:w=1.5:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200,loudnorm=I=-14:LRA=7:TP=-2[acontent];
    [a0][acontent]acrossfade=d=1:c1=tri:c2=tri[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -map_chapters 8 \
  -c:v libx264 -preset medium -crf 20 \
  -c:a aac -ar 48000 -b:a 192k \
  -movflags +faststart \
  "$OUTPUT"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINS=$(( ELAPSED / 60 ))
echo ""
echo "════════════════════════════════════════════════════════════"
echo " ✓ Done in ${MINS}m"
echo ""
ls -lh "$OUTPUT"
echo ""
echo " Chapters:"
ffprobe -v error -show_chapters -of csv "$OUTPUT" 2>&1 | awk -F',' '{printf "  %s → %s  %s\n", $5, $6, $NF}'
echo "════════════════════════════════════════════════════════════"
