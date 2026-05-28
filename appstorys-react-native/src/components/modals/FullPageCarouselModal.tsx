import { useRef, useState } from 'react';
import { ActivityIndicator, Dimensions, FlatList, Modal, StyleSheet, Text, View } from 'react-native';
import ModalMediaRenderer from './ModalMediaRenderer';
import BackendCta from './BackendCta';
import CrossButton from '../common/CrossButton';
import { personalizeText } from '../../domain/actions/utils/personalization';

interface FullPageCarouselModalProps {
  modalDetails: any;
  onClose: () => void;
  onModalClick: () => void;
  onPrimaryCta?: (link?: string) => void;
  onSecondaryCta?: (link?: string) => void;
}

const parseColor = (colorStr?: string): string => {
  if (!colorStr) return '#000000';
  const cleaned = colorStr.trim();
  if (cleaned.startsWith('#') || cleaned.startsWith('rgb') || cleaned.startsWith('rgba')) return cleaned;
  const isHex = /^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?([0-9a-fA-F]{2})?$/.test(cleaned);
  if (isHex) return `#${cleaned}`;
  return cleaned;
};

const getFontStyles = (decoration: string[], defaultWeight: '400' | '600' = '400') => ({
  fontWeight: decoration.includes('bold') ? ('700' as const) : defaultWeight,
  fontStyle: decoration.includes('italic') ? ('italic' as const) : ('normal' as const),
  textDecorationLine: decoration.includes('underline') ? ('underline' as const) : decoration.includes('line-through') ? ('line-through' as const) : ('none' as const),
});

export default function FullPageCarouselModal({ modalDetails, onClose, onPrimaryCta, onSecondaryCta }: FullPageCarouselModalProps) {
  const { width } = Dimensions.get('window');
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loadedSlides, setLoadedSlides] = useState<Set<number>>(new Set());
  const flatListRef = useRef<FlatList>(null);

  const modal = modalDetails.modals?.[0];
  if (!modal) return null;

  const slides = modal.content?.set?.length > 0 ? modal.content.set : modal.content ? [modal.content] : [];
  if (slides.length === 0) return null;

  const currentSlide = slides[currentIndex];
  const slideAppearance = currentSlide?.styling?.appearance;
  const globalAppearance = modal.styling?.appearance;

  let backdropColor = slideAppearance?.backdrop?.color || slideAppearance?.backdropColor || globalAppearance?.backdrop?.color || globalAppearance?.backdropColor || '#000000';
  if (backdropColor.toLowerCase() === 'black') backdropColor = '#000000';
  if (backdropColor.toLowerCase() === 'white') backdropColor = '#FFFFFF';
  const backdropOpacity = parseFloat(String(slideAppearance?.backdropOpacity || '30')) / 100;
  const backdropEnabled = (slideAppearance?.enableBackdrop ?? globalAppearance?.enableBackdrop) !== false;
  const finalBackdropColor = backdropEnabled ? `${backdropColor}${Math.round(backdropOpacity * 255).toString(16).padStart(2, '0')}` : 'transparent';

  const effectiveCrossButton = currentSlide?.styling?.crossButton || modal.styling?.crossButton;
  const crossImageUrl = effectiveCrossButton?.image || effectiveCrossButton?.uploadImage?.url || effectiveCrossButton?.default?.crossButtonImage;
  const crossConfig = {
    color: { fill: effectiveCrossButton?.color?.fill || 'rgba(0,0,0,0.6)', cross: effectiveCrossButton?.color?.cross || '#FFFFFF', stroke: effectiveCrossButton?.color?.stroke || 'transparent' },
    enabled: effectiveCrossButton?.enabled !== false,
    image: crossImageUrl || '',
    margin: { top: effectiveCrossButton?.margin?.top ?? 4, right: effectiveCrossButton?.margin?.right ?? 4, bottom: effectiveCrossButton?.margin?.bottom ?? 4, left: effectiveCrossButton?.margin?.left ?? 4 },
    size: effectiveCrossButton?.size || 32,
  };

  const rawContentEnable = currentSlide?.enableCrossButton ?? modal.content?.enableCrossButton;
  const contentEnable = rawContentEnable != null ? String(rawContentEnable).trim() === 'true' : null;
  const showCross = contentEnable ?? (effectiveCrossButton?.enabled !== false);

  const onViewableItemsChanged = useRef<any>(({ viewableItems }: any) => {
    if (viewableItems?.[0] && typeof viewableItems[0].index === 'number') setCurrentIndex(viewableItems[0].index);
  }).current;
  const viewabilityConfig = useRef({ itemVisiblePercentThreshold: 50 }).current;

  const isFirstSlideLoaded = loadedSlides.has(0);

  return (
    <Modal visible={true} transparent={true} animationType="fade" onRequestClose={onClose}>
      <View style={[styles.container, { backgroundColor: finalBackdropColor, opacity: isFirstSlideLoaded ? 1 : 0 }]}>
        <View style={styles.mediaSection}>
          <FlatList
            ref={flatListRef}
            data={slides}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={{ flexGrow: 1 }}
            style={{ flex: 1 }}
            keyExtractor={(_, index) => `slide-${index}`}
            onViewableItemsChanged={onViewableItemsChanged}
            viewabilityConfig={viewabilityConfig}
            renderItem={({ item: slide, index }) => (
              <View style={{ width, flex: 1 }}>
                <View style={styles.slideMediaContainer}>
                  <ModalMediaRenderer
                    mediaUrl={slide.chooseMediaType?.url}
                    mediaType={slide.chooseMediaType?.type}
                    style={styles.slideMedia}
                    contentScale="contain"
                    muted={false}
                    paused={index !== currentIndex}
                    onLoadEnd={() => setLoadedSlides((prev) => new Set(prev).add(index))}
                    onError={() => setLoadedSlides((prev) => new Set(prev).add(index))}
                  />
                </View>
              </View>
            )}
          />
          {slides.length > 1 && (
            <View style={styles.dotsContainer}>
              {slides.map((_: any, index: number) => (
                <View key={`dot-${index}`} style={[styles.dot, { backgroundColor: index === currentIndex ? '#FFFFFF' : 'rgba(255,255,255,0.5)', width: index === currentIndex ? 20 : 8 }]} />
              ))}
            </View>
          )}
        </View>

        <View style={styles.contentSection}>
          {currentSlide && (
            <CarouselSlideContent slide={currentSlide} modal={modal} onPrimaryCta={onPrimaryCta} onSecondaryCta={onSecondaryCta} />
          )}
        </View>

        {showCross && <View style={styles.crossButtonContainer}><CrossButton config={crossConfig} onPress={onClose} /></View>}
        {!isFirstSlideLoaded && <View style={styles.loadingOverlay}><ActivityIndicator size="large" color="#FFFFFF" /></View>}
      </View>
    </Modal>
  );
}

