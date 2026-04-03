import React from "react";
import { Composition } from "remotion";
import { Opener } from "./Opener";
import type { OpenerProps } from "./Opener";

export const Root: React.FC = () => {
  return (
    <Composition
      id="Opener"
      component={Opener}
      durationInFrames={600}
      fps={30}
      width={1920}
      height={1080}
      defaultProps={
        {
          title: "2026 Operations Summit",
          subtitle: "Engine Behind the Experience",
          date: "Day 1  ·  March 24, 2026",
        } as OpenerProps
      }
    />
  );
};
