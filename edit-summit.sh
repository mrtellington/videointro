#!/bin/bash
set -e

# ─── Operations Summit Day 1 — Full Edit ───────────────────────────────────
# Opener (25s) + 7 kept segments with 5 crossfades + 1 hard cut
# Studio sound on content audio, chapter markers embedded
#
# Final duration: ~2h 49m 35s
# Expected render time: ~1-2 hours on Apple Silicon

SRC="/Users/todellington/Downloads/Operations Summit_ The Engine behind the Experience Day 1 - 2026_03_24 09_41 EDT - Recording.mp4"
OPENER="/Users/todellington/videointro/out/summit-day1.mp4"
OUTPUT="/Users/todellington/videointro/out/opssummit1.mp4"
WORKDIR="/Users/todellington/videointro/work"

mkdir -p "$WORKDIR"

# ── Chapter metadata ──
cat > "$WORKDIR/chapters.txt" << 'FFMETA'
;FFMETADATA1

[CHAPTER]
TIMEBASE=1/1000
START=0
END=24999
title=Intro

[CHAPTER]
TIMEBASE=1/1000
START=25000
END=2132199
title=Welcome & Framing

[CHAPTER]
TIMEBASE=1/1000
START=2132200
END=2534699
title=Empowered Decision Making

[CHAPTER]
TIMEBASE=1/1000
START=2534700
END=3411399
title=Communication That Builds Trust

[CHAPTER]
TIMEBASE=1/1000
START=3411400
END=3818799
title=Customer Obsessed Operations

[CHAPTER]
TIMEBASE=1/1000
START=3818800
END=6157699
title=Operational Impact

[CHAPTER]
TIMEBASE=1/1000
START=6157700
END=10175400
title=Ownership Commitments & Wrap-Up
FFMETA

# ── Segment map ──
# Kept segments from source (start → duration):
#   Seg1: 00:06.8 → 35:15.0   (2108.2s)  — Welcome & Framing
#   Seg2: 45:54.2 → 51:46.0   (351.8s)   ─┐ Empowered Decision Making
#   Seg3: 1:01:55 → 1:02:47.7 (52.7s)    ─┘
#   Seg4: 1:12:20.2 → 1:26:57.9 (877.7s) — Communication That Builds Trust
#   Seg5: 1:43:34.9 → 1:50:23.3 (408.4s) — Customer Obsessed Operations
#   Seg6: 2:08:40.5 → 2:47:39.4 (2338.9s) — Operational Impact
#   Seg7: 2:52:22.8 → 3:59:20.5 (4017.7s) — Ownership Commitments & Wrap-Up
#
# Transitions: xfade (1s dissolve) between 1↔2, 2↔3, 3↔4, 4↔5, 5↔6
#              hard cut between 6↔7
#
# xfade offsets (cumulative in content stream):
#   xfade1: 2107.2   (seg1 dur - 1)
#   xfade2: 2458.0   (prev + seg2 dur - 1)
#   xfade3: 2509.7   (prev + seg3 dur - 1)
#   xfade4: 3386.4   (prev + seg4 dur - 1)
#   xfade5: 3793.8   (prev + seg5 dur - 1)

echo "════════════════════════════════════════════════════════════"
echo " Operations Summit Day 1 — Full Edit"
echo " Output:   $OUTPUT"
echo " Duration: ~2h 49m 35s"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Starting render — this will take a while..."
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
    [0:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS[a0];

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

    [v1][v2]xfade=transition=fade:duration=1:offset=2107.2[xv1];
    [xv1][v3]xfade=transition=fade:duration=1:offset=2458.0[xv2];
    [xv2][v4]xfade=transition=fade:duration=1:offset=2509.7[xv3];
    [xv3][v5]xfade=transition=fade:duration=1:offset=3386.4[xv4];
    [xv4][v6]xfade=transition=fade:duration=1:offset=3793.8[xv5];
    [xv5][v7]concat=n=2:v=1:a=0[vcontent];
    [v0][vcontent]concat=n=2:v=1:a=0[vout];

    [a1][a2]acrossfade=d=1:c1=tri:c2=tri[xa1];
    [xa1][a3]acrossfade=d=1:c1=tri:c2=tri[xa2];
    [xa2][a4]acrossfade=d=1:c1=tri:c2=tri[xa3];
    [xa3][a5]acrossfade=d=1:c1=tri:c2=tri[xa4];
    [xa4][a6]acrossfade=d=1:c1=tri:c2=tri[xa5];
    [xa5][a7]concat=n=2:v=0:a=1[acontent_raw];
    [acontent_raw]highpass=f=80,afftdn=nt=w:om=o,equalizer=f=180:t=q:w=1:g=-3,equalizer=f=3500:t=q:w=1.5:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200,loudnorm=I=-14:LRA=7:TP=-2[acontent];
    [a0][acontent]concat=n=2:v=0:a=1[aout]
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
