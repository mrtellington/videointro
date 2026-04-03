import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Figtree";

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

  // Title: crashes in from below with scale punch — most impact
  const titleProgress = spring({
    frame: f,
    fps,
    config: { damping: 14, stiffness: 700, mass: 0.45 },
  });
  const titleY = interpolate(titleProgress, [0, 1], [120, 0]);
  const titleScale = interpolate(titleProgress, [0, 0.5, 1], [0.85, 1.04, 1]);
  const titleOpacity = interpolate(f, [0, 6], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Subtitle: slides in from left with slight delay
  const subProgress = spring({
    frame: f - 10,
    fps,
    config: { damping: 15, stiffness: 500, mass: 0.5 },
  });
  const subX = interpolate(subProgress, [0, 1], [-80, 0]);
  const subOpacity = interpolate(f, [10, 20], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Date: slides in from right with further delay
  const dateProgress = spring({
    frame: f - 20,
    fps,
    config: { damping: 16, stiffness: 400, mass: 0.5 },
  });
  const dateX = interpolate(dateProgress, [0, 1], [60, 0]);
  const dateOpacity = interpolate(f, [20, 30], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    // Centered vertically and horizontally on the frame
    <AbsoluteFill
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        fontFamily,
        textAlign: "center",
        // Nudge slightly below center to feel balanced with the logo above
        paddingTop: 80,
      }}
    >
      {/* Line 1: Main title — largest, boldest */}
      <div
        style={{
          transform: `translateY(${titleY}px) scale(${titleScale})`,
          opacity: titleOpacity,
          fontSize: 108,
          fontWeight: 800,
          color: "#ffffff",
          letterSpacing: "-2px",
          lineHeight: 1.0,
          maxWidth: 1500,
        }}
      >
        {title}
      </div>

      {/* Line 2: Subtitle — teal, slides from left */}
      <div
        style={{
          transform: `translateX(${subX}px)`,
          opacity: subOpacity,
          fontSize: 58,
          fontWeight: 400,
          color: "#00b6bf",
          marginTop: 24,
          letterSpacing: "0.5px",
        }}
      >
        {subtitle}
      </div>

      {/* Line 3: Date — light, uppercase, slides from right */}
      <div
        style={{
          transform: `translateX(${dateX}px)`,
          opacity: dateOpacity,
          fontSize: 32,
          fontWeight: 300,
          color: "rgba(255,255,255,0.6)",
          marginTop: 36,
          letterSpacing: "5px",
          textTransform: "uppercase",
        }}
      >
        {date}
      </div>
    </AbsoluteFill>
  );
};