function CarouselSlideContent({ slide, modal, onPrimaryCta, onSecondaryCta }: { slide: any; modal: any; onPrimaryCta?: (link?: string) => void; onSecondaryCta?: (link?: string) => void }) {
  const getTextAlign = (alignment?: string): 'left' | 'center' | 'right' | 'auto' => {
    const a = alignment?.trim()?.toLowerCase();
    if (a === 'left') return 'left';
    if (a === 'right') return 'right';
    return 'center';
  };

  const titleDecoration = slide.styling?.title?.fontDecoration || modal.styling?.title?.fontDecoration || [];
  const subtitleDecoration = slide.styling?.subTitle?.fontDecoration || modal.styling?.subTitle?.fontDecoration || [];
  const primaryStyling = slide.styling?.primaryCta || modal.styling?.primaryCta;
  const secondaryStyling = slide.styling?.secondaryCta || modal.styling?.secondaryCta;
  const primaryText = slide.primaryCta || slide.primaryCtaText || modal.content?.primaryCta || modal.content?.primaryCtaText;
  const secondaryText = slide.secondayCta || slide.secondaryCtaText || slide.secondaryCtaAlt || modal.content?.secondayCta || modal.content?.secondaryCtaText;
  const primaryOccupy = primaryStyling?.container?.ctaFullWidth === true || primaryStyling?.occupyFullWidth?.trim() === 'true';
  const secondaryOccupy = secondaryStyling?.container?.ctaFullWidth === true || secondaryStyling?.occupyFullWidth?.trim() === 'true';

  return (
    <View style={styles.slideContent}>
      {slide.titleText && (
        <>
          <View style={{ height: 12 }} />
          <Text style={{ color: parseColor(slide.styling?.title?.color || modal.styling?.title?.color), fontSize: slide.styling?.title?.fontSize || modal.styling?.title?.fontSize || 16, textAlign: getTextAlign(slide.styling?.title?.textAlign || modal.styling?.title?.textAlign), fontFamily: slide.styling?.title?.fontFamily || modal.styling?.title?.fontFamily, paddingHorizontal: 16, width: '100%', ...getFontStyles(titleDecoration, '600') }}>
            {personalizeText(slide.titleText)}
          </Text>
        </>
      )}
      {slide.subtitleText && (
        <>
          <View style={{ height: 6 }} />
          <Text style={{ color: parseColor(slide.styling?.subTitle?.color || modal.styling?.subTitle?.color), fontSize: slide.styling?.subTitle?.fontSize || modal.styling?.subTitle?.fontSize || 12, textAlign: getTextAlign(slide.styling?.subTitle?.textAlign || modal.styling?.subTitle?.textAlign), fontFamily: slide.styling?.subTitle?.fontFamily || modal.styling?.subTitle?.fontFamily, paddingHorizontal: 16, width: '100%', ...getFontStyles(subtitleDecoration) }}>
            {personalizeText(slide.subtitleText)}
          </Text>
        </>
      )}
      <View style={{ height: 12 }} />
      <View style={styles.ctaRow}>
        {primaryText && (
          <View style={[{ marginLeft: primaryStyling?.margin?.left || 4, marginRight: primaryStyling?.margin?.right || 4, marginTop: primaryStyling?.margin?.top || 4, marginBottom: primaryStyling?.margin?.bottom || 4 }, primaryOccupy && { flex: 1 }]}>
            <BackendCta text={primaryText} height={primaryStyling?.container?.height || 40} width={primaryStyling?.container?.ctaWidth} occupyFullWidth={primaryOccupy} backgroundColor={parseColor(primaryStyling?.container?.backgroundColor)} textColor={primaryStyling?.text?.color || '#FFFFFF'} textSizeSp={primaryStyling?.text?.fontSize || 14} borderColor={parseColor(primaryStyling?.container?.borderColor)} borderWidth={primaryStyling?.container?.borderWidth || 0} cornerRadius={{ topLeft: primaryStyling?.cornerRadius?.topLeft || 16, topRight: primaryStyling?.cornerRadius?.topRight || 16, bottomLeft: primaryStyling?.cornerRadius?.bottomLeft || 16, bottomRight: primaryStyling?.cornerRadius?.bottomRight || 16 }} textAlign={primaryStyling?.container?.alignment || 'center'} fontFamily={primaryStyling?.text?.fontFamily} textDecoration={primaryStyling?.text?.fontDecoration || []} fontWeight={getFontStyles(primaryStyling?.text?.fontDecoration || []).fontWeight} fontStyle={getFontStyles(primaryStyling?.text?.fontDecoration || []).fontStyle} onClick={() => onPrimaryCta?.(slide.primaryCtaRedirection?.url || slide.primaryCtaRedirection?.value)} />
          </View>
        )}
        {secondaryText && (
          <View style={[{ marginLeft: secondaryStyling?.margin?.left || 4, marginRight: secondaryStyling?.margin?.right || 4, marginTop: secondaryStyling?.margin?.top || 4, marginBottom: secondaryStyling?.margin?.bottom || 4 }, secondaryOccupy && { flex: 1 }]}>
            <BackendCta text={secondaryText} height={secondaryStyling?.container?.height || 40} width={secondaryStyling?.container?.ctaWidth} occupyFullWidth={secondaryOccupy} backgroundColor={parseColor(secondaryStyling?.container?.backgroundColor)} textColor={secondaryStyling?.text?.color || '#FFFFFF'} textSizeSp={secondaryStyling?.text?.fontSize || 14} borderColor={parseColor(secondaryStyling?.container?.borderColor)} borderWidth={secondaryStyling?.container?.borderWidth || 0} cornerRadius={{ topLeft: secondaryStyling?.cornerRadius?.topLeft || 16, topRight: secondaryStyling?.cornerRadius?.topRight || 16, bottomLeft: secondaryStyling?.cornerRadius?.bottomLeft || 16, bottomRight: secondaryStyling?.cornerRadius?.bottomRight || 16 }} textAlign={secondaryStyling?.container?.alignment || 'center'} fontFamily={secondaryStyling?.text?.fontFamily} textDecoration={secondaryStyling?.text?.fontDecoration || []} fontWeight={getFontStyles(secondaryStyling?.text?.fontDecoration || []).fontWeight} fontStyle={getFontStyles(secondaryStyling?.text?.fontDecoration || []).fontStyle} onClick={() => onSecondaryCta?.(slide.secondaryCtaRedirection?.url || slide.secondaryCtaRedirection?.value)} />
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  mediaSection: { flex: 1, position: 'relative' },
  slideMediaContainer: { flex: 1, justifyContent: 'flex-end', alignItems: 'center' },
  slideMedia: { width: '100%', height: '100%' },
  dotsContainer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', paddingVertical: 12 },
  dot: { height: 8, borderRadius: 4, marginHorizontal: 3 },
  contentSection: { paddingHorizontal: 16, paddingBottom: 24, paddingTop: 12 },
  slideContent: { width: '100%' },
  ctaRow: { flexDirection: 'row', width: '100%', justifyContent: 'flex-start', alignItems: 'center' },
  crossButtonContainer: { position: 'absolute', top: 20, right: 50, zIndex: 20 },
  loadingOverlay: { ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.5)' },
});
