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

loadFont("normal", { weights: ["300", "800"] });
const { fontFamily } = loadFont("normal");

export type OutroProps = {
  music?: boolean;
};

// ─── Phase timings (frames @ 30fps, 600 total = 20s) ──────────────────
//  0–12   (0–0.4s):  Background fades in
//  15–55  (0.5–1.8s):"Thank You" crashes up from below
//  55–200 (1.8–6.7s):"Thank You" holds with beat pulse
// 195–232 (6.5–7.7s):"Thank You" flies out to the right
// 220–295 (7.3–9.8s):Stone paths spring in (via <Sequence from={220}>)
// 280–345 (9.3–11.5s):Stone spins out
// 315–385 (10.5–12.8s):Full logo slams in from above
// 385–600 (12.8–20s): Logo holds
// 600:   Hard cut

export const Outro: React.FC<OutroProps> = ({ music = true }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Background fade
  const bgOpacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: "clamp",
  });

  // ── Beat pulse on "Thank You" ──
  const BEAT = 20;
  const beatFrame = frame % BEAT;
  const beatPulse = spring({
    frame: beatFrame,
    fps,
    config: { damping: 5, stiffness: 1200, mass: 0.08 },
  });
  const inPulsePhase = frame >= 55 && frame < 195;
  const tyPulse = inPulsePhase ? 1 + beatPulse * 0.04 : 1;

  // ── "Thank You" entrance: crashes up from below ──
  const tyEnter = spring({
    frame: frame - 15,
    fps,
    config: { damping: 14, stiffness: 700, mass: 0.45 },
  });
  const tyEnterY = interpolate(tyEnter, [0, 1], [150, 0]);
  const tyEnterScale = interpolate(tyEnter, [0, 0.5, 1], [0.85, 1.04, 1]);

  // ── "Thank You" exit: flies out to the right ──
  const tyExit = spring({
    frame: frame - 195,
    fps,
    config: { damping: 22, stiffness: 700, mass: 0.5 },
  });
  const tyExitX = interpolate(tyExit, [0, 1], [0, 1500]);
  const tyExitRotate = interpolate(tyExit, [0, 1], [0, 30]);
  const tyOpacity = interpolate(
    frame,
    [15, 22, 195, 232],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // ── Stone: spin exit ──
  const spinExit = spring({
    frame: frame - 280,
    fps,
    config: { damping: 20, stiffness: 280, mass: 0.9 },
  });
  const stoneSpinDeg = interpolate(spinExit, [0, 1], [0, 360]);
  const stoneExitScale = interpolate(spinExit, [0, 0.65, 1], [1, 0.9, 0]);
  const stoneOpacity = interpolate(
    frame,
    [220, 228, 280, 345],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Stone pulse during hold (220-280)
  const inStonePulse = frame >= 228 && frame < 280;
  const stonePulseScale = inStonePulse ? 1 + beatPulse * 0.05 : 1;

  // ── Full logo: slams in from above ──
  const logoEnter = spring({
    frame: frame - 315,
    fps,
    config: { damping: 12, stiffness: 260, mass: 0.95 },
  });
  const logoSlideY = interpolate(logoEnter, [0, 1], [-380, 0]);
  const logoSlideScale = interpolate(logoEnter, [0, 1], [0.5, 1]);
  const logoOpacity = interpolate(
    frame,
    [315, 342],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill style={{ background: "black" }}>
      <AbsoluteFill style={{ background: "#0e1237", opacity: bgOpacity }} />

      {music && <Audio src={staticFile("method-man.mp3")} />}

      <AbsoluteFill>
        {/* ── "Thank You" text ── */}
        <AbsoluteFill
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            opacity: tyOpacity,
            transform: `translateX(${tyExitX}px) translateY(${tyEnterY}px) scale(${tyEnterScale * tyPulse}) rotate(${tyExitRotate}deg)`,
            fontFamily,
            textAlign: "center",
          }}
        >
          <div
            style={{
              fontSize: 180,
              fontWeight: 800,
              color: "#ffffff",
              letterSpacing: "-4px",
              lineHeight: 1.0,
            }}
          >
            Thank You
          </div>
          <div
            style={{
              fontSize: 36,
              fontWeight: 300,
              color: "rgba(255,255,255,0.5)",
              letterSpacing: "8px",
              textTransform: "uppercase",
              marginTop: 28,
            }}
          >
            Whitestone
          </div>
        </AbsoluteFill>

        {/* ── Stone: uses <Sequence> so StoneIcon's internal frame starts at 0 ── */}
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: stoneOpacity,
            transform: `rotate(${stoneSpinDeg}deg) scale(${stoneExitScale * stonePulseScale})`,
          }}
        >
          <Sequence from={220}>
            <StoneIcon />
          </Sequence>
        </AbsoluteFill>

        {/* ── Full logo: slams in, holds to hard cut ── */}
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
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
