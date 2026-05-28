import React from 'react';
import { TouchableOpacity, Image, ViewStyle, GestureResponderEvent } from 'react-native';

export interface CrossButtonConfig {
  color: {
    cross: string;
    fill: string;
    stroke: string;
  };
  enabled: boolean;
  image: string;
  margin: {
    bottom: number;
    left: number;
    right: number;
    top: number;
  };
  selectedStyle?: string;
  size: number;
}

interface CrossButtonProps {
  config?: CrossButtonConfig | null;
  onPress: (event: GestureResponderEvent) => void;
  style?: ViewStyle;
  ignoreSizeAndMargin?: boolean;
}

const CrossButton: React.FC<CrossButtonProps> = ({ config, onPress, style, ignoreSizeAndMargin = false }) => {
  if (!config || !config.enabled) return null;

  const { size: backendSize = 18, margin, color, image, selectedStyle } = config;
  const size = ignoreSizeAndMargin ? 40 : backendSize;

  const marginTop = ignoreSizeAndMargin ? 0 : (margin?.top ?? 0);
  const marginBottom = ignoreSizeAndMargin ? 0 : (margin?.bottom ?? 0);
  const marginLeft = ignoreSizeAndMargin ? 0 : (margin?.left ?? 0);
  const marginRight = ignoreSizeAndMargin ? 0 : (margin?.right ?? 0);

  const containerStyle: ViewStyle = {
    marginTop,
    marginBottom,
    marginLeft,
    marginRight,
    width: size,
    height: size,
    backgroundColor: color?.fill || 'transparent',
    borderColor: color?.stroke || 'transparent',
    borderWidth: size * 0.05,
    borderRadius: size / 2,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000000,
    position: 'absolute',
    ...style,
  };

  return (
    <TouchableOpacity
      activeOpacity={0.7}
      onPress={onPress}
      style={containerStyle}
      testID={selectedStyle}
      hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
    >
      {image && image.trim() !== '' ? (
        <Image source={{ uri: image }} style={{ width: size, height: size }} resizeMode="contain" />
      ) : (
        <Image
          source={require('../../assets/images/close.png')}
          resizeMode="contain"
          style={{ height: size, width: size, tintColor: color?.cross || '#ffffff' }}
        />
      )}
    </TouchableOpacity>
  );
};

export default CrossButton;
