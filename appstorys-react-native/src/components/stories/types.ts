export interface StorySlide {
  id: string;
  image?: string;
  video?: string;
  link?: string;
  button_text?: string;
  finish?: number;
  order?: number;
  styling?: { cta?: any };
}

export interface StoryGroupState {
  ringColor?: string;
  fontColor?: string;
  fontSize?: number;
  fontDecoration?: string[];
}

export interface StoryStyling {
  storyGroupNotViewed?: StoryGroupState;
  storyGroupViewed?: StoryGroupState;
  size?: number;
  ringWidth?: number;
  cornerRadius?: { topLeft?: number; topRight?: number; bottomLeft?: number; bottomRight?: number };
  crossButton?: { enabled?: boolean; size?: number; margin?: { top?: number; right?: number }; color?: { cross?: string; fill?: string; stroke?: string }; image?: string };
  share?: { enabled?: boolean; image?: string; size?: number; margin?: { top?: number; right?: number }; color?: any };
  soundToggle?: { enabled?: boolean; mute?: any; unmute?: any };
  name?: { size?: number };
}

export interface StoryGroup {
  id?: string;
  name?: string;
  thumbnail?: string;
  ringColor?: string;
  nameColor?: string;
  slides?: StorySlide[];
  styling?: StoryStyling;
  order?: number;
}

export interface StoryData {
  groups: StoryGroup[];
  campaignId: string;
  initialGroupIndex: number;
}
