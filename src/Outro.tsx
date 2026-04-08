import React from "react";
import {
  AbsoluteFill,
  Audio,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Figtree";
import { StoneIcon } from "./components/StoneIcon";
import { FullLogo } from "./components/FullLogo";

loadFont("normal", { weights: ["300", "400", "600", "800"] });
const { fontFamily } = loadFont("normal");

export type OutroProps = {
  title: string;
  subtitle: string;
  date: string;
  music?: boolean;
};

// ─── 18s (540 frames @ 30fps) — reverse mirror of intro ─────────────────
//
//  0–1.3s  (0–40f):    "Thank You!" grows from center
//  0.7–1.8s (20–55f):  Context (title/subtitle/date) fades in below
//  1.8–5.3s (55–160f): Hold with beat pulse
//  5.2–6.5s (155–195f):All text shrinks to 0 from center
//  6.3–8.3s (190–250f):Full logo grows from center
//  8.2–9.7s (245–290f):Logo shrinks to 0 from center
//  9.5–11s  (285–330f):Solo stone grows from center (paths spring in)
//  11–12s   (330–360f):Stone sits still, centered (moment of calm)
//  12–15.3s (360–460f):Stone pulses to beat
//  15–16.5s (450–495f):Music: full mix fades out → bass/kick only
//  15.8–16.8s(475–505f):Stone shrinks to 0
//  16.8–17.8s(505–535f):CRT screen-off effect
//  18s      (540f):     End

export const Outro: React.FC<OutroProps> = ({
  title,
  subtitle,
  date,
  music = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Beat pulse (~100 BPM ≈ 18 frames per beat) ──
  const BEAT = 18;
  const beatFrame = frame % BEAT;
  const beatPulse = spring({
    frame: beatFrame,
    fps,
    config: { damping: 5, stiffness: 1200, mass: 0.08 },
  });

  // ════════════════════════════════════════════════════════════════════════
  // TEXT PHASE: "Thank You!" + context
  // ════════════════════════════════════════════════════════════════════════

  // Grow in from center
  const textGrow = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 700, mass: 0.45 },
  });
  const textGrowScale = interpolate(textGrow, [0, 1], [0, 1]);

  // Context staggers in
  const ctxProgress = spring({
    frame: frame - 20,
    fps,
    config: { damping: 16, stiffness: 400, mass: 0.5 },
  });
  const ctxScale = interpolate(ctxProgress, [0, 1], [0.5, 1]);
  const ctxOpacity = interpolate(frame, [20, 50], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Text shrinks to 0 from center
  const textShrink = spring({
    frame: frame - 155,
    fps,
    config: { damping: 20, stiffness: 400, mass: 0.6 },
  });
  const textShrinkScale = interpolate(textShrink, [0, 1], [1, 0]);

  // Combined text scale (no beat pulse — pulse stays on stone only)
  const textVisible = frame < 195;
  const textScale = textVisible
    ? textGrowScale * textShrinkScale
    : 0;
  const textOpacity = frame < 195 ? 1 : 0;

  // ════════════════════════════════════════════════════════════════════════
  // LOGO PHASE: grows from center, then shrinks
  // ════════════════════════════════════════════════════════════════════════

  const logoGrow = spring({
    frame: frame - 190,
    fps,
    config: { damping: 13, stiffness: 300, mass: 0.8 },
  });
  const logoGrowScale = interpolate(logoGrow, [0, 1], [0, 1]);

  const logoShrink = spring({
    frame: frame - 245,
    fps,
    config: { damping: 20, stiffness: 400, mass: 0.6 },
  });
  const logoShrinkScale = interpolate(logoShrink, [0, 1], [1, 0]);

  const logoVisible = frame >= 190 && frame < 295;
  const logoScale = logoVisible ? logoGrowScale * logoShrinkScale : 0;

  // ════════════════════════════════════════════════════════════════════════
  // STONE PHASE: grows from center, sits, pulses, then shrinks
  // ════════════════════════════════════════════════════════════════════════

  // Stone grows in (paths spring via startFrame prop)
  const stoneEnter = spring({
    frame: frame - 285,
    fps,
    config: { damping: 13, stiffness: 280, mass: 0.8 },
  });
  const stoneEnterScale = interpolate(stoneEnter, [0, 1], [0, 1]);

  // Stone pulse during beat section
  const inStonePulse = frame >= 360 && frame < 470;
  const stonePulse = inStonePulse ? 1 + beatPulse * 0.18 : 1;

  // Stone shrinks to 0
  const stoneShrink = spring({
    frame: frame - 475,
    fps,
    config: { damping: 25, stiffness: 600, mass: 0.4 },
  });
  const stoneShrinkScale = interpolate(stoneShrink, [0, 1], [1, 0]);

  const stoneVisible = frame >= 285 && frame < 510;
  const stoneScale = stoneVisible
    ? stoneEnterScale * stonePulse * stoneShrinkScale
    : 0;

  // ════════════════════════════════════════════════════════════════════════
  // SCREEN-OFF EFFECT: CRT collapse after stone disappears
  // ════════════════════════════════════════════════════════════════════════

  const screenOffActive = frame >= 505;
  const offProgress = spring({
    frame: frame - 505,
    fps,
    config: { damping: 30, stiffness: 800, mass: 0.3 },
  });
  // Squash vertically to a line, then horizontally to a point
  const screenScaleY = screenOffActive
    ? interpolate(offProgress, [0, 0.4, 1], [1, 0.003, 0])
    : 1;
  const screenScaleX = screenOffActive
    ? interpolate(offProgress, [0, 0.4, 1], [1, 1, 0])
    : 1;
  // Brightness flash during the collapse
  const screenBrightness = screenOffActive
    ? interpolate(offProgress, [0, 0.2, 0.5, 1], [1, 1.8, 1.5, 0])
    : 1;

  // ════════════════════════════════════════════════════════════════════════
  // AUDIO: Full mix crossfades to bass-only in last 3s
  // ════════════════════════════════════════════════════════════════════════

  const fullMixVolume = (f: number) => {
    if (f < 450) return 1;
    if (f > 495) return 0;
    return 1 - (f - 450) / 45;
  };

  const bassVolume = (f: number) => {
    if (f < 435) return 0;
    if (f < 470) return (f - 435) / 35; // fade in
    if (f > 505) return 0;
    return 1 - (f - 470) / 35; // fade out
  };

  return (
    <AbsoluteFill style={{ background: "black" }}>
      {/* Audio layers */}
      {music && (
        <>
          <Audio src={staticFile("vivrant-thing.mp3")} volume={fullMixVolume} />
          <Audio src={staticFile("vivrant-thing-lp.mp3")} volume={bassVolume} />
        </>
      )}

      {/* All visual content — affected by screen-off */}
      <AbsoluteFill
        style={{
          background: "#0e1237",
          transform: `scaleY(${screenScaleY}) scaleX(${screenScaleX})`,
          filter: `brightness(${screenBrightness})`,
        }}
      >
        {/* ── Text: Thank You + context ── */}
        {textVisible && (
          <AbsoluteFill
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              transform: `scale(${textScale})`,
              opacity: textOpacity,
              fontFamily,
              textAlign: "center",
            }}
          >
            <div
              style={{
                fontSize: 160,
                fontWeight: 800,
                color: "#ffffff",
                letterSpacing: "-3px",
                lineHeight: 1.0,
              }}
            >
              Thank You!
            </div>

            <div
              style={{
                opacity: ctxOpacity,
                transform: `scale(${ctxScale})`,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                marginTop: 32,
              }}
            >
              <div
                style={{
                  fontSize: 42,
                  fontWeight: 600,
                  color: "#00b6bf",
                }}
              >
                {title}
              </div>
              <div
                style={{
                  fontSize: 32,
                  fontWeight: 400,
                  color: "rgba(255,255,255,0.7)",
                  marginTop: 12,
                }}
              >
                {subtitle}
              </div>
              <div
                style={{
                  fontSize: 24,
                  fontWeight: 300,
                  color: "rgba(255,255,255,0.45)",
                  marginTop: 16,
                  letterSpacing: "4px",
                  textTransform: "uppercase",
                }}
              >
                {date}
              </div>
            </div>
          </AbsoluteFill>
        )}

        {/* ── Logo: grows then shrinks from center ── */}
        {logoVisible && (
          <AbsoluteFill
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              transform: `scale(${logoScale})`,
            }}
          >
            <FullLogo />
          </AbsoluteFill>
        )}

        {/* ── Stone: grows, sits, pulses, shrinks — centered ── */}
        {stoneVisible && (
          <AbsoluteFill
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              transform: `scale(${stoneScale})`,
            }}
          >
            <StoneIcon startFrame={285} />
          </AbsoluteFill>
        )}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
