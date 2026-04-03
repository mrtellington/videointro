import React from "react";
import { interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { loadFont } from "@remotion/google-fonts/Figtree";

// Load Figtree weights needed for the title card
loadFont("normal", { weights: ["300", "400", "800"] });
const { fontFamily } = loadFont("normal");

type Props = {
  title: string;
  subtitle: string;
  date: string;
  startFrame: number;
};

export const TitleCard: React.FC<Props> = ({
  title,
  subtitle,
  date,
  startFrame,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const f = frame - startFrame;

  if (f < 0) return null;

  // Each line slams up from below with a spring + stagger
  const slamIn = (delay: number) => {
    const progress = spring({
      frame: f - delay,
      fps,
      config: { damping: 16, stiffness: 600, mass: 0.5 },
    });
    return {
      transform: `translateY(${interpolate(progress, [0, 1], [65, 0])}px)`,
      opacity: interpolate(f - delay, [0, 8], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      }),
    };
  };

  return (
    <div
      style={{
        position: "absolute",
        bottom: 160,
        left: 0,
        right: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        fontFamily,
        textAlign: "center",
      }}
    >
      {/* Line 1: Main event title */}
      <div
        style={{
          ...slamIn(0),
          fontSize: 80,
          fontWeight: 800,
          color: "#ffffff",
          letterSpacing: "-1.5px",
          lineHeight: 1.05,
          maxWidth: 1400,
        }}
      >
        {title}
      </div>

      {/* Line 2: Subtitle / tagline — teal accent */}
      <div
        style={{
          ...slamIn(8),
          fontSize: 44,
          fontWeight: 400,
          color: "#00b6bf",
          marginTop: 20,
          letterSpacing: "0.5px",
        }}
      >
        {subtitle}
      </div>

      {/* Line 3: Date / episode — light weight, uppercase */}
      <div
        style={{
          ...slamIn(16),
          fontSize: 26,
          fontWeight: 300,
          color: "rgba(255,255,255,0.6)",
          marginTop: 30,
          letterSpacing: "4px",
          textTransform: "uppercase",
        }}
      >
        {date}
      </div>
    </div>
  );
};
