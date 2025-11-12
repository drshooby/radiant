type VideoPlayerStyleOverrides = {
  mainVideoContainer?: React.CSSProperties
}

export interface VideoPlayerProps {
  videoName: string;
  overrides?: VideoPlayerStyleOverrides
}