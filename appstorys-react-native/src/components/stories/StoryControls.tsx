import React from 'react';
import { View, ViewStyle } from 'react-native';
import { StoryStyling } from './types';
import ShareButton from '../common/ShareButton';
import { SoundButton } from '../common/SoundButton';
import CrossButton from '../common/CrossButton';

interface StoryControlsProps {
  styling: StoryStyling;
  muted: boolean;
  onClose: () => void;
  onToggleMute: () => void;
  onShare: () => void;
  hasVideo: boolean;
  hasLink: boolean;
  containerStyle?: ViewStyle;
}

const StoryControls: React.FC<StoryControlsProps> = ({
  styling, muted, onClose, onToggleMute, onShare, hasVideo, hasLink, containerStyle,
}) => {
  if (!styling) return null;

  const crossConfig = styling.crossButton;
  const shareConfig = styling.share;
  const soundConfig = muted ? styling.soundToggle?.unmute : styling.soundToggle?.mute;

  return (
    <View
      pointerEvents="box-none"
      style={[{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, width: '100%', height: '100%', zIndex: 9999999 }, containerStyle]}
    >
      {crossConfig?.enabled && (
        <CrossButton
          config={{
            color: { cross: crossConfig.color?.cross ?? '#ffffff', fill: crossConfig.color?.fill ?? 'transparent', stroke: crossConfig.color?.stroke ?? 'transparent' },
            image: crossConfig.image ?? '',
            enabled: crossConfig.enabled ?? true,
            margin: { top: crossConfig.margin?.top ?? 0, bottom: 0, left: 0, right: crossConfig.margin?.right ?? 0 },
            size: crossConfig.size && crossConfig.size > 10 ? crossConfig.size : 20,
          }}
          onPress={onClose}
          style={{ position: 'absolute', top: crossConfig.margin?.top ?? 0, right: crossConfig.margin?.right ?? 0 }}
        />
      )}
      {shareConfig?.enabled && hasLink && (
        <ShareButton config={shareConfig} onPress={onShare} style={{ position: 'absolute', top: shareConfig.margin?.top ?? 0, right: shareConfig.margin?.right ?? 0 }} />
      )}
      {styling.soundToggle?.enabled && hasVideo && soundConfig && (
        <SoundButton
          config={soundConfig}
          onPress={onToggleMute}
          style={{ position: 'absolute', top: soundConfig.margin?.top ?? 0, right: soundConfig.margin?.right ?? 0 }}
          enabled={styling.soundToggle?.enabled}
          type={muted ? 'unmute' : 'mute'}
        />
      )}
    </View>
  );
};

export default StoryControls;
