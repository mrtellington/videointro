# Whitestone Video Intro — Project Handoff

## Repo
**GitHub:** `github.com/mrtellington/videointro`
**Local:** `~/videointro`

---

## What This Project Does

Generates branded video openers, outros, and fully edited summit recordings for Whitestone. Built on **Remotion** (React video) + **FFmpeg** (editing/assembly).

---

## Project Structure

```
videointro/
├── src/
│   ├── Root.tsx                 # All Remotion compositions
│   ├── Opener.tsx               # 20s opener (stone → logo → title)
│   ├── Outro.tsx                # 18s outro (Thank You → logo → stone → CRT off)
│   ├── NoteSlide.tsx            # 5s informational text card
│   └── components/
│       ├── StoneIcon.tsx        # Animated 3-path Whitestone stone
│       ├── FullLogo.tsx         # Full Whitestone logo (stone + wordmark)
│       └── TitleCard.tsx        # Title/subtitle/date text block
├── public/
│   ├── stone.svg                # Solo stone icon
│   ├── full-logo.svg            # Full Whitestone logo
│   ├── method-man.mp3           # Opener music (Wu-Tang)
│   ├── vivrant-thing.mp3        # Outro music (J Dilla)
│   └── vivrant-thing-lp.mp3    # Bass-only version for outro ending
├── render.sh                    # Render opener only
├── render-all.sh                # Render opener + outro with matching props
├── render-outro.sh              # Render outro only
├── edit-summit.sh               # Day 1 full edit (3-pass pipeline)
├── edit-summit-day2.sh          # Day 2 full edit (with note slide)
├── edit-hotspots.sh             # Hot Spots standalone edit
├── split-day1.sh                # Day 1 → 6 individual session videos
└── work/                        # Intermediate files (not committed)
```

---

## Compositions (Remotion)

| ID | Duration | Props | Description |
|----|----------|-------|-------------|
| `Opener` | 20s (600f) | title, subtitle, date, music? | Stone → logo → title card, Method Man |
| `Outro` | 18s (540f) | title, subtitle, date, music? | Thank You → logo → pulsing stone → CRT off, J Dilla |
| `NoteSlide` | 5s (150f) | message | Branded text card (used for Day 2 late-start notice) |

### Animation Style
- All transitions are **shrink/grow from center** (scale 0↔1) — no slides or spins
- Beat pulse on stone/text (~92 BPM opener, ~100 BPM outro)
- Outro music ending: full mix crossfades to bass-only (150Hz lowpass) in last 3s

---

## Quick Commands

### Render opener + outro for a new event
```bash
cd ~/videointro
./render-all.sh "Session Title" "Event Subtitle" "Day X · Date" output-name
# → out/output-name-opener.mp4 + out/output-name-outro.mp4
```

### Preview in browser
```bash
npm run studio
# Opens Remotion Studio at localhost:3000
```

### Re-render Day 1 full edit
```bash
./edit-summit.sh
# → out/opssummit1.mp4 (~25 min render)
```

### Re-render Day 1 split sessions
```bash
./split-day1.sh
# → out/day1-welcome.mp4, day1-decision-making.mp4, etc. (~37 min)
```

### Re-render Day 2 full edit
```bash
./edit-summit-day2.sh
# → out/opssummit2.mp4 (~30 min render)
```

### Re-render Hot Spots
```bash
./edit-hotspots.sh
# → out/hotspots.mp4 (~1 min render)
```

---

## Rendered Files (local: ~/videointro/out/)

### Full Summit Recordings
| File | Content | Duration | Size |
|------|---------|----------|------|
| `opssummit1.mp4` | Day 1 full edit (7 chapters + intro/outro) | ~2h 50m | 777 MB |
| `opssummit2.mp4` | Day 2 full edit (14 chapters + intro/outro + note) | ~3h 48m | 997 MB |

### Day 1 Individual Sessions
| File | Session | Duration |
|------|---------|----------|
| `day1-welcome.mp4` | Welcome & Framing | ~35 min |
| `day1-decision-making.mp4` | Empowered Decision Making | ~7 min |
| `day1-communication.mp4` | Communication That Builds Trust | ~15 min |
| `day1-customer-ops.mp4` | Customer Obsessed Operations | ~7 min |
| `day1-operational-impact.mp4` | Operational Impact | ~39 min |
| `day1-ownership.mp4` | Ownership Commitments & Wrap-Up | ~67 min |

### Standalone
| File | Content | Duration |
|------|---------|----------|
| `hotspots.mp4` | "Hot Spots" Activity Summary (pillarboxed) | ~11 min |

---

## GitHub Branches

| Branch | Content |
|--------|---------|
| `main` | Source code + all edit scripts |
| `render/opssummit1` | Day 1 full edit (LFS) |
| `render/opssummit2` | Day 2 full edit (LFS) |
| `render/summit-day1` | Day 1 opener only |
| `render/summit-day1-no-music` | Day 1 opener, silent |
| `render/outro` | Outro with music |
| `render/outro-no-music` | Outro, silent |

---

## Edit Pipeline Architecture

Each edit script follows a multi-pass approach:

1. **Pass 0** (optional): Word-level audio edits (micro-crossfade splices)
2. **Pass 1**: Build content chain — extract segments from source, apply crossfades (2s dissolves), studio sound
3. **Pass 2**: Sandwich opener + content + outro with 1s crossfades, embed chapter markers

### Studio Sound Processing
Applied to meeting audio only (not opener/outro music):
- 80Hz highpass (rumble removal)
- FFT noise reduction
- Low-mid EQ cut (-3dB @ 180Hz)
- Presence boost (+3dB @ 3.5kHz)
- Compression (3:1 @ -20dB threshold)
- Loudnorm (-14 LUFS) — *removed for Loom-targeted encodes*

### Loom Compatibility
Loom applies its own audio normalization. For Loom uploads:
- Remove `loudnorm` from audio filter chain
- Use `volume=1.5` on opener/outro music instead
- AAC-LC profile, 128k bitrate
- See `edit-hotspots.sh` for the Loom-friendly pattern

---

## How to Create a New Event Video

1. **Render bookends:**
   ```bash
   ./render-all.sh "Session Name" "Event Series" "Day X · Date" my-event
   ```

2. **Write an edit script** — copy `edit-hotspots.sh` as a template for simple videos, or `edit-summit.sh` for complex multi-segment edits with trims

3. **Key variables to set:**
   - `SRC` — path to source recording
   - Segment timestamps (`S1_START`, `S1_DUR`, etc.)
   - Crossfade duration (`XF=2` for 2s dissolves)
   - Chapter metadata

4. **Run and verify:**
   ```bash
   ./edit-my-event.sh
   open out/my-event.mp4
   ```

---

## Known Issues / Notes

- **Loom audio**: Loom re-normalizes audio and can make music too quiet. Use the Loom-friendly encode pattern (no loudnorm, volume boost on music, AAC-LC 128k)
- **Git branch switching**: `out/` is gitignored, so switching to render branches deletes local MP4s. Always `cp` to `/tmp/` before branch operations
- **Word edit timestamps**: The splice at ~36s in Day 1 Welcome & Framing uses approximate timestamps. Adjust `WE_END`, `SPEND_START`, `OF_END`, `TIME_START` in the scripts if the edit sounds off
- **Day 1 split videos** still use -14 LUFS loudnorm on music. If uploading to Loom, update `split-day1.sh` with the Loom-friendly audio pattern
- **Git LFS required** for pushing rendered videos >100MB to GitHub
