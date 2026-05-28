import { CrossButtonConfig } from '../common/CrossButton';

export interface PipButtonConfig {
  color: { cross: string; fill: string; stroke: string };
  enabled: boolean;
  image: string;
  margin: { bottom: number; left: number; right: number; top: number };
  selectedStyle?: string;
  size: number;
}

export interface PipStyling {
  appearance: { defaultSound: string; pipHeight: string; pipWidth: string };
  crossButton: CrossButtonConfig;
  cta: {
    cornerRadius: { bottomLeft: number; bottomRight: number; topLeft: number; topRight: number };
    container: { alignment: string; backgroundColor: string; borderColor: string; borderWidth: number; ctaFullWidth: boolean; ctaWidth: number; height: number };
    margin: { bottom: number; left: number; right: number; top: number };
    text: { color: string; fontDecoration: string[]; fontFamily: string; fontSize: number };
  };
  expandControls: { enabled: boolean; maximise: PipButtonConfig; minimise: PipButtonConfig; option: string };
  expandablePip: string;
  isMovable: boolean;
  pipBottomPadding: number;
  pipTopPadding: number;
  soundToggle: { defaultSound: string; enabled: boolean; mute: PipButtonConfig; option: string; unmute: PipButtonConfig };
  videoSelection: string;
}

export type PipData = {
  id: string;
  link: string | null;
  button_text: string | null;
  largeVideoUrl: string;
  styling: PipStyling;
};
