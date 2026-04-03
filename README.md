# Whitestone Video Opener

Remotion-based 20-second video opener generator for Whitestone recordings.

**Stack:** React + TypeScript via [Remotion](https://www.remotion.dev)  
**Output:** 1920×1080 MP4, ready for Loom / Descript  
**Font:** Figtree (via Google Fonts)  
**Audio:** Wu-Tang Clan – Method Man (Instrumental), starts at 0:00

---

## One-time setup

```bash
npm install
```

---

## Generate a new opener

```bash
./render.sh "Title" "Subtitle" "Date" output-filename
```

**Example — Day 1:**
```bash
./render.sh \
  "2026 Operations Summit" \
  "Engine Behind the Experience" \
  "Day 1  ·  March 24, 2026" \
  summit-day1
```

Output: `out/summit-day1.mp4`

---

## Preview / edit in browser

```bash
npm run studio
```

Opens Remotion Studio at http://localhost:3000 — live preview with scrubbing.

---

## Props reference

| Prop       | Description                        | Example                          |
|------------|------------------------------------|----------------------------------|
| `title`    | Main event/series name             | `2026 Operations Summit`         |
| `subtitle` | Session tagline or theme           | `Engine Behind the Experience`   |
| `date`     | Episode · date info                | `Day 1  ·  March 24, 2026`       |

---

## Animation timeline

| Time     | What happens                                      |
|----------|---------------------------------------------------|
| 0–2s     | Stone icon paths spring in (staggered, kinetic)   |
| 2–3.7s   | Cross-dissolve: stone → full Whitestone logo      |
| 3.7–9.3s | Logo holds center                                 |
| 9.3–10s  | Logo snaps up (spring physics)                    |
| 10–18s   | Title · subtitle · date slam in (staggered)       |
| 18–20s   | Fade to black                                     |

---

## Workflow: adding a new video

1. Run `./render.sh` with the new title/subtitle/date
2. Drop the MP4 into Loom or Descript at the start of your recording
3. Use the editor's crossfade/transition to blend into the meeting recording
