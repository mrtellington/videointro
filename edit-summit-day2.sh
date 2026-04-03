#!/bin/bash
set -e

# ─── Operations Summit Day 2 — Full Edit Pipeline ──────────────────────────
#
# Opener (20s) → Note slide (5s) → Content → Outro (18s)
#
# Content: 3 segments, 2 crossfades
#   Seg1: 0 → 1:03:41      — Operational Flow, People Ops, Marketing
#   [2s xfade — break removed: 1:03:41 → 1:19:23]
#   Seg2: 1:19:23 → 2:18:16 — Creative Process, Production, Compliance, Game start
#   [2s xfade — game cut: 2:18:16 → 2:20:23]
#   Seg3: 2:20:23 → 4:04:48 — Game cont., Enterprise, Brand, Finance, Tech, Ownership, Announcements
#
# 14 chapter markers at department boundaries

SRC="/Users/todellington/Downloads/Operations Summit_ The Engine behind the Experience Day 2 - 2026_03_25 09_53 EDT - Recording.mp4"
OPENER="/Users/todellington/videointro/out/summit-day2-opener.mp4"
NOTE="/Users/todellington/videointro/out/summit-day2-note.mp4"
OUTRO="/Users/todellington/videointro/out/summit-day2-outro.mp4"
OUTPUT="/Users/todellington/videointro/out/opssummit2.mp4"
WORKDIR="/Users/todellington/videointro/work"

mkdir -p "$WORKDIR"

echo "════════════════════════════════════════════════════════════"
echo " Operations Summit Day 2 — Full Edit"
echo "════════════════════════════════════════════════════════════"
START_TIME=$(date +%s)

# ════════════════════════════════════════════════════════════════════════════
# PASS 1: Build content chain (3 segments + 2 crossfades + studio sound)
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "Pass 1: Building content chain..."

# Segment timestamps (seconds)
S1_START=0;    S1_DUR=3821     # 0 → 1:03:41
S2_START=4763; S2_DUR=3533     # 1:19:23 → 2:18:16
S3_START=8423; S3_DUR=6265     # 2:20:23 → 4:04:48
XF=2

