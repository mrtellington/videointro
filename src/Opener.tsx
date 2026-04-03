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

  // ─── Phase timings (frames @ 30fps, 750 total = 25s) ─────────────────
  // 0–60    (0–2s):    Stone paths spring in
  // 60–210  (2–7s):    Stone holds with beat pulse (no glow)
  // 200–265 (6.7–8.8s):Stone spins out
  // 215–270 (7.2–9s):  Full logo slams in from above
  // 270–350 (9–11.7s): Logo holds
  // 350–382 (11.7–12.7s):Logo flies off left
  // 360–750 (12–25s):  Title card holds — no fade, abrupt stop at 750

  // Background fade: black → #0e1237
  const bgOpacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: "clamp",
  });

  // ── Beat pulse: ~92 BPM, snappy spring reset each beat, no glow ──
  const BEAT = 20;
  const beatFrame = frame % BEAT;
  const beatPulse = spring({
    frame: beatFrame,
    fps,
    config: { damping: 5, stiffness: 1200, mass: 0.08 },
  });
  const inPulsePhase = frame >= 60 && frame < 210;
  const pulseScale = inPulsePhase ? 1 + beatPulse * 0.05 : 1;

  // ── Stone: fades in, holds, then spins out ──
  const stoneOpacity = interpolate(
    frame,
    [0, 5, 200, 265],
    [0, 1, 1, 0],
    { extrapolateRight: "clamp" }
  );

  const spinExit = spring({
    frame: frame - 200,
    fps,
    config: { damping: 20, stiffness: 280, mass: 0.9 },
  });
  const stoneSpinDeg = interpolate(spinExit, [0, 1], [0, 360]);
  const stoneExitScale = interpolate(spinExit, [0, 0.65, 1], [1, 0.9, 0]);

  // ── Full logo: slams in from above, exits to the left ──
  const logoEnter = spring({
    frame: frame - 215,
    fps,
    config: { damping: 12, stiffness: 260, mass: 0.95 },
  });
  const logoSlideY = interpolate(logoEnter, [0, 1], [-380, 0]);
  const logoSlideScale = interpolate(logoEnter, [0, 1], [0.5, 1]);

  const logoExit = spring({
    frame: frame - 350,
    fps,
    config: { damping: 22, stiffness: 700, mass: 0.5 },
  });
  const logoExitX = interpolate(logoExit, [0, 1], [0, -1400]);
  const logoExitRotate = interpolate(logoExit, [0, 1], [0, -30]);

  const logoOpacity = interpolate(
    frame,
    [215, 242, 350, 382],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill style={{ background: "black" }}>
      <AbsoluteFill style={{ background: "#0e1237", opacity: bgOpacity }} />

      <Audio src={staticFile("method-man.mp3")} />

      {/* No global fade — abrupt stop at frame 750 */}
      <AbsoluteFill>
        {/* ── Stone phase ── */}
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            opacity: stoneOpacity,
            transform: `rotate(${stoneSpinDeg}deg) scale(${stoneExitScale * pulseScale})`,
          }}
        >
          <StoneIcon />
        </AbsoluteFill>

        {/* ── Full logo: slams in from above, flies off left ── */}
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

        {/* ── Title card: crashes in at 12s, holds to hard cut at 25s ── */}
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
