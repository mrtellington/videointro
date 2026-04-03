import React from "react";
import { spring, useCurrentFrame, useVideoConfig } from "remotion";

// Inline the 3 stone paths from Whitestone_SoloStone_Full Color.svg
// Each path springs in with a staggered delay for a kinetic "build" effect.
// transform-box: fill-box + transform-origin: center scales each path from its own center.

export const StoneIcon: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const path1Scale = spring({
    frame,
    fps,
    config: { damping: 10, stiffness: 260, mass: 0.5 },
  });

  const path2Scale = spring({
    frame: frame - 7,
    fps,
    config: { damping: 10, stiffness: 260, mass: 0.5 },
  });

  const path3Scale = spring({
    frame: frame - 14,
    fps,
    config: { damping: 8, stiffness: 300, mass: 0.4 },
  });

  const pathStyle = (scale: number): any => ({
    transformBox: "fill-box",
    transformOrigin: "center",
    transform: `scale(${scale})`,
  });

  return (
    <svg
      viewBox="0 0 600.16 464.18"
      style={{ width: 420, height: 325 }}
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient
          id="sg1"
          x1="-1.21"
          y1="145.37"
          x2="770.39"
          y2="-626.33"
          gradientTransform="translate(0 303.8)"
          gradientUnits="userSpaceOnUse"
        >
          <stop offset="0" stopColor="#007089" />
          <stop offset=".5" stopColor="#00b6bf" />
        </linearGradient>
        <linearGradient
          id="sg2"
          x1="161.4"
          y1="368.07"
          x2="549.7"
          y2="-20.23"
          gradientTransform="translate(0 303.8)"
          gradientUnits="userSpaceOnUse"
        >
          <stop offset=".6" stopColor="#007089" />
          <stop offset="1" stopColor="#00b6bf" />
        </linearGradient>
        <linearGradient
          id="sg3"
          x1="105.7"
          y1="292.97"
          x2="841.4"
          y2="-442.73"
          gradientTransform="translate(0 303.8)"
          gradientUnits="userSpaceOnUse"
        >
          <stop offset=".4" stopColor="#007089" />
          <stop offset=".7" stopColor="#00b6bf" />
        </linearGradient>
      </defs>

      {/* Path 1 — large left shape (springs in first) */}
      <path
        fill="url(#sg1)"
        style={pathStyle(path1Scale)}
        d="M350.03,3.5c-72.1-12.9-135.1,10.3-189.4,61.7C84.13,135.1,12.43,230.6.83,336.3c-5.3,47,14.7,93.3,61.1,108.7,47.9,16.8,106.8,16.7,154.2-3.5,61.8-26,83.6-92.7,117.4-146.7,26.6-43.2,62.9-81.6,85.8-127.1,38.9-72.2,16.9-147.8-67.8-163.9l-1.4-.3h-.1Z"
      />

      {/* Path 2 — bottom right shape */}
      <path
        fill="url(#sg2)"
        style={pathStyle(path2Scale)}
        d="M600.03,374.7c-3.9-41.7-52.4-78.9-91.8-95.3-45.5-20.2-101.9-19.1-138.9,16.4-65.3,63-31.8,168.6,62.7,168.3,55.4,1.5,170.2-19.4,168.1-88.3v-1.1h-.1Z"
      />

      {/* Path 3 — small upper right accent (springs in last) */}
      <path
        fill="url(#sg3)"
        style={pathStyle(path3Scale)}
        d="M474.23,241.5c36.7,27.3,94.2,3.9,104.2-40.2,9.9-34.1-12.4-75.5-45.1-83.1-63.3-15.8-113.9,83.1-60.2,122.5l1.1.8Z"
      />
    </svg>
  );
};
