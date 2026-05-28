import React from 'react';
import { GestureResponderEvent, Image, TouchableOpacity, ViewStyle } from 'react-native';
import { PipButtonConfig } from '../pip/types';

interface SoundButtonProps {
  config: PipButtonConfig | null;
  onPress: (event: GestureResponderEvent) => void;
  style?: ViewStyle;
  ignoreSizeAndMargin?: boolean;
  enabled?: boolean;
  type: 'mute' | 'unmute';
}

export const SoundButton: React.FC<SoundButtonProps> = ({ config, onPress, ignoreSizeAndMargin = false, enabled, style, type }) => {
  if (!config || !enabled) return null;

  const { size: backendSize = 18, margin, color, image, selectedStyle } = config;
  const size = ignoreSizeAndMargin ? 40 : backendSize;

  const containerStyle: ViewStyle = {
    width: size, height: size,
    backgroundColor: color?.fill || 'transparent',
    borderColor: color?.stroke || 'transparent',
    borderWidth: size * 0.05,
    borderRadius: size / 2,
    justifyContent: 'center', alignItems: 'center',
    zIndex: 1000000,
    marginTop: ignoreSizeAndMargin ? 0 : (margin?.top ?? 0),
    marginBottom: ignoreSizeAndMargin ? 0 : (margin?.bottom ?? 0),
    marginLeft: ignoreSizeAndMargin ? 0 : (margin?.left ?? 0),
    marginRight: ignoreSizeAndMargin ? 0 : (margin?.right ?? 0),
    ...style,
  };

  return (
    <TouchableOpacity activeOpacity={0.7} onPress={onPress} style={containerStyle} testID={selectedStyle} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
      {image && image.trim() !== '' ? (
        <Image source={{ uri: image }} style={{ width: size, height: size }} resizeMode="contain" />
      ) : type === 'mute' ? (
        <Image source={require('../../assets/images/mute.png')} resizeMode="contain" style={{ height: size, width: size, tintColor: color?.cross || '#ffffff' }} />
      ) : (
        <Image source={require('../../assets/images/volume.png')} resizeMode="contain" style={{ height: size, width: size, tintColor: color?.cross || '#ffffff' }} />
      )}
    </TouchableOpacity>
  );
};
