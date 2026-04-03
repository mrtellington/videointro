import React from "react";
import {
  AbsoluteFill,
  Audio,
  interpolate,
  Sequence,
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

// ─── 12s (360 frames @ 30fps) — reverse mirror of intro ─────────────────
// 0–1.5s:   "Thank You!" crashes up from below (kinetic, big)
// 0.8–2.2s: Title / subtitle / date context fades in below
// 2.2–5s:   Hold with beat pulse (~100 BPM)
// 4.7–6.2s: Text flies out to the right (kinetic exit)
// 5.7–7.7s: Full Whitestone logo slams in from above
// 7.3–8.8s: Logo cross-dissolves into solo stone
// 8.5–12s:  Stone pulses with the beat
// 12s:      Hard cut on a beat

export const Outro: React.FC<OutroProps> = ({
  title,
  subtitle,
  date,
  music = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Beat pulse (~100 BPM ≈ 18 frames per beat at 30fps) ──
  const BEAT = 18;
  const beatFrame = frame % BEAT;
  const beatPulse = spring({
    frame: beatFrame,
    fps,
    config: { damping: 5, stiffness: 1200, mass: 0.08 },
  });

  // ── Phase 1: "Thank You!" crashes up from below ──
  const tyEnter = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 700, mass: 0.45 },
  });
  const tyY = interpolate(tyEnter, [0, 1], [150, 0]);
  const tyScale = interpolate(tyEnter, [0, 0.5, 1], [0.85, 1.05, 1]);

  // ── Phase 2: Context fades in (staggered below Thank You) ──
  const ctxProgress = spring({
    frame: frame - 25,
    fps,
    config: { damping: 16, stiffness: 400, mass: 0.5 },
  });
  const ctxY = interpolate(ctxProgress, [0, 1], [40, 0]);
  const ctxOpacity = interpolate(frame, [25, 50], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Phase 3: Text beat pulse during hold ──
  const inTextPulse = frame >= 65 && frame < 140;
  const textPulse = inTextPulse ? 1 + beatPulse * 0.03 : 1;

  // ── Phase 4: Text flies out right ──
  const textExit = spring({
    frame: frame - 140,
    fps,
    config: { damping: 22, stiffness: 700, mass: 0.5 },
  });
  const textExitX = interpolate(textExit, [0, 1], [0, 1500]);
  const textExitRotate = interpolate(textExit, [0, 1], [0, 25]);
  const textOpacity = interpolate(frame, [0, 5, 140, 185], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Phase 5: Full logo slams in from above ──
  const logoEnter = spring({
    frame: frame - 170,
    fps,
    config: { damping: 12, stiffness: 260, mass: 0.95 },
  });
  const logoSlideY = interpolate(logoEnter, [0, 1], [-380, 0]);
  const logoSlideScale = interpolate(logoEnter, [0, 1], [0.5, 1]);
  const logoOpacity = interpolate(frame, [170, 200, 230, 265], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Phase 6: Stone appears as logo fades ──
  const stoneOpacity = interpolate(frame, [230, 260], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const inStonePulse = frame >= 270;
  const stonePulse = inStonePulse ? 1 + beatPulse * 0.05 : 1;

  return (
    <AbsoluteFill style={{ background: "#0e1237" }}>
      {music && <Audio src={staticFile("vivrant-thing.mp3")} />}

      {/* ── Text phase: Thank You + context ── */}
      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          opacity: textOpacity,
          transform: `translateX(${textExitX}px) translateY(${tyY}px) scale(${tyScale * textPulse}) rotate(${textExitRotate}deg)`,
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

        {/* Event context below */}
        <div
          style={{
            opacity: ctxOpacity,
            transform: `translateY(${ctxY}px)`,
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
              letterSpacing: "0.5px",
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

      {/* ── Logo phase: slams in from above, cross-dissolves out ── */}
      <AbsoluteFill
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          opacity: logoOpacity,
          transform: `translateY(${logoSlideY}px) scale(${logoSlideScale})`,
        }}
      >
        <FullLogo />
      </AbsoluteFill>

      {/* ── Stone phase: fades in as logo fades, pulses to the beat ── */}
      <AbsoluteFill
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          opacity: stoneOpacity,
          transform: `scale(${stonePulse})`,
        }}
      >
        <Sequence from={230}>
          <StoneIcon />
        </Sequence>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
