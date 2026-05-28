import React from 'react';
import { GestureResponderEvent, View, Pressable, Text, FlexAlignType } from 'react-native';
import { personalizeText } from '../../domain/actions/utils/personalization';

export const mapAlignment = (alignment?: string): FlexAlignType => {
  switch (alignment) {
    case 'left': case 'flex-start': return 'flex-start';
    case 'right': case 'flex-end': return 'flex-end';
    default: return 'center';
  }
};

interface CtaProps {
  cta?: any;
  buttonText?: string;
  onPress: (event: GestureResponderEvent) => void;
}

const Cta: React.FC<CtaProps> = ({ cta, buttonText, onPress }) => {
  if (!cta || !buttonText || buttonText.trim() === '') return null;

  return (
    <View style={{ position: 'absolute', bottom: cta?.margin?.bottom, left: cta?.margin?.left, right: cta?.margin?.right, alignItems: mapAlignment(cta?.container?.alignment) }}>
      <Pressable
        style={({ pressed }) => ({
          backgroundColor: cta?.container?.backgroundColor,
          borderColor: cta?.container?.borderColor,
          borderWidth: cta?.container?.borderWidth,
          borderTopEndRadius: cta?.cornerRadius?.topRight,
          borderTopStartRadius: cta?.cornerRadius?.topLeft,
          borderBottomEndRadius: cta?.cornerRadius?.bottomRight,
          borderBottomStartRadius: cta?.cornerRadius?.bottomLeft,
          height: cta?.container?.height,
          width: cta?.container?.ctaFullWidth ? '100%' : cta?.container?.ctaWidth,
          justifyContent: 'center', alignItems: 'center',
          opacity: pressed ? 0.85 : 1,
        })}
        onPress={onPress}
      >
        <Text style={{ color: cta?.text?.color, fontSize: cta?.text?.fontSize, fontFamily: cta?.text?.fontFamily, fontWeight: cta?.text?.fontDecoration?.includes('bold') ? 'bold' : 'normal', fontStyle: cta?.text?.fontDecoration?.includes('italic') ? 'italic' : 'normal', textDecorationLine: cta?.text?.fontDecoration?.includes('underline') ? 'underline' : 'none', textAlign: 'center' }}>
          {personalizeText(buttonText)}
        </Text>
      </Pressable>
    </View>
  );
};

export default Cta;
