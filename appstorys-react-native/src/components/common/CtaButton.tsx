import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { personalizeText } from '../../domain/actions/utils/personalization';

interface CtaButtonProps {
  element: any;
  onPress: (link?: string) => void;
  isBts?: boolean;
}

const CtaButton: React.FC<CtaButtonProps> = ({ element, onPress, isBts = false }) => {
  const parseColor = (colorStr?: string, defaultColor: string = '#000000'): string => {
    if (!colorStr) return defaultColor;
    try {
      if (colorStr.startsWith('#')) return colorStr;
      return colorStr.startsWith('#') ? colorStr : `#${colorStr}`;
    } catch {
      return defaultColor;
    }
  };

  const getJustifyContent = (alignment?: string): 'flex-start' | 'flex-end' | 'center' => {
    switch (alignment) {
      case 'left': return 'flex-start';
      case 'right': return 'flex-end';
      default: return 'center';
    }
  };

  const safeParse = (val: any, fallback: number) => {
    const parsed = parseFloat(val);
    return (!isNaN(parsed) && parsed > 0) ? parsed : fallback;
  };

  const ctaConfig = element.cta;
  const ctaContainer = ctaConfig?.container || {};
  const ctaTextConfig = ctaConfig?.text || {};

  const buttonColor = parseColor(ctaContainer.ctaBoxColor ?? element.ctaBoxColor, '#000000');
  const textColor = parseColor(ctaTextConfig.color ?? element.ctaTextColour, '#FFFFFF');
  const backgroundColor = parseColor(ctaContainer.backgroundColor ?? element.ctaBackgroundColor, 'transparent');
  const borderColor = parseColor(ctaContainer.borderColor, '#000000');

  const genericRadius = safeParse(element.ctaBorderRadius, 5);
  const corners = ctaConfig?.cornerRadius || {};

  const getRadius = (val: any) => {
    const parsed = parseFloat(val);
    return isNaN(parsed) ? (genericRadius || 0) : parsed;
  };

  const borderTopLeftRadius = getRadius(corners.topLeft);
  const borderTopRightRadius = getRadius(corners.topRight);
  const borderBottomLeftRadius = getRadius(corners.bottomLeft);
  const borderBottomRightRadius = getRadius(corners.bottomRight);

  const buttonHeight = safeParse(ctaContainer.height ?? element.ctaHeight, 50);
  const buttonWidth = safeParse(ctaContainer.ctaWidth ?? element.ctaWidth, 100);
  const fontSize = safeParse(ctaTextConfig.fontSize ?? element.ctaFontSize, 14);

  const rawDecoration = ctaTextConfig.fontDecoration ?? element.ctaFontDecoration;
  const checkDecoration = (type: string) => {
    if (Array.isArray(rawDecoration)) return rawDecoration.includes(type);
    if (typeof rawDecoration === 'string') return rawDecoration.includes(type);
    return false;
  };

  const ctaFullWidth = ctaContainer.ctaFullWidth ?? element.ctaFullWidth;
  const margins = ctaConfig?.margin || {};
  const marginTop = parseFloat(margins.top ?? element.marginTop ?? '0');
  const marginBottom = parseFloat(margins.bottom ?? element.marginBottom ?? '0');
  const marginLeft = parseFloat(margins.left ?? element.marginLeft ?? '0');
  const marginRight = parseFloat(margins.right ?? element.marginRight ?? '0');
  const alignment = ctaContainer.alignment ?? element.alignment;

  return (
    <View style={[styles.ctaContainer, {
      width: ctaFullWidth ? 'auto' : '100%',
      backgroundColor: isBts ? backgroundColor : 'transparent',
      paddingLeft: isBts ? marginLeft : parseFloat(element.paddingLeft || '0'),
      paddingRight: isBts ? marginRight : parseFloat(element.paddingRight || '0'),
      paddingTop: isBts ? marginTop : parseFloat(element.paddingTop || '0'),
      paddingBottom: isBts ? marginBottom : parseFloat(element.paddingBottom || '0'),
      marginTop: isBts ? undefined : marginTop,
      marginBottom: isBts ? undefined : marginBottom,
      marginLeft: isBts ? undefined : marginLeft,
      marginRight: isBts ? undefined : marginRight,
      justifyContent: getJustifyContent(alignment),
    }]}>
      <TouchableOpacity
        onPress={() => onPress(element.ctaLink)}
        activeOpacity={1}
        style={[styles.ctaButton, {
          backgroundColor: isBts ? buttonColor : backgroundColor,
          height: buttonHeight,
          width: ctaFullWidth ? '100%' : buttonWidth,
          borderWidth: parseFloat(ctaContainer.borderWidth ?? 0),
          borderColor,
          borderTopLeftRadius,
          borderTopRightRadius,
          borderBottomLeftRadius,
          borderBottomRightRadius,
        }]}
      >
        <Text style={[styles.ctaText, {
          color: textColor,
          fontSize,
          fontWeight: checkDecoration('bold') ? 'bold' : 'normal',
          fontStyle: checkDecoration('italic') ? 'italic' : 'normal',
          textDecorationLine: checkDecoration('underline') ? 'underline' : 'none',
          fontFamily: ctaTextConfig.fontFamily,
        }]}>
          {personalizeText(element.ctaText || 'Click')}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  ctaContainer: { width: '100%', alignItems: 'center' },
  ctaButton: { justifyContent: 'center', alignItems: 'center' },
  ctaText: { textAlign: 'center' },
});

export default CtaButton;
