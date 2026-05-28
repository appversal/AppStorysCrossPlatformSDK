import React from 'react';
import { View, ViewStyle } from 'react-native';
import { PipStyling } from '../pip/types';
import { SoundButton } from './SoundButton';
import { ExpandableButton } from './ExpandableButton';
import CrossButton from './CrossButton';

type PipMode = 'SMALL' | 'LARGE';

interface PipControlsProps {
  styling: PipStyling;
  mode: PipMode;
  muted: boolean;
  expanded: boolean;
  onClose: () => void;
  onToggleMute: () => void;
  onToggleExpand: () => void;
  containerStyle?: ViewStyle;
}

const PipControls: React.FC<PipControlsProps> = ({ styling, mode, muted, expanded, onClose, onToggleMute, onToggleExpand, containerStyle }) => {
  if (!styling) return null;

  const ignoreSizeAndMargin = mode === 'LARGE';

  const crossStyle: ViewStyle = ignoreSizeAndMargin ? { position: 'absolute', top: 15, right: 15 } : { position: 'absolute', top: 0, right: 0 };
  const soundStyle: ViewStyle = ignoreSizeAndMargin ? { position: 'absolute', top: 15, right: 60 } : { position: 'absolute', top: 0, left: 0 };
  const expandStyle: ViewStyle = ignoreSizeAndMargin ? { position: 'absolute', top: 15, left: 15 } : { position: 'absolute', bottom: 0, right: 0 };

  const soundConfig = muted ? styling.soundToggle?.unmute : styling.soundToggle?.mute;
  const expandConfig = expanded ? styling.expandControls?.minimise : styling.expandControls?.maximise;

  return (
    <View pointerEvents="box-none" style={[{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, width: '100%', height: '100%', zIndex: 9999999, elevation: 9999999 }, containerStyle]}>
      {styling.crossButton?.enabled && (
        <CrossButton config={{ ...styling.crossButton, size: styling.crossButton.size && styling.crossButton.size > 10 ? styling.crossButton.size : 20 }} onPress={onClose} ignoreSizeAndMargin={ignoreSizeAndMargin} style={crossStyle} />
      )}
      {styling.soundToggle?.enabled && soundConfig && (
        <SoundButton config={soundConfig} onPress={onToggleMute} ignoreSizeAndMargin={ignoreSizeAndMargin} style={soundStyle} enabled={styling.soundToggle?.enabled} type={muted ? 'unmute' : 'mute'} />
      )}
      {styling.expandControls?.enabled && expandConfig && (
        <ExpandableButton config={expandConfig} onPress={onToggleExpand} ignoreSizeAndMargin={ignoreSizeAndMargin} style={expandStyle} enabled={styling.expandControls?.enabled} type={expanded ? 'minimise' : 'maximise'} />
      )}
    </View>
  );
};

export default PipControls;
