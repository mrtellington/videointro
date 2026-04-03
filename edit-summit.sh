#!/bin/bash
set -e

# ─── Operations Summit Day 1 — Full Edit Pipeline ──────────────────────────
#
# Pass 0: Word edit on segment 1 (remove "are going to" and "the")
# Pass 1: Build content chain (all segments + crossfades + studio sound)
# Pass 2: Sandwich opener + content + outro with crossfades + chapters
#
# Adjust CUT timestamps below if the word splice doesn't align perfectly.

SRC="/Users/todellington/Downloads/Operations Summit_ The Engine behind the Experience Day 1 - 2026_03_24 09_41 EDT - Recording.mp4"
OPENER="/Users/todellington/videointro/out/summit-day1-opener.mp4"
OUTRO="/Users/todellington/videointro/out/summit-day1-outro.mp4"
OUTPUT="/Users/todellington/videointro/out/opssummit1.mp4"
WORKDIR="/Users/todellington/videointro/work"

mkdir -p "$WORKDIR"

# bc strips leading zeros (.9 instead of 0.9) — ffmpeg rejects that
calc() { echo "scale=3; $1" | bc | sed 's/^\./0./;s/^-\./-0./'; }

echo "════════════════════════════════════════════════════════════"
echo " Operations Summit Day 1 — Full Edit"
echo "════════════════════════════════════════════════════════════"
START_TIME=$(date +%s)

# ════════════════════════════════════════════════════════════════════════════
# PASS 0: Word edit on segment 1
# ════════════════════════════════════════════════════════════════════════════
# Original @ ~36s: "we [are going to] spend a lot of [the] time..."
# Target:          "we spend a lot of time..."
#
# ⚠️  ADJUST these if the splice sounds off:
WE_END=35.7        # timestamp where "we" ends
SPEND_START=36.4   # timestamp where "spend" begins
OF_END=37.3        # timestamp where "of" ends
TIME_START=37.5    # timestamp where "time" begins
SEG1_END=2115.0    # 35:15 in seconds

echo ""
echo "Pass 0: Editing segment 1 (word splice @ ~36s)..."

SEG1A_DUR=$(echo "$WE_END - 6.8" | bc | sed 's/^\./0./;s/^-\./-0./')
SEG1B_DUR=$(echo "$OF_END - $SPEND_START" | bc | sed 's/^\./0./;s/^-\./-0./')
SEG1C_DUR=$(echo "$SEG1_END - $TIME_START" | bc | sed 's/^\./0./;s/^-\./-0./')
XF_DUR=0.06

# Offset for second micro-xfade = seg1a + seg1b - 2 * xfade
XF1_OFFSET=$(echo "$SEG1A_DUR - $XF_DUR" | bc | sed 's/^\./0./;s/^-\./-0./')
XF2_OFFSET=$(echo "$SEG1A_DUR + $SEG1B_DUR - 2 * $XF_DUR" | bc | sed 's/^\./0./;s/^-\./-0./')

