# Handoff: Ops Summit Day 1 — Welcome & Framing Edits

## Session Metadata
- Created: 2026-04-08 13:04:55
- Project: /Users/todellington/videointro
- Branch: main
- Session duration: ~3 hours

### Recent Commits (for context)
  - d45e093 Add project handoff document
  - 7d04ec1 Loom-friendly audio: remove loudnorm, AAC-LC, volume boost for music
  - b9f0140 Add edit-hotspots.sh: Hot Spots Activity Summary with pillarbox
  - e5c0239 Add split-day1.sh: 6 individual session videos with custom openers
  - de1ec4a Add Day 2 edit: NoteSlide component, 14 chapters, 3 segments

## Handoff Chain

- **Continues from**: None (fresh start)
- **Supersedes**: None

> This is the first handoff for this task.

## Current State Summary

We switched the Day 1 editing pipeline to use `out/opssummit1.mp4` as the source (already processed/mastered) instead of raw recording. The first session — "Welcome & Framing" — is complete: three filler phrases were surgically removed using 4-segment FFmpeg extraction with 60ms crossfades, then assembled with a branded opener/outro into `out/day1-v2-welcome.mp4` (61MB, ~16:24). Animation improvements were also applied: stone pulse intensity raised from 0.05 to 0.18 in both Opener.tsx and Outro.tsx, and the title/text screen pulse was removed from the Outro. The video was opened for user review but no feedback was received before this handoff. Remaining 5 sessions still need timestamps from the user.

## Codebase Understanding

### Architecture Overview

The project has two layers:
1. **Remotion (React)** — renders branded opener (20s) and outro (18s) for each session as `.mp4` files. Components: `Opener.tsx`, `Outro.tsx`, `StoneIcon.tsx`, `FullLogo.tsx`, `TitleCard.tsx`.
2. **FFmpeg shell scripts** — extract content segments from source video and assemble final output by concatenating opener + content + outro with 1s crossfades.

The `split-day1-v2.sh` script is the active pipeline. It uses helper functions `render_bookends()`, `extract_segment()`, and `assemble()`. All Day 1 sections will be added to this single script.

### Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `split-day1-v2.sh` | Main editing script for Day 1 re-split | Add new sections here |
| `src/Opener.tsx` | Branded opener (20s) — stone → logo → title card | Stone pulse = 0.18, no logo pulse |
| `src/Outro.tsx` | Branded outro (18s) — thank you → logo → stone → CRT off | Stone pulse = 0.18, title screen NO pulse |
| `out/opssummit1.mp4` | Fully processed Day 1 source (audio mastered) | All timestamps are relative to THIS file |
| `out/day1-v2-welcome.mp4` | Completed Welcome & Framing output | 61MB, 984.333s |
| `work/day1-v2/` | Working directory for intermediate files | welcome-content.mp4, welcome-opener.mp4, welcome-outro.mp4 |

### Key Patterns Discovered

- **Timestamp origin**: All timestamps in `split-day1-v2.sh` are relative to `opssummit1.mp4`. The raw recording timestamps are NOT used — the user provides start/end times directly in opssummit1 space.
- **Word-level editing**: Use multiple `-ss`/`-t` inputs to FFmpeg with chained `xfade`/`acrossfade` at `XF=0.06` (60ms). Very short crossfade conceals the cut while preventing audio clicks.
- **Assembly pipeline**: loudnorm (`I=-14:LRA=7:TP=-2`) applied in assemble step to all 3 streams (opener, content, outro). NOT applied during extraction. `-t "$FINAL_DUR"` hard cap prevents xfade PTS corruption that shows wrong duration in players.
- **Outro crossfade offset**: `OUTRO_OFFSET = 20 + CONTENT_DUR - 1 - 1` (opener 20s, minus 2 × 1s crossfade overlap).
- **Remotion render**: `npx remotion render Opener/Outro` with `--props` JSON containing title/subtitle/date.

## Work Completed

### Tasks Finished

- [x] Fix Outro.tsx — remove beat pulse from title screen, keep only on stone (frames 360–470)
- [x] Fix Opener.tsx — increase stone pulse multiplier from 0.05 to 0.18
- [x] Fix Outro.tsx — increase stone pulse multiplier from 0.05 to 0.18
- [x] Build `split-day1-v2.sh` with new pipeline (opssummit1.mp4 as source, loudnorm on all streams, `-t` hard cap)
- [x] Welcome & Framing: extract 20s→974s with 3 word edits, assemble with opener/outro → `out/day1-v2-welcome.mp4`
- [x] Fix container duration bug (was showing 2:49:10; fixed with `-t "$FINAL_DUR"`)
- [x] Fix audio volume imbalance (opener quieter; fixed with loudnorm on content stream)
- [x] Save animation standards to memory (`videointro-animation-standards.md`)

