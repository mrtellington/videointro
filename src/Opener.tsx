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
  music?: boolean;
};

export const Opener: React.FC<OpenerProps> = ({ title, subtitle, date, music = true }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ─── Phase timings (frames @ 30fps, 600 total = 20s) ─────────────────
  // 0–60    (0–2s):    Stone paths spring in
  // 60–210  (2–7s):    Stone holds with beat pulse
  // 200–265 (6.7–8.8s):Stone shrinks to 0 from center
  // 215–270 (7.2–9s):  Full logo grows from center
  // 270–350 (9–11.7s): Logo holds
  // 350–382 (11.7–12.7s):Logo shrinks to 0 from center
  // 360–600 (12–20s):  Title card grows in, holds — hard cut at 600

  // Background fade: black → #0e1237
  const bgOpacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: "clamp",
  });

  // ── Beat pulse: ~92 BPM, snappy spring reset each beat ──
  const BEAT = 20;
  const beatFrame = frame % BEAT;
  const beatPulse = spring({
    frame: beatFrame,
    fps,
    config: { damping: 5, stiffness: 1200, mass: 0.08 },
  });
  const inPulsePhase = frame >= 60 && frame < 200;
  const pulseScale = inPulsePhase ? 1 + beatPulse * 0.18 : 1;

  // ── Stone: grows in (via StoneIcon springs), holds, shrinks to 0 ──
  const stoneShrink = spring({
    frame: frame - 200,
    fps,
    config: { damping: 20, stiffness: 400, mass: 0.6 },
  });
  const stoneShrinkScale = interpolate(stoneShrink, [0, 1], [1, 0]);

  const stoneVisible = frame < 265;
  const stoneScale = stoneVisible ? pulseScale * stoneShrinkScale : 0;

  // ── Full logo: grows from center, holds, shrinks to 0 ──
  const logoGrow = spring({
    frame: frame - 215,
    fps,
    config: { damping: 13, stiffness: 300, mass: 0.8 },
  });
  const logoGrowScale = interpolate(logoGrow, [0, 1], [0, 1]);

  const logoShrink = spring({
    frame: frame - 350,
    fps,
    config: { damping: 22, stiffness: 500, mass: 0.5 },
  });
  const logoShrinkScale = interpolate(logoShrink, [0, 1], [1, 0]);

  const logoVisible = frame >= 215 && frame < 390;
  const logoScale = logoVisible ? logoGrowScale * logoShrinkScale : 0;

  return (
    <AbsoluteFill style={{ background: "black" }}>
      <AbsoluteFill style={{ background: "#0e1237", opacity: bgOpacity }} />

      {music && <Audio src={staticFile("method-man.mp3")} />}

      <AbsoluteFill>
        {/* ── Stone: centered, grows in, pulses, shrinks ── */}
        {stoneVisible && (
          <AbsoluteFill
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              transform: `scale(${stoneScale})`,
            }}
          >
            <StoneIcon />
          </AbsoluteFill>
        )}

        {/* ── Full logo: grows from center, shrinks to center ── */}
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

        {/* ── Title card: grows in from center, holds to hard cut ── */}
        <TitleCard
          title={title}
          subtitle={subtitle}
          date={date}
          startFrame={360}
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
