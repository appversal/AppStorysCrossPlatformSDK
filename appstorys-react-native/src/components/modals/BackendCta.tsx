import { StyleSheet, Text, TouchableOpacity } from 'react-native';
import { personalizeText } from '../../domain/actions/utils/personalization';

interface BackendCtaProps {
  text: string;
  height: number;
  width?: number;
  occupyFullWidth?: boolean;
  backgroundColor: string;
  textColor: string;
  textSizeSp: number;
  borderColor?: string;
  borderWidth?: number;
  cornerRadius: { topLeft: number; topRight: number; bottomLeft: number; bottomRight: number };
  textAlign?: string;
  buttonAlignment?: string;
  fontWeight?: string;
  fontStyle?: string;
  fontFamily?: string;
  textDecoration?: string[];
  onClick: () => void;
}

export default function BackendCta({
  text, height, width, occupyFullWidth = false, backgroundColor, textColor, textSizeSp,
  borderColor = 'transparent', borderWidth = 0, cornerRadius, textAlign = 'center',
  buttonAlignment, fontWeight, fontStyle, fontFamily, textDecoration = [], onClick,
}: BackendCtaProps) {
  const parseColor = (color: string): string => {
    if (!color) return '#000000';
    const cleaned = color.trim();
    if (cleaned.startsWith('#') || cleaned.startsWith('rgb') || cleaned.startsWith('rgba')) return cleaned;
    const isHex = /^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?([0-9a-fA-F]{2})?$/.test(cleaned);
    if (isHex) return `#${cleaned}`;
    return cleaned;
  };

  const getTextAlign = (): 'left' | 'center' | 'right' => {
    const align = (buttonAlignment || textAlign)?.toLowerCase();
    if (align === 'left' || align === 'flex-start') return 'left';
    if (align === 'right' || align === 'flex-end') return 'right';
    return 'center';
  };

  const getFontWeight = (): any => {
    const w = fontWeight?.toLowerCase();
    if (w === 'bold' || w === '700' || w === '800') return 'bold';
    if (w === '600') return '600';
    if (w === '500') return '500';
    return 'normal';
  };

  const getTextDecorationLine = (): any => {
    if (textDecoration.some((d) => d.toLowerCase() === 'underline')) return 'underline';
    if (textDecoration.some((d) => d.toLowerCase() === 'line-through')) return 'line-through';
    return 'none';
  };

  return (
    <TouchableOpacity
      activeOpacity={0.7}
      onPress={onClick}
      style={[
        styles.button,
        {
          height,
          width: occupyFullWidth ? undefined : width,
          backgroundColor: parseColor(backgroundColor),
          borderColor: parseColor(borderColor),
          borderWidth,
          borderTopLeftRadius: cornerRadius.topLeft,
          borderTopRightRadius: cornerRadius.topRight,
          borderBottomLeftRadius: cornerRadius.bottomLeft,
          borderBottomRightRadius: cornerRadius.bottomRight,
        },
        occupyFullWidth && styles.fullWidth,
      ]}
    >
      <Text style={[styles.text, {
        color: parseColor(textColor),
        fontSize: textSizeSp,
        textAlign: getTextAlign(),
        fontWeight: getFontWeight(),
        fontStyle: fontStyle?.toLowerCase() === 'italic' ? 'italic' : 'normal',
        fontFamily,
        textDecorationLine: getTextDecorationLine(),
      }]} numberOfLines={1}>
        {personalizeText(text)}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: { justifyContent: 'center', alignItems: 'center', paddingHorizontal: 16 },
  fullWidth: { width: '100%' },
  text: { textAlign: 'center' },
});
