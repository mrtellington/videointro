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
  // 0–60    (0–2s):    Stone paths spring in one by one
  // 60–135  (2–4.5s):  Stone holds with beat pulse + teal glow
  // 120–175 (4–5.8s):  Stone spins out (360° + scale to 0)
  // 135–195 (4.5–6.5s):Full logo slams in from above with bounce
  // 195–295 (6.5–9.8s):Logo holds centered
  // 290–320 (9.7–10.7s):Logo flies off left (dramatic exit)
  // 305–385 (10.2–12.8s):Title crashes in centered
  // 385–540 (12.8–18s): Title holds
  // 540–600 (18–20s):   Fade to black

  // Background fade: black → #0e1237
  const bgOpacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: "clamp",
  });

  // ── Beat pulse (approx 92 BPM = beat every ~19.6 frames, round to 20) ──
  // Resets each beat creating a snappy percussive scale/glow effect
  const BEAT = 20;
  const beatFrame = frame % BEAT;
  const beatPulse = spring({
    frame: beatFrame,
    fps,
    config: { damping: 5, stiffness: 1200, mass: 0.08 },
  });
  // Only apply pulse during stone hold phase
  const inPulsePhase = frame >= 60 && frame < 120;
  const pulseScale = inPulsePhase ? 1 + beatPulse * 0.05 : 1;
  const glowIntensity = inPulsePhase ? beatPulse * 28 : 0;

  // ── Stone: entrance opacity, then spins out ──
  const stoneOpacity = interpolate(
    frame,
    [0, 5, 120, 175],
    [0, 1, 1, 0],
    { extrapolateRight: "clamp" }
  );

  // Stone spin exit — full 360° rotation while scaling to 0
  const spinExit = spring({
    frame: frame - 120,
    fps,
    config: { damping: 20, stiffness: 280, mass: 0.9 },
  });
  const stoneSpinDeg = interpolate(spinExit, [0, 1], [0, 360]);
  const stoneExitScale = interpolate(spinExit, [0, 0.65, 1], [1, 0.9, 0]);

  // ── Full logo: slams in from above with bounce ──
  const logoEnter = spring({
    frame: frame - 135,
    fps,
    config: { damping: 12, stiffness: 260, mass: 0.95 },
  });
  const logoSlideY = interpolate(logoEnter, [0, 1], [-380, 0]);
  const logoSlideScale = interpolate(logoEnter, [0, 1], [0.5, 1]);
  const logoEnterOpacity = interpolate(frame, [135, 162], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // ── Logo dramatic exit: flies off to the left with a spin ──
  const logoExit = spring({
    frame: frame - 290,
    fps,
    config: { damping: 22, stiffness: 700, mass: 0.5 },
  });
  const logoExitX = interpolate(logoExit, [0, 1], [0, -1400]);
  const logoExitRotate = interpolate(logoExit, [0, 1], [0, -30]);
  const logoOpacity = interpolate(
    frame,
    [135, 162, 290, 322],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // ── Global fade to black ──
  const globalOpacity = interpolate(frame, [540, 600], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ background: "black" }}>
      <AbsoluteFill style={{ background: "#0e1237", opacity: bgOpacity }} />

      <Audio src={staticFile("method-man.mp3")} />

      <AbsoluteFill style={{ opacity: globalOpacity }}>
        {/* ── Stone phase ── */}
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: stoneOpacity,
            // Combine beat pulse scale with spin-exit scale
            transform: `rotate(${stoneSpinDeg}deg) scale(${stoneExitScale * pulseScale})`,
            filter:
              glowIntensity > 0
                ? `drop-shadow(0 0 ${glowIntensity}px #00b6bf)`
                : undefined,
          }}
        >
          <StoneIcon />
        </AbsoluteFill>

        {/* ── Full logo phase: slams in from above, exits to the left ── */}
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: logoOpacity,
            transform: `translate(${logoExitX}px, ${logoSlideY}px) scale(${logoSlideScale}) rotate(${logoExitRotate}deg)`,
          }}
        >
          <FullLogo />
        </AbsoluteFill>

        {/* ── Title card: crashes in from below, centered ── */}
        <TitleCard
          title={title}
          subtitle={subtitle}
          date={date}
          startFrame={305}
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