### Files Modified

| File | Changes | Rationale |
|------|---------|-----------|
| `src/Opener.tsx` | Stone pulse multiplier 0.05 → 0.18 | More dramatic effect, user confirmed |
| `src/Outro.tsx` | Remove text phase pulse; stone pulse multiplier 0.05 → 0.18 | Text pulse was distracting; stone pulse needs to match opener |
| `split-day1-v2.sh` | New script replacing split-day1.sh | New pipeline: opssummit1 as source, loudnorm in assemble, `-t` hard cap, word edits for Welcome |

### Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| Use opssummit1.mp4 as source | Raw recording vs processed file | Avoids re-processing already-mastered audio; original split-day1.sh had bad alignment |
| loudnorm in assemble, not extract | During extract vs during assemble | Assemble normalizes all 3 streams together for consistent volume across opener/content/outro |
| `-t "$FINAL_DUR"` hard cap | None vs cap | xfade can corrupt PTS metadata; hard cap forces correct container duration |
| 60ms (0.06s) word-edit crossfade | 0s cut vs short crossfade | Hard cuts at word boundaries create audio clicks; 60ms is imperceptible but smooth |
| Stone pulse = 0.18 | 0.05 (too subtle) vs 0.18 | User reviewed and confirmed 0.18 as right balance |

## Pending Work

### Immediate Next Steps

1. **Get user confirmation on Welcome & Framing** — video is at `out/day1-v2-welcome.mp4`; user was reviewing when session ended
2. **Add remaining Day 1 sections to split-day1-v2.sh** — user needs to provide start/end timestamps for each:
   - Empowered Decision Making
   - Communication That Builds Trust
   - Customer Obsessed Operations
   - Operational Impact
   - Ownership Commitments & Wrap-Up
3. **Run script for each new section** — follow same pattern: `render_bookends()` + extract with any word edits + `assemble()`

### Blockers/Open Questions

- [ ] User must provide opssummit1.mp4 timestamps for remaining 5 sections
- [ ] User has not confirmed Welcome & Framing output is acceptable (review was in progress)

### Deferred Items

- No Day 2 work in scope for this task — Day 2 already handled in separate script/session

## Context for Resuming Agent

### Important Context

**The source file is `out/opssummit1.mp4` — all timestamps are relative to this file, not the raw recording.**

The Welcome & Framing section covers frames 20s–974s in opssummit1.mp4 (16:14 in player = 974s). Three phrases were removed:
- Cut 1: 28.0 → 32.0 — "um, thinking about how we can make operations great and,"
- Cut 2: 35.5 → 36.0 — "'re gonna" (turned "we're gonna" into "we")
- Cut 3: 45.0 → 46.0 — "uh, or we do that now"

This produces 4 segments: (20→28), (32→35.5), (36→45), (46→974).

The `assemble()` function in the script applies loudnorm to all 3 streams. Do NOT add loudnorm during extraction — it's already done in assemble.

Animation standards (already in memory file `videointro-animation-standards.md`):
- Opener stone pulse: `1 + beatPulse * 0.18` (frames 60–200)
- Outro stone pulse: `1 + beatPulse * 0.18` (frames 360–470)
- Title/text screens: NO pulse — static hold

### Assumptions Made

- User will provide timestamps in MM:SS or HH:MM:SS format relative to opssummit1.mp4 player position
- Each session gets its own slug and title (same subtitle/date as Welcome section)
- No further word edits unless user specifies — just clean in/out cuts

### Potential Gotchas

- **Never add loudnorm to the extract step** — it belongs in assemble only, applied to all 3 streams
- **Always include `-t "$FINAL_DUR"`** in the assemble ffmpeg command or the output duration will be wrong in QuickTime
- **The `assemble()` function is already in the script** — just add new sections calling `render_bookends`, extract, and `assemble`
- **Remotion render takes ~2–3 minutes per opener/outro** — opener and outro can render in parallel if needed
- **SD_DUR calculation**: last segment duration = section_end_time - last_cut_end. For Welcome it was 974 - 46 = 928s

## Environment State

### Tools/Services Used

- FFmpeg (local install, no drawtext/libfreetype — workaround: VLC E key for frame stepping)
- Remotion (npx remotion render)
- Node.js / npm for Remotion

### Active Processes

- None

### Environment Variables

- None required beyond standard PATH

## Related Resources

- `split-day1-v2.sh` — the script to extend with new sections
- `out/opssummit1.mp4` — source for all Day 1 sections
- `src/Opener.tsx`, `src/Outro.tsx` — animation components (do not change pulse values)
- Memory: `videointro-animation-standards.md` — canonical animation settings

---

**Security Reminder**: Before finalizing, run `validate_handoff.py` to check for accidental secret exposure.
