import { useEffect, useRef, useState } from 'react';
import {
  Animated, Dimensions, Easing, Image, Modal, PanResponder,
  ScrollView, StyleSheet, Text, TouchableOpacity, View,
} from 'react-native';
import trackEvent from '../domain/actions/trackEvent';
import CtaButton from './common/CtaButton';
import CrossButton from './common/CrossButton';
import LottieView from 'lottie-react-native';
import checkForCache from '../domain/actions/utils/checkForCache';
import { personalizeText } from '../domain/actions/utils/personalization';
import AppStorys from '../index';
import useScreen from '../domain/screen/useScreen';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');
const DRAG_THRESHOLD = 50;

export default function BottomSheet() {
  const [isBottomSheetVisible, setIsBottomSheetVisible] = useState(false);
  const [imageCache, setImageCache] = useState<Record<string, { path: string; ratio: number | null }>>({});
  const [lottieCache, setLottieCache] = useState<Record<string, { data: any; ratio: number | null }>>({});
  const slideAnim = useRef(new Animated.Value(SCREEN_HEIGHT)).current;
  const backdropOpacity = useRef(new Animated.Value(0)).current;
  const [isContentMeasured, setIsContentMeasured] = useState(false);

  const { campaigns } = useScreen();
  const campaignData = campaigns.find((c) => c.campaign_type === 'BTS') as any;
  const bottomSheetDetails = campaignData?.details || null;
  const elements = bottomSheetDetails?.elements?.sort((a: any, b: any) => (a.order || 0) - (b.order || 0)) || [];

  const imageElement = elements.find((el: any) => el.type === 'image');
  const bodyElements = elements.filter((el: any) => el.type === 'body');
  const ctaElements = elements.filter((el: any) => el.type === 'cta');

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: (_, g) => Math.abs(g.dy) > 10,
      onPanResponderMove: (_, g) => { if (g.dy > 0) slideAnim.setValue(Math.max(0, g.dy)); },
      onPanResponderRelease: (_, g) => {
        if (g.dy > DRAG_THRESHOLD || g.vy > 0.5) {
          handleDismissRequest();
        } else {
          Animated.spring(slideAnim, { toValue: 0, useNativeDriver: true, tension: 100, friction: 8 }).start();
        }
      },
    })
  ).current;

  const showBottomSheet = () => {
    setIsBottomSheetVisible(true);
    slideAnim.setValue(SCREEN_HEIGHT);
    backdropOpacity.setValue(0);
    Animated.parallel([
      Animated.timing(backdropOpacity, { toValue: 1, duration: 300, useNativeDriver: true, easing: Easing.out(Easing.quad) }),
      Animated.spring(slideAnim, { toValue: 0, useNativeDriver: true, tension: 100, friction: 8 }),
    ]).start();
  };

  const hideBottomSheet = () => {
    Animated.parallel([
      Animated.timing(backdropOpacity, { toValue: 0, duration: 200, useNativeDriver: true, easing: Easing.in(Easing.quad) }),
      Animated.timing(slideAnim, { toValue: SCREEN_HEIGHT, duration: 250, useNativeDriver: true, easing: Easing.in(Easing.quad) }),
    ]).start(() => {
      setIsBottomSheetVisible(false);
      setIsContentMeasured(false);
    });
  };

  useEffect(() => {
    if (campaignData?.id && bottomSheetDetails) {
      void trackEvent('viewed', campaignData.id);

      const isLottieUrl = (url?: string) => {
        if (!url) return false;
        return url.toLowerCase().endsWith('.json') || url.trimStart().startsWith('{') || url.trimStart().startsWith('[');
      };

      if (imageElement?.url) {
        if (isLottieUrl(imageElement.url)) {
          checkForCache(imageElement.url, 'video').then(async (result) => {
            if (result?.path) {
              try {
                const response = await fetch(result.path);
                const json = await response.json();
                let aspectRatio: number | null = null;
                if (json.w && json.h && json.w > 0) aspectRatio = json.h / json.w;
                setLottieCache((prev) => ({ ...prev, [imageElement.url!]: { data: json, ratio: aspectRatio } }));
              } catch { }
            }
          });
        } else {
          checkForCache(imageElement.url).then((result) => {
            if (result?.path) {
              setImageCache((prev) => ({ ...prev, [imageElement.url!]: { path: result.path, ratio: result.ratio } }));
            }
          });
        }
      }

      setTimeout(showBottomSheet, 100);
    }
  }, [campaignData?.id, bottomSheetDetails, imageElement?.url]);

  const handleDismissRequest = () => hideBottomSheet();

  const handleClick = (ctaLink?: string) => {
    if (ctaLink && campaignData?.id) {
      void trackEvent('clicked', campaignData.id);
      AppStorys.handleNavigation(ctaLink);
    }
  };

  const parseColor = (colorStr?: string, defaultColor = '#000000'): string => {
    if (!colorStr) return defaultColor;
    if (colorStr.startsWith('#')) return colorStr;
    return `#${colorStr}`;
  };

  const getTextAlign = (alignment?: string): 'left' | 'center' | 'right' => {
    if (alignment === 'left') return 'left';
    if (alignment === 'right') return 'right';
    return 'center';
  };

  const getJustifyContent = (alignment?: string): 'flex-start' | 'flex-end' | 'center' => {
    if (alignment === 'left') return 'flex-start';
    if (alignment === 'right') return 'flex-end';
    return 'center';
  };

  const renderImageElement = (element: any) => {
    const isLottieUrl = (url?: string) => {
      if (!url) return false;
      return url.toLowerCase().endsWith('.json') || url.trimStart().startsWith('{') || url.trimStart().startsWith('[');
    };
    const isLottie = isLottieUrl(element.url);
    const lottieCacheData = isLottie ? lottieCache[element.url] : null;
    const cachedData = !isLottie ? imageCache[element.url] : null;
    if (isLottie && !lottieCacheData) return null;
    if (!isLottie && !cachedData?.path) return null;

    const corners = element.cornerRadius || {};
    const getRadius = (val: any) => { const p = parseFloat(val); return isNaN(p) ? 0 : p; };
    const radii = {
      borderTopLeftRadius: getRadius(corners.topLeft),
      borderTopRightRadius: getRadius(corners.topRight),
      borderBottomLeftRadius: getRadius(corners.bottomLeft),
      borderBottomRightRadius: getRadius(corners.bottomRight),
    };
    const paddingStyle = {
      paddingLeft: parseFloat(element.paddingLeft || '0'),
      paddingRight: parseFloat(element.paddingRight || '0'),
      paddingTop: parseFloat(element.paddingTop || '0'),
      paddingBottom: parseFloat(element.paddingBottom || '0'),
      justifyContent: getJustifyContent(element.alignment),
    };

    if (isLottie) {
      const lottieAspectRatio = lottieCacheData!.ratio ? 1 / lottieCacheData!.ratio : 1;
      return (
        <TouchableOpacity key={`lottie-${element.order}`} onPress={() => handleClick(element.imageLink)} activeOpacity={1} style={[styles.imageContainer, paddingStyle]}>
          <LottieView source={lottieCacheData!.data} autoPlay loop style={[styles.image, { ...radii, overflow: 'hidden', aspectRatio: lottieAspectRatio }]} resizeMode="contain" />
        </TouchableOpacity>
      );
    }
    const aspectRatio = cachedData!.ratio ? 1 / cachedData!.ratio : 1.77;
    return (
      <TouchableOpacity key={`image-${element.order}`} onPress={() => handleClick(element.imageLink)} activeOpacity={1} style={[styles.imageContainer, paddingStyle]}>
        <Image source={{ uri: cachedData!.path }} style={[styles.image, { backgroundColor: 'transparent', ...radii, overflow: 'hidden', aspectRatio }]} resizeMode="cover" />
      </TouchableOpacity>
    );
  };

  const renderBodyElement = (element: any) => {
    const titleFontSize = parseFloat(element.titleFontSize || '16');
    const descriptionFontSize = parseFloat(element.descriptionFontSize || '14');
    const spacing = parseFloat(element.spacingBetweenTitleDesc || '8');
    const titleDecoration = element.titleFontStyle?.decoration || '';
    const descriptionDecoration = element.descriptionFontStyle?.decoration || '';
    return (
      <View key={`body-${element.order}`} style={[styles.bodyContainer, {
        backgroundColor: parseColor(element.bodyBackgroundColor, 'transparent'),
        paddingLeft: parseFloat(element.marginLeft || '0'),
        paddingRight: parseFloat(element.marginRight || '0'),
        paddingTop: parseFloat(element.marginTop || '0'),
        paddingBottom: parseFloat(element.marginBottom || '0'),
        alignItems: element.alignment === 'left' ? 'flex-start' : element.alignment === 'right' ? 'flex-end' : 'center',
      }]}>
        {element.titleText && (
          <Text style={[styles.titleText, {
            color: parseColor(element.titleFontStyle?.colour, '#000000'),
            fontSize: titleFontSize,
            textAlign: getTextAlign(element.alignment),
            fontWeight: titleDecoration.includes('bold') ? 'bold' : 'normal',
            fontStyle: titleDecoration.includes('italic') ? 'italic' : 'normal',
            textDecorationLine: titleDecoration.includes('underline') ? 'underline' : 'none',
            lineHeight: parseFloat(element.titleLineHeight || '1') * titleFontSize,
          }]}>{personalizeText(element.titleText)}</Text>
        )}
        {element.titleText && element.descriptionText && <View style={{ height: spacing }} />}
        {element.descriptionText && (
          <Text style={[styles.descriptionText, {
            color: parseColor(element.descriptionFontStyle?.colour, '#000000'),
            fontSize: descriptionFontSize,
            textAlign: getTextAlign(element.alignment),
            fontWeight: descriptionDecoration.includes('bold') ? 'bold' : 'normal',
            fontStyle: descriptionDecoration.includes('italic') ? 'italic' : 'normal',
            textDecorationLine: descriptionDecoration.includes('underline') ? 'underline' : 'none',
            lineHeight: parseFloat(element.descriptionLineHeight || '1') * descriptionFontSize,
          }]}>{personalizeText(element.descriptionText)}</Text>
        )}
      </View>
    );
  };

  const renderCTAElement = (element: any) => (
    <CtaButton isBts={true} key={`cta-${element.order}`} element={element} onPress={handleClick} />
  );

  const renderCTARow = () => {
    const leftCTA = ctaElements.find((el: any) => el.position === 'left');
    const rightCTA = ctaElements.find((el: any) => el.position === 'right');
    if (!leftCTA && !rightCTA) return null;
    return (
      <View key="cta-row" style={styles.ctaRow}>
        <View style={styles.ctaRowItem}>{leftCTA && renderCTAElement(leftCTA)}</View>
        <View style={styles.ctaRowItem}>{rightCTA && renderCTAElement(rightCTA)}</View>
      </View>
    );
  };

  if (!bottomSheetDetails || !campaignData) return null;

  const backdropColor = parseColor(bottomSheetDetails.backdropColor, '#000000');
  const parsedOpacity = Number(bottomSheetDetails.backdropOpacity);
  const targetBackdropOpacity = !isNaN(parsedOpacity) && parsedOpacity > 1 ? parsedOpacity / 100 : (!isNaN(parsedOpacity) ? parsedOpacity : 0.5);
  const hasOverlayButton = imageElement?.overlayButton === true;
  const centerCTAs = ctaElements.filter((el: any) => el.position === 'center' || !el.position);
  const crossButtonConfig = bottomSheetDetails.crossButton;

  return (
    <Modal visible={isBottomSheetVisible} transparent={true} animationType="none" onRequestClose={handleDismissRequest}>
      <View style={styles.overlay}>
        <Animated.View style={[styles.backdrop, {
          backgroundColor: backdropColor,
          opacity: backdropOpacity.interpolate({ inputRange: [0, 1], outputRange: [0, targetBackdropOpacity] }),
        }]}>
          <TouchableOpacity style={styles.backdropTouchable} onPress={handleDismissRequest} activeOpacity={1} />
        </Animated.View>

        <Animated.View style={[styles.bottomSheetContainer, { transform: [{ translateY: slideAnim }] }]} {...panResponder.panHandlers}>
          <View style={{
            borderTopLeftRadius: bottomSheetDetails.cornerRadius?.topLeft || 12,
            borderTopRightRadius: bottomSheetDetails.cornerRadius?.topRight || 12,
            overflow: 'hidden',
            backgroundColor: 'transparent',
          }}>
            <ScrollView
              style={styles.scrollView}
              showsVerticalScrollIndicator={false}
              bounces={false}
              onContentSizeChange={(_, contentHeight) => {
                if (!isContentMeasured && contentHeight > 0) setIsContentMeasured(true);
              }}
            >
              {hasOverlayButton ? (
                <View style={styles.overlayContainer}>
                  {imageElement && renderImageElement(imageElement)}
                  <View style={styles.overlayContent}>
                    {bodyElements.map(renderBodyElement)}
                    {renderCTARow()}
                    {centerCTAs.map(renderCTAElement)}
                  </View>
                </View>
              ) : (
                <View style={styles.normalContainer}>
                  {imageElement && renderImageElement(imageElement)}
                  {bodyElements.map(renderBodyElement)}
                  {renderCTARow()}
                  {centerCTAs.map(renderCTAElement)}
                </View>
              )}
            </ScrollView>
          </View>

          {crossButtonConfig && crossButtonConfig.enabled && (
            <CrossButton config={crossButtonConfig} onPress={handleDismissRequest} style={{ position: 'absolute', top: 0, right: 0 }} />
          )}
        </Animated.View>
      </View>
    </Modal>
  );
}

export { BottomSheet };

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end' },
  backdrop: { ...StyleSheet.absoluteFillObject },
  backdropTouchable: { flex: 1 },
  bottomSheetContainer: { backgroundColor: 'transparent', overflow: 'visible' },
  scrollView: { flexGrow: 0, flexShrink: 1 },
  overlayContainer: { position: 'relative' },
  overlayContent: { position: 'absolute', bottom: 0, left: 0, right: 0, backgroundColor: 'transparent' },
  normalContainer: { backgroundColor: 'transparent' },
  imageContainer: { backgroundColor: 'transparent', width: '100%', alignItems: 'center' },
  image: { width: '100%', height: undefined },
  bodyContainer: { width: '100%' },
  titleText: { width: '100%' },
  descriptionText: { width: '100%' },
  ctaRow: { flexDirection: 'row', width: '100%' },
  ctaRowItem: { flex: 1 },
});
