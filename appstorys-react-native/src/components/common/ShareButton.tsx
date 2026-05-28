import React from 'react';
import { GestureResponderEvent, Image, TouchableOpacity, ViewStyle } from 'react-native';

export interface ShareButtonConfig {
  color?: { cross?: string; fill?: string; stroke?: string };
  enabled?: boolean;
  image?: string;
  margin?: { bottom?: number; left?: number; right?: number; top?: number };
  size?: number;
}

interface ShareButtonProps {
  config: ShareButtonConfig | null;
  onPress: (event: GestureResponderEvent) => void;
  style?: ViewStyle;
}

const ShareButton: React.FC<ShareButtonProps> = ({ config, onPress, style }) => {
  if (!config || config.enabled === false) return null;

  const size = config.size ?? 18;
  const color = config.color ?? {};

  const containerStyle: ViewStyle = {
    width: size,
    height: size,
    backgroundColor: color.fill ?? 'transparent',
    borderColor: color.stroke ?? 'transparent',
    borderWidth: size * 0.05,
    borderRadius: size / 2,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000000,
    position: 'absolute',
    top: config.margin?.top ?? 0,
    right: config.margin?.right ?? 0,
    ...style,
  };

  return (
    <TouchableOpacity
      activeOpacity={0.7}
      onPress={onPress}
      style={containerStyle}
      hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
    >
      {config.image && config.image.trim() !== '' ? (
        <Image source={{ uri: config.image }} style={{ width: size, height: size }} resizeMode="contain" />
      ) : (
        <Image
          source={require('../../assets/images/share.png')}
          resizeMode="contain"
          style={{ height: size, width: size, tintColor: color.cross ?? '#ffffff' }}
        />
      )}
    </TouchableOpacity>
  );
};

export default ShareButton;