ffmpeg -y -loglevel warning -stats \
  -ss 6.8 -t "$SEG1A_DUR" -i "$SRC" \
  -ss "$SPEND_START" -t "$SEG1B_DUR" -i "$SRC" \
  -ss "$TIME_START" -t "$SEG1C_DUR" -i "$SRC" \
  -filter_complex "
    [0:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[va];
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[aa];
    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[vb];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[ab];
    [2:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[vc];
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[ac];
    [va][vb]xfade=transition=fade:duration=$XF_DUR:offset=$XF1_OFFSET[xv1];
    [xv1][vc]xfade=transition=fade:duration=$XF_DUR:offset=$XF2_OFFSET[vout];
    [aa][ab]acrossfade=d=$XF_DUR[xa1];
    [xa1][ac]acrossfade=d=$XF_DUR[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 18 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/seg1.mp4"

SEG1_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WORKDIR/seg1.mp4")
echo "  Segment 1 edited: ${SEG1_DUR}s"

# ════════════════════════════════════════════════════════════════════════════
# PASS 1: Build content chain (7 segments with crossfades + studio sound)
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "Pass 1: Building content chain (crossfades + studio sound)..."

# Segment durations (seg1 from probe, rest from source timestamps)
S2_DUR=351.8; S3_DUR=52.7; S4_DUR=877.7; S5_DUR=408.4; S6_DUR=2338.9; S7_DUR=4017.7
XF=2  # crossfade duration between segments

# Cumulative xfade offsets
XO1=$(echo "$SEG1_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CUM1=$(echo "$SEG1_DUR + $S2_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO2=$(echo "$CUM1 - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CUM2=$(echo "$CUM1 + $S3_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO3=$(echo "$CUM2 - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CUM3=$(echo "$CUM2 + $S4_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO4=$(echo "$CUM3 - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CUM4=$(echo "$CUM3 + $S5_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO5=$(echo "$CUM4 - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')

echo "  xfade offsets: $XO1 | $XO2 | $XO3 | $XO4 | $XO5"

ffmpeg -y -loglevel warning -stats \
  -i "$WORKDIR/seg1.mp4" \
  -ss 2754.2 -t $S2_DUR -i "$SRC" \
  -ss 3715.0 -t $S3_DUR -i "$SRC" \
  -ss 4340.2 -t $S4_DUR -i "$SRC" \
  -ss 6214.9 -t $S5_DUR -i "$SRC" \
  -ss 7720.5 -t $S6_DUR -i "$SRC" \
  -ss 10342.8 -t $S7_DUR -i "$SRC" \
  -filter_complex "
    [0:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v1];
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a1];
    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v2];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a2];
    [2:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v3];
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a3];
    [3:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v4];
    [3:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a4];
    [4:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v5];
    [4:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a5];
    [5:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v6];
    [5:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a6];
    [6:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v7];
    [6:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a7];

    [v1][v2]xfade=transition=fade:duration=$XF:offset=$XO1[xv1];
    [xv1][v3]xfade=transition=fade:duration=$XF:offset=$XO2[xv2];
    [xv2][v4]xfade=transition=fade:duration=$XF:offset=$XO3[xv3];
    [xv3][v5]xfade=transition=fade:duration=$XF:offset=$XO4[xv4];
    [xv4][v6]xfade=transition=fade:duration=$XF:offset=$XO5[xv5];
    [xv5][v7]concat=n=2:v=1:a=0[vout];

    [a1][a2]acrossfade=d=$XF:c1=tri:c2=tri[xa1];
    [xa1][a3]acrossfade=d=$XF:c1=tri:c2=tri[xa2];
    [xa2][a4]acrossfade=d=$XF:c1=tri:c2=tri[xa3];
    [xa3][a5]acrossfade=d=$XF:c1=tri:c2=tri[xa4];
    [xa4][a6]acrossfade=d=$XF:c1=tri:c2=tri[xa5];
    [xa5][a7]concat=n=2:v=0:a=1[a_raw];
    [a_raw]highpass=f=80,afftdn=nt=w:om=o,equalizer=f=180:t=q:w=1:g=-3,equalizer=f=3500:t=q:w=1.5:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200,loudnorm=I=-14:LRA=7:TP=-2[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 20 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/content.mp4"

CONTENT_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WORKDIR/content.mp4")
echo "  Content built: ${CONTENT_DUR}s"

# ════════════════════════════════════════════════════════════════════════════
# PASS 2: Opener (20s) + Content + Outro (18s) with crossfades + chapters
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "Pass 2: Adding opener + outro with crossfades..."

# Opener xfade: starts at 19s (last 1s of opener blends into content)
# After opener xfade: duration = 20 + content - 1
OPENER_XF_OFFSET=19
WITH_OPENER_DUR=$(echo "20 + $CONTENT_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')

# Outro xfade: starts 1s before the end of the opener+content
OUTRO_XF_OFFSET=$(echo "$WITH_OPENER_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')

# Total final duration = with_opener + 18 (outro) - 1 (xfade)
FINAL_DUR=$(echo "$WITH_OPENER_DUR + 18 - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
FINAL_MINS=$(echo "$FINAL_DUR / 60" | bc | sed 's/^\./0./;s/^-\./-0./')

echo "  Content: ${CONTENT_DUR}s"
echo "  Outro xfade offset: ${OUTRO_XF_OFFSET}"
echo "  Final duration: ~${FINAL_MINS}m"

# ── Chapter metadata (computed from actual durations) ──
# Chapters at segment boundaries (content timeline + 19s for opener xfade)
CH1_START=0
CH1_END=$(echo "($OPENER_XF_OFFSET - 0.001) * 1000" | bc | cut -d. -f1)
CH2_START=$(echo "$OPENER_XF_OFFSET * 1000" | bc | cut -d. -f1)
CH2_END=$(echo "($OPENER_XF_OFFSET + $XO1) * 1000" | bc | cut -d. -f1)
CH3_START=$((CH2_END + 1))
CH3_END=$(echo "($OPENER_XF_OFFSET + $XO3) * 1000" | bc | cut -d. -f1)
CH4_START=$((CH3_END + 1))
CH4_END=$(echo "($OPENER_XF_OFFSET + $XO4) * 1000" | bc | cut -d. -f1)
CH5_START=$((CH4_END + 1))
CH5_END=$(echo "($OPENER_XF_OFFSET + $XO5) * 1000" | bc | cut -d. -f1)
CH6_START=$((CH5_END + 1))
# Seg6 ends where seg7 starts (concat, no xfade)
CUM5=$(echo "$CUM4 + $S6_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CH6_END=$(echo "($OPENER_XF_OFFSET + $CUM5) * 1000" | bc | cut -d. -f1)
CH7_START=$((CH6_END + 1))
CH7_END=$(echo "($FINAL_DUR - 18) * 1000" | bc | cut -d. -f1)
CH8_START=$((CH7_END + 1))
CH8_END=$(echo "$FINAL_DUR * 1000" | bc | cut -d. -f1)

cat > "$WORKDIR/chapters.txt" << FFMETA
;FFMETADATA1

[CHAPTER]
TIMEBASE=1/1000
START=$CH1_START
END=$CH1_END
title=Intro

[CHAPTER]
TIMEBASE=1/1000
START=$CH2_START
END=$CH2_END
title=Welcome & Framing

[CHAPTER]
TIMEBASE=1/1000
START=$CH3_START
END=$CH3_END
title=Empowered Decision Making

[CHAPTER]
TIMEBASE=1/1000
START=$CH4_START
END=$CH4_END
title=Communication That Builds Trust

[CHAPTER]
TIMEBASE=1/1000
START=$CH5_START
END=$CH5_END
title=Customer Obsessed Operations

[CHAPTER]
TIMEBASE=1/1000
START=$CH6_START
END=$CH6_END
title=Operational Impact

[CHAPTER]
TIMEBASE=1/1000
START=$CH7_START
END=$CH7_END
title=Ownership Commitments & Wrap-Up

[CHAPTER]
TIMEBASE=1/1000
START=$CH8_START
END=$CH8_END
title=Outro
FFMETA

ffmpeg -y -loglevel warning -stats \
  -i "$OPENER" \
  -i "$WORKDIR/content.mp4" \
  -i "$OUTRO" \
  -i "$WORKDIR/chapters.txt" \
  -filter_complex "
    [0:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v0];
    [0:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a0];
    [1:v]settb=1/24,fps=24,format=yuv420p[vcontent];
    [1:a]asetpts=PTS-STARTPTS[acontent];
    [2:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v_outro];
    [2:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a_outro];

    [v0][vcontent]xfade=transition=fade:duration=1:offset=$OPENER_XF_OFFSET[v_with_opener];
    [v_with_opener]settb=1/24,fps=24[v_norm];
    [v_norm][v_outro]xfade=transition=fade:duration=1:offset=$OUTRO_XF_OFFSET[vout];

    [a0][acontent]acrossfade=d=1:c1=tri:c2=tri[a_with_opener];
    [a_with_opener][a_outro]acrossfade=d=1:c1=tri:c2=tri[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -map_chapters 3 \
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
