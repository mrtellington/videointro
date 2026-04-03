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

  // All lines grow from center (scale 0→1) with stagger — organic, no slides
  const growIn = (delay: number) => {
    const progress = spring({
      frame: f - delay,
      fps,
      config: { damping: 14, stiffness: 500, mass: 0.5 },
    });
    const scale = interpolate(progress, [0, 1], [0, 1]);
    const opacity = interpolate(f - delay, [0, 8], [0, 1], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    });
    return { transform: `scale(${scale})`, opacity };
  };

  return (
    <AbsoluteFill
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        fontFamily,
        textAlign: "center",
        paddingTop: 80,
      }}
    >
      {/* Title — grows first */}
      <div
        style={{
          ...growIn(0),
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

      {/* Subtitle — teal, grows with slight delay */}
      <div
        style={{
          ...growIn(8),
          fontSize: 58,
          fontWeight: 400,
          color: "#00b6bf",
          marginTop: 24,
          letterSpacing: "0.5px",
        }}
      >
        {subtitle}
      </div>

      {/* Date — light, grows last */}
      <div
        style={{
          ...growIn(16),
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
