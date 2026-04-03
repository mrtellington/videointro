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
import { StoneIcon } from "./components/StoneIcon";
import { FullLogo } from "./components/FullLogo";
import { TitleCard } from "./components/TitleCard";

export type OpenerProps = {
  title: string;
  subtitle: string;
  date: string;
};

export const Opener: React.FC<OpenerProps> = ({ title, subtitle, date }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ─── Phase timings (frames @ 30fps) ─────────────────────────────────
  // 0–60   (0–2s):   Stone paths spring in one by one
  // 60–110 (2–3.7s): Cross-dissolve: stone fades out, full logo fades in
  // 110–280 (3.7–9.3s): Logo holds centered
  // 280–310 (9.3–10.3s): Logo snaps up + scales down (kinetic)
  // 295–540 (9.8–18s): Title card slams in line by line, holds
  // 540–600 (18–20s): Fade to black

  // Background fade: black → #0e1237
  const bgOpacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Stone: quick fade in, hold, then kinetic "push" before dissolve
  const stonePush = interpolate(frame, [55, 72], [1, 1.09], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const stoneOpacity = interpolate(
    frame,
    [0, 5, 55, 100],
    [0, 1, 1, 0],
    { extrapolateRight: "clamp" }
  );

  // Full logo: fades in during cross-dissolve, stays until fade-out
  const logoOpacity = interpolate(
    frame,
    [60, 110, 540, 600],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Logo snap: springs from center up to title-card position
  const snapProgress = spring({
    frame: frame - 280,
    fps,
    config: { damping: 22, stiffness: 500, mass: 0.7 },
  });
  const logoY = interpolate(snapProgress, [0, 1], [0, -195]);
  const logoScale = interpolate(snapProgress, [0, 1], [1, 0.6]);

  // Global fade to black
  const globalOpacity = interpolate(frame, [540, 600], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ background: "black" }}>
      {/* Background layer fades from black to brand dark */}
      <AbsoluteFill style={{ background: "#0e1237", opacity: bgOpacity }} />

      <Audio src={staticFile("method-man.mp3")} />

      {/* Content — fades out at end */}
      <AbsoluteFill style={{ opacity: globalOpacity }}>
        {/* Phase 1: Animated stone icon, centered */}
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: stoneOpacity,
            transform: `scale(${stonePush})`,
          }}
        >
          <StoneIcon />
        </AbsoluteFill>

        {/* Phase 2+: Full logo, springs up to make room for title */}
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: logoOpacity,
            transform: `translateY(${logoY}px) scale(${logoScale})`,
          }}
        >
          <FullLogo />
        </AbsoluteFill>

        {/* Phase 3: Title card slams in below the logo */}
        <TitleCard
          title={title}
          subtitle={subtitle}
          date={date}
          startFrame={295}
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
