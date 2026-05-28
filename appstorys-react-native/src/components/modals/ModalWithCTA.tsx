import { useState } from 'react';
import { ActivityIndicator, Modal, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import ModalMediaRenderer from './ModalMediaRenderer';
import BackendCta from './BackendCta';
import CrossButton from '../common/CrossButton';
import { personalizeText } from '../../domain/actions/utils/personalization';

interface ModalWithCTAProps {
  modal: any;
  onClose: () => void;
  onPrimaryCta?: (link?: string) => void;
  onSecondaryCta?: (link?: string) => void;
}

const getFontStyles = (decoration: string[], defaultWeight: '400' | '600' = '400') => ({
  fontWeight: decoration.includes('bold') ? ('700' as const) : defaultWeight,
  fontStyle: decoration.includes('italic') ? ('italic' as const) : ('normal' as const),
  textDecorationLine: decoration.includes('underline') ? ('underline' as const) : decoration.includes('line-through') ? ('line-through' as const) : ('none' as const),
});

const parseColor = (colorStr?: string, defaultColor: string = '#000000'): string => {
  if (!colorStr) return defaultColor;
  const cleaned = colorStr.trim();
  if (cleaned.startsWith('#') || cleaned.startsWith('rgb') || cleaned.startsWith('rgba')) return cleaned;
  const isHex = /^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?([0-9a-fA-F]{2})?$/.test(cleaned);
  if (isHex) return `#${cleaned}`;
  return cleaned;
};

export default function ModalWithCTA({ modal, onClose, onPrimaryCta, onSecondaryCta }: ModalWithCTAProps) {
  const [isMediaLoaded, setIsMediaLoaded] = useState(false);
  const [mediaAspectRatio, setMediaAspectRatio] = useState<number | undefined>(undefined);

  const appearance = modal.styling?.appearance;
  const dimension = appearance?.dimension;
  const modalWidth = dimension?.width ? (typeof dimension.width === 'string' && dimension.width.includes('%') ? dimension.width : parseFloat(dimension.width)) : 340;

  const cornerRadius = appearance?.cornerRadius;
  const borderRadiusStyle = {
    borderTopLeftRadius: parseFloat(cornerRadius?.topLeft || '0'),
    borderTopRightRadius: parseFloat(cornerRadius?.topRight || '0'),
    borderBottomLeftRadius: parseFloat(cornerRadius?.bottomLeft || '0'),
    borderBottomRightRadius: parseFloat(cornerRadius?.bottomRight || '0'),
  };

  const backgroundColor = parseColor(appearance?.backgroundColor, '#FFFFFF');
  const backdrop = appearance?.backdrop;
  let backdropColor = backdrop?.color || appearance?.backdropColor || '#000000';
  if (backdropColor.toLowerCase() === 'black') backdropColor = '#000000';
  if (backdropColor.toLowerCase() === 'white') backdropColor = '#FFFFFF';
  const backdropOpacity = parseFloat(backdrop?.opacity || appearance?.backdropOpacity || '50') / 100;
  const backdropEnabled = appearance?.enableBackdrop ?? true;

  const padding = appearance?.padding;
  const contentPadding = {
    paddingLeft: parseFloat(padding?.left || '0'),
    paddingRight: parseFloat(padding?.right || '0'),
    paddingTop: parseFloat(padding?.top || '0'),
    paddingBottom: parseFloat(padding?.bottom || '0'),
  };

  const crossButton = modal.styling?.crossButton;
  const crossEnabled = crossButton?.enabled ?? crossButton?.enableCrossButton ?? true;
  const crossColors = crossButton?.color || crossButton?.default?.color;
  const crossMargin = crossButton?.margin || crossButton?.default?.spacing?.margin;
  const crossConfig = {
    color: { fill: crossColors?.fill || 'rgba(0,0,0,0.6)', cross: crossColors?.cross || '#FFFFFF', stroke: crossColors?.stroke || 'transparent' },
    enabled: crossEnabled,
    image: crossButton?.image || crossButton?.uploadImage?.url || crossButton?.default?.crossButtonImage || '',
    margin: { top: crossMargin?.top || 0, right: crossMargin?.right || 0, bottom: crossMargin?.bottom || 0, left: crossMargin?.left || 0 },
    size: crossButton?.size || crossButton?.default?.size || 32,
  };

  const mediaUrl = modal.content?.chooseMediaType?.url || modal.chooseMediaType?.url || modal.resolvedMedia?.url || modal.url;
  const getTextAlign = (alignment?: string): 'left' | 'center' | 'right' | 'auto' => {
    const a = alignment?.trim()?.toLowerCase();
    if (a === 'left') return 'left';
    if (a === 'right') return 'right';
    return 'center';
  };

  const titleDecoration = modal.styling?.title?.fontDecoration || [];
  const subtitleDecoration = modal.styling?.subTitle?.fontDecoration || [];
  const hasContent = modal.content?.titleText || modal.content?.subtitleText || modal.content?.primaryCtaText || modal.content?.secondaryCtaText;

  return (
    <Modal visible={true} transparent={true} animationType="fade" onRequestClose={onClose}>
      <View style={[styles.overlay, { backgroundColor: backdropEnabled ? `${backdropColor}${Math.round(backdropOpacity * 255).toString(16).padStart(2, '0')}` : 'transparent' }]}>
        <TouchableOpacity style={StyleSheet.absoluteFill} activeOpacity={1} onPress={onClose} />
        <View style={[styles.modalContainer, { width: modalWidth, borderWidth: parseFloat(dimension?.borderWidth || '0'), borderColor: appearance?.borderColor || 'transparent', ...borderRadiusStyle }]}>
          <View style={[styles.contentContainer, borderRadiusStyle, { backgroundColor }]}>
            {mediaUrl && (
              <View style={[styles.mediaSection, { aspectRatio: mediaAspectRatio || 16 / 9 }]}>
                {crossEnabled && <CrossButton config={crossConfig} onPress={onClose} style={{ position: 'absolute', top: 0, right: 0, zIndex: 10 }} />}
                {!isMediaLoaded && <View style={styles.loadingContainer}><ActivityIndicator size="large" color="#999999" /></View>}
                <View style={{ flex: 1, borderTopLeftRadius: borderRadiusStyle.borderTopLeftRadius, borderTopRightRadius: borderRadiusStyle.borderTopRightRadius, overflow: 'hidden' }}>
                  <View style={{ opacity: isMediaLoaded ? 1 : 0, flex: 1 }}>
                    <ModalMediaRenderer mediaUrl={mediaUrl} mediaType={modal.content?.chooseMediaType?.type || modal.chooseMediaType?.type} style={{ width: '100%', height: '100%' }} contentScale="contain" muted={false} onLoadEnd={() => setIsMediaLoaded(true)} onError={() => setIsMediaLoaded(true)} onDimensions={(w, h) => { if (w && h) setMediaAspectRatio(w / h); }} />
                  </View>
                </View>
              </View>
            )}
            {hasContent && (
              <View style={[styles.textSection, contentPadding]}>
                {modal.content?.titleText && (
                  <>
                    <View style={{ height: 12 }} />
                    <Text style={{ color: parseColor(modal.styling?.title?.color), fontSize: modal.styling?.title?.fontSize || 16, textAlign: getTextAlign(modal.styling?.title?.textAlign), fontFamily: modal.styling?.title?.fontFamily, paddingHorizontal: 16, ...getFontStyles(titleDecoration) }}>
                      {personalizeText(modal.content.titleText)}
                    </Text>
                  </>
                )}
                {modal.content?.subtitleText && (
                  <>
                    <View style={{ height: 6 }} />
                    <Text style={{ color: parseColor(modal.styling?.subTitle?.color), fontSize: modal.styling?.subTitle?.fontSize || 12, textAlign: getTextAlign(modal.styling?.subTitle?.textAlign), fontFamily: modal.styling?.subTitle?.fontFamily, paddingHorizontal: 16, ...getFontStyles(subtitleDecoration) }}>
                      {personalizeText(modal.content.subtitleText)}
                    </Text>
                  </>
                )}
                <ModalCtaRow modal={modal} onPrimaryCta={onPrimaryCta} onSecondaryCta={onSecondaryCta} />
              </View>
            )}
          </View>
        </View>
      </View>
    </Modal>
  );
}

function ModalCtaRow({ modal, onPrimaryCta, onSecondaryCta }: { modal: any; onPrimaryCta?: (link?: string) => void; onSecondaryCta?: (link?: string) => void }) {
  const primaryText = modal.content?.primaryCtaText;
  const secondaryText = modal.content?.secondaryCtaText;
  const hasPrimary = primaryText && primaryText.trim() !== '';
  const hasSecondary = secondaryText && secondaryText.trim() !== '';
  if (!hasPrimary && !hasSecondary) return null;

  const primaryStyling = modal.styling?.primaryCta;
  const secondaryStyling = modal.styling?.secondaryCta;
  const primaryContainer = primaryStyling?.container || {};
  const primaryTextStyle = primaryStyling?.text || {};
  const secondaryContainer = secondaryStyling?.container || {};
  const secondaryTextStyle = secondaryStyling?.text || {};
  const primaryOccupy = hasPrimary && (primaryContainer.occupyFullWidth?.toString() === 'true' || primaryStyling?.occupyFullWidth?.trim() === 'true' || primaryContainer.ctaFullWidth === true);
  const secondaryOccupy = hasSecondary && (secondaryContainer.occupyFullWidth?.toString() === 'true' || secondaryStyling?.occupyFullWidth?.trim() === 'true' || secondaryContainer.ctaFullWidth === true);
  const primaryMargin = primaryStyling?.margin || primaryStyling?.spacing?.margin;
  const secondaryMargin = secondaryStyling?.margin || secondaryStyling?.spacing?.margin;
  const isAnyFullWidth = primaryOccupy || secondaryOccupy;
  const maxMarginTop = Math.max(hasPrimary ? primaryMargin?.top || 0 : 0, hasSecondary ? secondaryMargin?.top || 0 : 0);
  const maxMarginBottom = Math.max(hasPrimary ? primaryMargin?.bottom || 0 : 0, hasSecondary ? secondaryMargin?.bottom || 0 : 0);
  const p = (c?: string) => { if (!c) return '#000000'; if (c.startsWith('#')) return c; return `#${c}`; };

  return (
    <View style={[styles.ctaRow, { marginTop: maxMarginTop, marginBottom: maxMarginBottom }]}>
      {hasPrimary && (
        <View style={[{ marginLeft: primaryMargin?.left || 0, marginRight: primaryMargin?.right || 0 }, isAnyFullWidth && { flex: 1 }]}>
          <BackendCta text={primaryText} height={primaryContainer.height || 40} width={primaryContainer.ctaWidth} occupyFullWidth={isAnyFullWidth} backgroundColor={p(primaryContainer.backgroundColor || primaryStyling?.backgroundColor)} textColor={primaryTextStyle.color || '#FFFFFF'} textSizeSp={primaryTextStyle.fontSize || 14} borderColor={p(primaryContainer.borderColor || primaryStyling?.borderColor)} borderWidth={primaryContainer.borderWidth ?? 0} cornerRadius={{ topLeft: primaryStyling?.cornerRadius?.topLeft || 12, topRight: primaryStyling?.cornerRadius?.topRight || 12, bottomLeft: primaryStyling?.cornerRadius?.bottomLeft || 12, bottomRight: primaryStyling?.cornerRadius?.bottomRight || 12 }} textAlign={primaryContainer.alignment || 'center'} fontFamily={primaryTextStyle.fontFamily} textDecoration={primaryTextStyle.fontDecoration || []} fontWeight={getFontStyles(primaryTextStyle.fontDecoration || []).fontWeight} fontStyle={getFontStyles(primaryTextStyle.fontDecoration || []).fontStyle} onClick={() => onPrimaryCta?.(modal.content?.primaryCtaRedirection?.url || modal.content?.primaryCtaRedirection?.value)} />
        </View>
      )}
      {hasSecondary && (
        <View style={[{ marginLeft: secondaryMargin?.left || 0, marginRight: secondaryMargin?.right || 0 }, isAnyFullWidth && { flex: 1 }]}>
          <BackendCta text={secondaryText} height={secondaryContainer.height || 40} width={secondaryContainer.ctaWidth} occupyFullWidth={isAnyFullWidth} backgroundColor={p(secondaryContainer.backgroundColor || secondaryStyling?.backgroundColor)} textColor={secondaryTextStyle.color || '#FFFFFF'} textSizeSp={secondaryTextStyle.fontSize || 14} borderColor={p(secondaryContainer.borderColor || secondaryStyling?.borderColor)} borderWidth={secondaryContainer.borderWidth ?? 0} cornerRadius={{ topLeft: secondaryStyling?.cornerRadius?.topLeft || 12, topRight: secondaryStyling?.cornerRadius?.topRight || 12, bottomLeft: secondaryStyling?.cornerRadius?.bottomLeft || 12, bottomRight: secondaryStyling?.cornerRadius?.bottomRight || 12 }} textAlign={secondaryContainer.alignment || 'center'} fontFamily={secondaryTextStyle.fontFamily} textDecoration={secondaryTextStyle.fontDecoration || []} fontWeight={getFontStyles(secondaryTextStyle.fontDecoration || []).fontWeight} fontStyle={getFontStyles(secondaryTextStyle.fontDecoration || []).fontStyle} onClick={() => onSecondaryCta?.(modal.content?.secondaryCtaRedirection?.url || modal.content?.secondaryCtaRedirection?.value)} />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  modalContainer: { overflow: 'visible' },
  contentContainer: { overflow: 'hidden' },
  mediaSection: { width: '100%' },
  loadingContainer: { ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F5F5F5' },
  textSection: { width: '100%' },
  ctaRow: { flexDirection: 'row', width: '100%', justifyContent: 'center', alignItems: 'center' },
});
