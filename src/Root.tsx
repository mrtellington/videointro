import React from "react";
import { Composition } from "remotion";
import { Opener } from "./Opener";
import type { OpenerProps } from "./Opener";
import { Outro } from "./Outro";
import type { OutroProps } from "./Outro";
import { NoteSlide } from "./NoteSlide";
import type { NoteSlideProps } from "./NoteSlide";

export const Root: React.FC = () => {
  return (
    <>
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
      <Composition
        id="Outro"
        component={Outro}
        durationInFrames={540}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={
          {
            title: "2026 Operations Summit",
            subtitle: "Engine Behind the Experience",
            date: "Day 1  ·  March 24, 2026",
          } as OutroProps
        }
      />
      <Composition
        id="NoteSlide"
        component={NoteSlide}
        durationInFrames={150}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={
          {
            message:
              "This recording was started approximately 45 minutes after the beginning of the day's session.",
          } as NoteSlideProps
        }
      />
    </>
  );
};