# xfade offsets
XO1=$(echo "$S1_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CUM1=$(echo "$S1_DUR + $S2_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
XO2=$(echo "$CUM1 - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')
CONTENT_EST=$(echo "$CUM1 + $S3_DUR - $XF" | bc | sed 's/^\./0./;s/^-\./-0./')

echo "  Segments: ${S1_DUR}s | ${S2_DUR}s | ${S3_DUR}s"
echo "  xfade offsets: $XO1 | $XO2"
echo "  Content est: ${CONTENT_EST}s"

ffmpeg -y -loglevel warning -stats \
  -ss $S1_START -t $S1_DUR -i "$SRC" \
  -ss $S2_START -t $S2_DUR -i "$SRC" \
  -ss $S3_START -t $S3_DUR -i "$SRC" \
  -filter_complex "
    [0:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v1];
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a1];
    [1:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v2];
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a2];
    [2:v]fps=24,format=yuv420p,setpts=PTS-STARTPTS[v3];
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo,asetpts=PTS-STARTPTS[a3];

    [v1][v2]xfade=transition=fade:duration=$XF:offset=$XO1[xv1];
    [xv1][v3]xfade=transition=fade:duration=$XF:offset=$XO2[vout];

    [a1][a2]acrossfade=d=$XF:c1=tri:c2=tri[xa1];
    [xa1][a3]acrossfade=d=$XF:c1=tri:c2=tri[a_raw];
    [a_raw]highpass=f=80,afftdn=nt=w:om=o,equalizer=f=180:t=q:w=1:g=-3,equalizer=f=3500:t=q:w=1.5:g=3,acompressor=threshold=-20dB:ratio=3:attack=10:release=200,loudnorm=I=-14:LRA=7:TP=-2[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 20 \
  -c:a aac -ar 48000 -b:a 192k \
  "$WORKDIR/content.mp4"

CONTENT_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WORKDIR/content.mp4")
echo "  Content built: ${CONTENT_DUR}s"

# ════════════════════════════════════════════════════════════════════════════
# PASS 2: Opener (20s) + Note (5s) + Content + Outro (18s)
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "Pass 2: Adding opener + note + outro..."

# Opener (20s) hard-concat with Note (5s) = 25s opening sequence
# Then xfade (1s) into content at offset 24 (25-1)
# Then xfade (1s) into outro
OPEN_NOTE_DUR=25
CONTENT_XF_OFFSET=$(echo "$OPEN_NOTE_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
WITH_CONTENT_DUR=$(echo "$OPEN_NOTE_DUR + $CONTENT_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
OUTRO_XF_OFFSET=$(echo "$WITH_CONTENT_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
FINAL_DUR=$(echo "$WITH_CONTENT_DUR + 18 - 1" | bc | sed 's/^\./0./;s/^-\./-0./')
FINAL_MINS=$(echo "$FINAL_DUR / 60" | bc)

echo "  Content: ${CONTENT_DUR}s"
echo "  Content xfade offset: ${CONTENT_XF_OFFSET}"
echo "  Outro xfade offset: ${OUTRO_XF_OFFSET}"
echo "  Final duration: ~${FINAL_MINS}m"

# ── Chapter timestamps ──────────────────────────────────────────────────
# Content starts at OPEN_NOTE_DUR - 1 = 24s in the final video
# Seg1 original times map directly to content time
# Seg2 original times: content_time = orig - (S2_START - S1_DUR + XF) = orig - 944
# Seg3 original times: content_time = orig - (S3_START - CUM1 + XF) = orig - 1073
CONTENT_OFFSET=$(echo "$OPEN_NOTE_DUR - 1" | bc | sed 's/^\./0./;s/^-\./-0./')  # 24
SEG2_SHIFT=$(echo "$S2_START - $S1_DUR + $XF" | bc | sed 's/^\./0./;s/^-\./-0./')  # 944
SEG3_SHIFT=$(echo "$S3_START - $CUM1 + $XF" | bc | sed 's/^\./0./;s/^-\./-0./')    # 1075

# Chapter times in original → final (milliseconds)
ch_ms() {
  local orig=$1
  local shift=${2:-0}
  echo "($CONTENT_OFFSET + $orig - $shift) * 1000" | bc | sed 's/^\./0./;s/^-\./-0./' | cut -d. -f1
}

CH_INTRO_S=0
CH_INTRO_E=$(echo "($CONTENT_OFFSET - 0.001) * 1000" | bc | sed 's/^\./0./;s/^-\./-0./' | cut -d. -f1)
# Seg1 chapters (orig times, no shift)
CH_OPFLOW_S=$(ch_ms 0)
CH_PEOPLEOPS_S=$(ch_ms 1933)
CH_MARKETING_S=$(ch_ms 2900)
# Seg2 chapters (shift by SEG2_SHIFT)
CH_CREATIVE_S=$(ch_ms 4763 $SEG2_SHIFT)
CH_PRODUCTION_S=$(ch_ms 6305 $SEG2_SHIFT)
CH_COMPLIANCE_S=$(ch_ms 7047 $SEG2_SHIFT)
CH_GAME_S=$(ch_ms 8261 $SEG2_SHIFT)
# Seg3 chapters (shift by SEG3_SHIFT)
CH_ENTERPRISE_S=$(ch_ms 10160 $SEG3_SHIFT)
CH_BRAND_S=$(ch_ms 10987 $SEG3_SHIFT)
CH_FINANCE_S=$(ch_ms 11391 $SEG3_SHIFT)
CH_TECH_S=$(ch_ms 12289 $SEG3_SHIFT)
CH_OWNERSHIP_S=$(ch_ms 13050 $SEG3_SHIFT)
CH_ANNOUNCE_S=$(ch_ms 13459 $SEG3_SHIFT)
# Outro
CH_OUTRO_S=$(echo "($WITH_CONTENT_DUR - 1) * 1000" | bc | sed 's/^\./0./;s/^-\./-0./' | cut -d. -f1)
CH_OUTRO_E=$(echo "$FINAL_DUR * 1000" | bc | sed 's/^\./0./;s/^-\./-0./' | cut -d. -f1)

cat > "$WORKDIR/chapters.txt" << FFMETA
;FFMETADATA1

[CHAPTER]
TIMEBASE=1/1000
START=$CH_INTRO_S
END=$CH_INTRO_E
title=Intro

[CHAPTER]
TIMEBASE=1/1000
START=$CH_OPFLOW_S
END=$((CH_PEOPLEOPS_S - 1))
title=Operational Flow

[CHAPTER]
TIMEBASE=1/1000
START=$CH_PEOPLEOPS_S
END=$((CH_MARKETING_S - 1))
title=People Operations

[CHAPTER]
TIMEBASE=1/1000
START=$CH_MARKETING_S
END=$((CH_CREATIVE_S - 1))
title=Marketing

[CHAPTER]
TIMEBASE=1/1000
START=$CH_CREATIVE_S
END=$((CH_PRODUCTION_S - 1))
title=Creative Process

[CHAPTER]
TIMEBASE=1/1000
START=$CH_PRODUCTION_S
END=$((CH_COMPLIANCE_S - 1))
title=Production

[CHAPTER]
TIMEBASE=1/1000
START=$CH_COMPLIANCE_S
END=$((CH_GAME_S - 1))
title=Compliance & Logistics

[CHAPTER]
TIMEBASE=1/1000
START=$CH_GAME_S
END=$((CH_ENTERPRISE_S - 1))
title=Game

[CHAPTER]
TIMEBASE=1/1000
START=$CH_ENTERPRISE_S
END=$((CH_BRAND_S - 1))
title=Enterprise Solutions

[CHAPTER]
TIMEBASE=1/1000
START=$CH_BRAND_S
END=$((CH_FINANCE_S - 1))
title=Brand

[CHAPTER]
TIMEBASE=1/1000
START=$CH_FINANCE_S
END=$((CH_TECH_S - 1))
title=Finance

[CHAPTER]
TIMEBASE=1/1000
START=$CH_TECH_S
END=$((CH_OWNERSHIP_S - 1))
title=Technology

[CHAPTER]
TIMEBASE=1/1000
START=$CH_OWNERSHIP_S
END=$((CH_ANNOUNCE_S - 1))
title=Ownership Commitments

[CHAPTER]
TIMEBASE=1/1000
START=$CH_ANNOUNCE_S
END=$((CH_OUTRO_S - 1))
title=Announcements

[CHAPTER]
TIMEBASE=1/1000
START=$CH_OUTRO_S
END=$CH_OUTRO_E
title=Outro
FFMETA

ffmpeg -y -loglevel warning -stats \
  -i "$OPENER" \
  -i "$NOTE" \
  -i "$WORKDIR/content.mp4" \
  -i "$OUTRO" \
  -i "$WORKDIR/chapters.txt" \
  -filter_complex "
    [0:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v_opener];
    [0:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a_opener];
    [1:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v_note];
    [1:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS[a_note_raw];
    [a_note_raw]volume=0[a_note];
    [2:v]settb=1/24,fps=24,format=yuv420p[v_content];
    [2:a]asetpts=PTS-STARTPTS[a_content];
    [3:v]fps=24,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1,setsar=1,format=yuv420p,setpts=PTS-STARTPTS[v_outro];
    [3:a]aresample=48000,aformat=channel_layouts=stereo,asetpts=PTS-STARTPTS,loudnorm=I=-14:LRA=7:TP=-2[a_outro];

    [v_opener][v_note]concat=n=2:v=1:a=0,settb=1/24,fps=24[v_opening];
    [a_opener][a_note]concat=n=2:v=0:a=1[a_opening];

    [v_opening][v_content]xfade=transition=fade:duration=1:offset=$CONTENT_XF_OFFSET[v_with_content];
    [v_with_content]settb=1/24,fps=24[v_norm];
    [v_norm][v_outro]xfade=transition=fade:duration=1:offset=$OUTRO_XF_OFFSET[vout];

    [a_opening][a_content]acrossfade=d=1:c1=tri:c2=tri[a_with_content];
    [a_with_content][a_outro]acrossfade=d=1:c1=tri:c2=tri[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -map_chapters 4 \
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
