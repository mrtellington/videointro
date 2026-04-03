import React from "react";
import { staticFile } from "remotion";

// Renders the full Whitestone logo (stone icon + wordmark).
// SVG viewBox is 1080×288; we render at 900px wide to stay centered in 1920px frame.

export const FullLogo: React.FC = () => {
  return (
    <img
      src={staticFile("full-logo.svg")}
      style={{
        width: 900,
        height: Math.round(900 * (288 / 1080)), // 240px
      }}
      alt="Whitestone"
    />
  );
};
