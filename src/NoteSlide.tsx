import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Figtree";

loadFont("normal", { weights: ["300", "400", "700"] });
const { fontFamily } = loadFont("normal");

export type NoteSlideProps = {
  message: string;
};

// 5s (150 frames @ 30fps): grows in → holds → shrinks out
export const NoteSlide: React.FC<NoteSlideProps> = ({ message }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const growIn = spring({
    frame,
    fps,
    config: { damping: 14, stiffness: 400, mass: 0.5 },
  });
  const enterScale = interpolate(growIn, [0, 1], [0, 1]);

  const shrinkOut = spring({
    frame: frame - 120,
    fps,
    config: { damping: 20, stiffness: 400, mass: 0.6 },
  });
  const exitScale = interpolate(shrinkOut, [0, 1], [1, 0]);

  const scale = frame < 120 ? enterScale : enterScale * exitScale;

  return (
    <AbsoluteFill
      style={{
        background: "#0e1237",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div
        style={{
          transform: `scale(${scale})`,
          textAlign: "center",
          fontFamily,
          maxWidth: 1200,
        }}
      >
        <div
          style={{
            fontSize: 22,
            fontWeight: 700,
            color: "rgba(255,255,255,0.4)",
            letterSpacing: "6px",
            textTransform: "uppercase",
            marginBottom: 24,
          }}
        >
          Note
        </div>
        <div
          style={{
            fontSize: 38,
            fontWeight: 300,
            color: "rgba(255,255,255,0.75)",
            lineHeight: 1.6,
            letterSpacing: "0.3px",
          }}
        >
          {message}
        </div>
      </div>
    </AbsoluteFill>
  );
};
