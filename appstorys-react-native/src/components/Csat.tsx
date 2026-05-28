import { useEffect, useRef, useState } from 'react';
import { Image, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View, Animated, Dimensions, Easing, Pressable } from 'react-native';
import LottieView from 'lottie-react-native';
import CrossButton from './common/CrossButton';
import trackEvent from '../domain/actions/trackEvent';
import usePadding from '../domain/hooks/usePadding';
import { personalizeText } from '../domain/actions/utils/personalization';
import AppStorys from '../index';
import useScreen from '../domain/screen/useScreen';

const SCREEN_HEIGHT = Dimensions.get('window').height;

export default function Csat() {
  // KMP: read campaign from ScreenContext
  const { campaigns } = useScreen();
  const data = campaigns.find((c) => c.campaign_type === 'CSAT') as any;
  const padding = usePadding('CSAT')?.bottom || 0;

  const [showCsat, setShowCsat] = useState(false);
  const [selectedStars, setSelectedStars] = useState(0);
  const [showThanks, setShowThanks] = useState(false);
  const [showFeedback, setShowFeedback] = useState(false);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [additionalComments, setAdditionalComments] = useState('');

  const slideAnim = useRef(new Animated.Value(SCREEN_HEIGHT)).current;
  const scrollViewRef = useRef<ScrollView>(null);
  const textInputRef = useRef<TextInput>(null);

  useEffect(() => {
    if (data && data.id && !viewed.has(data.id)) {
      try {
        const displayDelay = (data.details?.styling as any)?.appearance?.displayDelay ?? 0;
        const delay = typeof displayDelay === 'string' ? parseInt(displayDelay) : displayDelay;
        setTimeout(async () => {
          void trackEvent('viewed', data.id);
          setShowCsat(true);
          animateIn();
          viewed.add(data.id);
        }, delay * 1000);
      } catch { }
    }
  }, [data]);

  const animateIn = () => {
    Animated.timing(slideAnim, { toValue: 0, duration: 500, useNativeDriver: true, easing: Easing.out(Easing.exp) }).start();
  };

  const handleClose = () => {
    Animated.timing(slideAnim, { toValue: SCREEN_HEIGHT, duration: 400, useNativeDriver: true, easing: Easing.in(Easing.exp) }).start(() => setShowCsat(false));
  };

  const handleStarPress = (index: number) => {
    const starCount = index + 1;
    setSelectedStars(starCount);
    if (starCount >= 4) {
      setTimeout(() => {
        setShowThanks(true);
        if (data) void trackEvent('csat captured', data.details.id, { starCount, selectedOption: selectedOption || '', additionalComments: additionalComments || '' });
      }, 1000);
    } else {
      setShowFeedback(true);
    }
  };

  const handleSubmitFeedback = () => {
    if (data) void trackEvent('csat captured', data.details.id, { starCount: selectedStars, selectedOption: selectedOption || '', additionalComments: additionalComments || '' });
    setShowThanks(true);
  };

  if (!showCsat || !data || !data.details) return null;

  const getFontStyles = (decoration: string[] = [], defaultWeight: '400' | '600' = '400') => ({
    fontWeight: decoration.includes('bold') ? ('700' as const) : defaultWeight,
    fontStyle: decoration.includes('italic') ? ('italic' as const) : ('normal' as const),
    textDecorationLine: decoration.includes('underline') ? ('underline' as const) : decoration.includes('line-through') ? ('line-through' as const) : ('none' as const),
  });

  const CsatButton = ({ config, text, onPress }: { config: any; text: string; onPress: () => void }) => {
    if (!config) return null;
    return (
      <View style={{ marginTop: config.margin?.top ?? 0, marginBottom: config.margin?.bottom ?? 0, paddingLeft: config.margin?.left ?? 0, paddingRight: config.margin?.right ?? 0, width: '100%', alignItems: config.container?.alignment === 'center' ? 'center' : config.container?.alignment === 'right' ? 'flex-end' : 'flex-start' }}>
        <Pressable onPress={onPress} style={({ pressed }) => ({ backgroundColor: config.container?.backgroundColor, borderColor: config.container?.borderColor, borderWidth: config.container?.borderWidth ?? (config.container?.borderColor ? 1 : 0), borderTopEndRadius: config.cornerRadius?.topRight, borderTopStartRadius: config.cornerRadius?.topLeft, borderBottomEndRadius: config.cornerRadius?.bottomRight, borderBottomStartRadius: config.cornerRadius?.bottomLeft, minHeight: Math.max(config.container?.height || 0, 40), width: config.container?.ctaFullWidth ? '100%' : config.container?.ctaWidth, justifyContent: 'center', alignItems: 'center', opacity: pressed ? 0.85 : 1, paddingVertical: 12, paddingHorizontal: 16 })}>
          <Text style={{ color: config.text?.color, fontSize: config.text?.fontSize, fontFamily: config.text?.fontFamily, textAlign: 'center', textAlignVertical: 'center', includeFontPadding: false, ...getFontStyles(config.text?.fontDecoration) }}>{personalizeText(text)}</Text>
        </Pressable>
      </View>
    );
  };

  const styling = data.details.styling as any;
  const appearance = styling?.appearance;
  const feedbackPage = styling?.feedbackPage;
  const ratingStyle = styling?.rating;
  const initialFeedback = styling?.initialFeedback;
  const thankyouPage = styling?.thankyouPage;

  const feedbackOptions = Object.entries(data.details.feedback_option || {}).map(([key, value]) => ({ id: key, name: value }));
  const fontSize = typeof styling?.fontSize === 'string' ? parseInt(styling.fontSize) : (styling?.fontSize || 12);
  const isLottie = data.details.thankyouImage?.endsWith('.json');
  const thankYouTitle = (selectedStars > 3 ? ratingStyle?.highRatingTitle : ratingStyle?.lowRatingTitle) || data.details.thankyouText || (selectedStars > 3 ? 'Thanks for the love' : 'Thanks for the feedback');
  const thankYouDescription = (selectedStars > 3 ? ratingStyle?.highRatingSubtitle : ratingStyle?.lowRatingSubtitle) || data.details.thankyouDescription;
  const doneText = thankyouPage?.doneButton?.text?.trim() ? thankyouPage.doneButton.text : selectedStars > 3 ? data.details.highStarText || 'Done' : data.details.lowStarText || 'Done';

  const crossBtn = styling?.crossButton;
  const crossBtnConfig = crossBtn ? { color: { fill: crossBtn.color?.fill || 'rgba(0,0,0,0.6)', cross: crossBtn.color?.cross || '#FFFFFF', stroke: crossBtn.color?.stroke || 'transparent' }, enabled: crossBtn.enabled !== false, image: crossBtn.image || '', margin: crossBtn.margin || { top: 0, right: 0, bottom: 0, left: 0 }, size: crossBtn.size || 18 } : undefined;

  const containerStyle: any = { bottom: padding + (appearance?.margin?.bottom ?? 10), left: appearance?.margin?.left ?? 10, right: appearance?.margin?.right ?? 10 };

  return (
    <Animated.View style={[styles.container, containerStyle, { transform: [{ translateY: slideAnim }] }]}>
      <View style={[styles.card, { backgroundColor: appearance?.backgroundColor || '#FFFFFF', borderRadius: appearance?.borderRadius, paddingTop: appearance?.padding?.top, paddingBottom: appearance?.padding?.bottom, paddingLeft: appearance?.padding?.left, paddingRight: appearance?.padding?.right }]}>
        {crossBtnConfig && <CrossButton config={crossBtnConfig} style={{ position: 'absolute', top: 0, right: 0 }} onPress={handleClose} />}
        <ScrollView ref={scrollViewRef} keyboardShouldPersistTaps="handled" contentContainerStyle={{ flexGrow: 1 }}>
          {showThanks ? (
            <View style={styles.thanksContainer}>
              {data.details.thankyouImage && (
                <View style={{ width: '100%', alignItems: 'center', marginTop: thankyouPage?.imageStyle?.margin?.top ?? 0, marginBottom: thankyouPage?.imageStyle?.margin?.bottom ?? 0, paddingLeft: thankyouPage?.imageStyle?.margin?.left ?? 0, paddingRight: thankyouPage?.imageStyle?.margin?.right ?? 0 }}>
                  {isLottie ? <LottieView source={{ uri: data.details.thankyouImage }} autoPlay loop={true} style={{ width: thankyouPage?.imageStyle?.width ?? '100%', height: thankyouPage?.imageStyle?.height ?? 200 }} /> : <Image source={{ uri: data.details.thankyouImage }} resizeMode={thankyouPage?.imageStyle?.resizeMode || 'contain'} style={{ width: thankyouPage?.imageStyle?.width ?? '100%', height: thankyouPage?.imageStyle?.height ?? 200 }} />}
                </View>
              )}
              {thankYouTitle ? <Text style={[styles.thanksTitle, { color: thankyouPage?.title?.textStyle?.color || '#FE6B35', fontSize: thankyouPage?.title?.textStyle?.fontSize ?? (fontSize + 6), fontFamily: thankyouPage?.title?.textStyle?.fontFamily, textAlign: (thankyouPage?.title?.textStyle?.textAlign as any) || 'center', ...getFontStyles(thankyouPage?.title?.textStyle?.fontDecoration) }]}>{personalizeText(thankYouTitle)}</Text> : null}
              {thankYouDescription ? <Text style={[styles.thanksDescription, { color: thankyouPage?.subtitle?.textStyle?.color || '#FE6B35', fontSize: thankyouPage?.subtitle?.textStyle?.fontSize ?? fontSize, fontFamily: thankyouPage?.subtitle?.textStyle?.fontFamily, textAlign: (thankyouPage?.subtitle?.textStyle?.textAlign as any) || 'center', ...getFontStyles(thankyouPage?.subtitle?.textStyle?.fontDecoration) }]}>{personalizeText(thankYouDescription)}</Text> : null}
              {thankyouPage?.doneButton?.cta && (
                <CsatButton config={{ ...thankyouPage.doneButton.cta, container: { ...thankyouPage.doneButton.cta?.container, borderWidth: thankyouPage.doneButton.cta?.container?.borderWidth ?? (thankyouPage.doneButton.cta?.container?.borderColor ? 1 : 0), height: Math.max(thankyouPage.doneButton.cta?.container?.height || 0, 40) }, margin: { ...thankyouPage.doneButton.cta?.margin }, text: { ...thankyouPage.doneButton.cta?.text, fontDecoration: thankyouPage.doneButton.cta?.text?.fontDecoration ?? ['bold'] } }} text={doneText} onPress={() => { handleClose(); if (selectedStars > 3) AppStorys.handleNavigation(data.details.link); }} />
              )}
            </View>
          ) : (
            <View>
              <Text style={[styles.title, { color: initialFeedback?.title?.textStyle?.color || '#161413', fontSize: initialFeedback?.title?.textStyle?.fontSize ?? 16, fontFamily: initialFeedback?.title?.textStyle?.fontFamily, textAlign: (initialFeedback?.title?.textStyle?.textAlign as any) || 'center', paddingRight: 18, ...getFontStyles(initialFeedback?.title?.textStyle?.fontDecoration, '600') }]}>{personalizeText(data.details.title)}</Text>
              <Text style={[styles.description, { color: initialFeedback?.subtitle?.textStyle?.color || '#32302f', fontSize: initialFeedback?.subtitle?.textStyle?.fontSize ?? fontSize, fontFamily: initialFeedback?.subtitle?.textStyle?.fontFamily, textAlign: (initialFeedback?.subtitle?.textStyle?.textAlign as any) || 'center', paddingRight: 18, ...getFontStyles(initialFeedback?.subtitle?.textStyle?.fontDecoration) }]}>{personalizeText(data.details.description_text)}</Text>
              <RatingComponent ratingStyle={ratingStyle} selectedRating={selectedStars} onRatingSelected={handleStarPress} />
              {showFeedback && (
                <View style={styles.feedbackContainer}>
                  {feedbackOptions.map((option: any) => (
                    <TouchableOpacity activeOpacity={0.7} key={option.id} style={[styles.optionButton, { backgroundColor: selectedOption === option.name ? feedbackPage?.options?.selectedOptions?.colors?.background || '#ededed' : feedbackPage?.options?.nonSelectedOptions?.colors?.background || '#ededed', borderColor: selectedOption === option.name ? feedbackPage?.options?.selectedOptions?.colors?.border || '#050505' : feedbackPage?.options?.nonSelectedOptions?.colors?.border || '#050505' }]} onPress={() => setSelectedOption(option.name)}>
                      <Text style={[styles.optionText, { color: selectedOption === option.name ? feedbackPage?.options?.selectedOptions?.textStyle?.color || '#f2870d' : feedbackPage?.options?.nonSelectedOptions?.textStyle?.color || '#f2870d', fontSize: feedbackPage?.options?.nonSelectedOptions?.textStyle?.fontSize ?? fontSize, fontFamily: feedbackPage?.options?.nonSelectedOptions?.textStyle?.fontFamily, textAlign: (feedbackPage?.options?.nonSelectedOptions?.textStyle?.textAlign as any) || 'center' }]}>{personalizeText(option.name)}</Text>
                    </TouchableOpacity>
                  ))}
                  {feedbackOptions.length > 0 && <View style={{ height: 12 }} />}
                  {feedbackPage?.additionalComments?.enabled !== false && (
                    <View style={[styles.inputContainer, { backgroundColor: feedbackPage?.additionalComments?.colors?.background || '#ededed', borderColor: feedbackPage?.additionalComments?.colors?.border || '#050505' }]}>
                      <TextInput ref={textInputRef} style={[styles.input, { color: feedbackPage?.additionalComments?.colors?.text || '#f2870d', fontSize: feedbackPage?.additionalComments?.textStyle?.fontSize ?? 12, fontFamily: feedbackPage?.additionalComments?.textStyle?.fontFamily }]} value={additionalComments} onChangeText={setAdditionalComments} placeholder="Enter comments" placeholderTextColor="#808080" multiline textAlignVertical="top" onFocus={() => setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 300)} />
                    </View>
                  )}
                  {feedbackPage?.submitButton && (
                    <CsatButton config={{ ...feedbackPage.submitButton.cta, container: { ...feedbackPage.submitButton.cta?.container, backgroundColor: feedbackPage.submitButton.cta?.container?.backgroundColor || '#f7f7f7', borderColor: feedbackPage.submitButton.cta?.container?.borderColor || '#050505', borderWidth: feedbackPage.submitButton.cta?.container?.borderWidth ?? (feedbackPage.submitButton.cta?.container?.borderColor ? 1 : 0) }, margin: { ...feedbackPage.submitButton.cta?.margin, top: feedbackPage.submitButton.cta?.margin?.top ?? 18 }, text: { ...feedbackPage.submitButton.cta?.text, color: feedbackPage.submitButton.cta?.text?.color || '#f2870d', fontSize: feedbackPage.submitButton.cta?.text?.fontSize ?? 12, fontDecoration: feedbackPage.submitButton.cta?.text?.fontDecoration ?? ['bold'] } }} text={feedbackPage.submitButton.text || 'Submit'} onPress={handleSubmitFeedback} />
                  )}
                </View>
              )}
            </View>
          )}
        </ScrollView>
      </View>
    </Animated.View>
  );
}

export { Csat };

const RatingComponent = ({ ratingStyle, selectedRating, onRatingSelected }: { ratingStyle: any; selectedRating: number; onRatingSelected: (index: number) => void }) => {
  const ratingType = ratingStyle?.ratingType?.toLowerCase() || 'star';
  const alignment = ratingStyle?.alignment?.toLowerCase() || 'center';
  const containerStyle = { flexDirection: 'row' as const, marginTop: 12, justifyContent: alignment === 'left' ? 'flex-start' as const : alignment === 'right' ? 'flex-end' as const : 'center' as const };
  if (ratingType === 'emoji') return <EmojiRating ratingStyle={ratingStyle} selectedRating={selectedRating} onRatingSelected={onRatingSelected} containerStyle={containerStyle} />;
  if (ratingType === 'number') return <NumberRating ratingStyle={ratingStyle} selectedRating={selectedRating} onRatingSelected={onRatingSelected} containerStyle={containerStyle} />;
  return <StarRating ratingStyle={ratingStyle} selectedRating={selectedRating} onRatingSelected={onRatingSelected} containerStyle={containerStyle} />;
};

const StarRating = ({ ratingStyle, selectedRating, onRatingSelected, containerStyle }: { ratingStyle: any; selectedRating: number; onRatingSelected: (index: number) => void; containerStyle: any }) => (
  <View style={containerStyle}>
    {Array.from({ length: 5 }).map((_, index) => {
      const isSelected = index < selectedRating;
      const isHighRatingMode = selectedRating >= 4;
      const unselectedColor = ratingStyle?.unselected?.background || ratingStyle?.star?.unselected?.stylingStar?.background || '#CCCCCC';
      const highColor = ratingStyle?.high?.background || ratingStyle?.star?.high?.stylingStar?.background || '#FFD700';
      const lowColor = ratingStyle?.low?.background || ratingStyle?.star?.low?.stylingStar?.background || '#FF6B6B';
      const starColor = !isSelected ? unselectedColor : isHighRatingMode ? highColor : lowColor;
      const unselectedBorderColor = ratingStyle?.unselected?.border || ratingStyle?.star?.unselected?.stylingStar?.border || 'transparent';
      const highBorderColor = ratingStyle?.high?.border || ratingStyle?.star?.high?.stylingStar?.border || 'transparent';
      const lowBorderColor = ratingStyle?.low?.border || ratingStyle?.star?.low?.stylingStar?.border || 'transparent';
      const borderColor = !isSelected ? unselectedBorderColor : isHighRatingMode ? highBorderColor : lowBorderColor;
      const borderWidth = !isSelected ? (ratingStyle?.unselected?.borderWidth || 0) : isHighRatingMode ? (ratingStyle?.high?.borderWidth || 0) : (ratingStyle?.low?.borderWidth || 0);
      return (
        <TouchableOpacity key={index} onPress={() => onRatingSelected(index)} activeOpacity={1} style={{ position: 'relative', width: 40, height: 40, marginRight: index < 4 ? 8 : 0, justifyContent: 'center', alignItems: 'center' }}>
          {borderWidth > 0 && <Image source={require('../assets/images/star.png')} style={{ position: 'absolute', tintColor: borderColor, width: 34 + (borderWidth * 3), height: 34 + (borderWidth * 3) }} />}
          <Image source={require('../assets/images/star.png')} style={{ tintColor: starColor, width: 34, height: 34 }} />
        </TouchableOpacity>
      );
    })}
  </View>
);

const EmojiRating = ({ ratingStyle, selectedRating, onRatingSelected, containerStyle }: { ratingStyle: any; selectedRating: number; onRatingSelected: (index: number) => void; containerStyle: any }) => {
  const emojiConfig = ratingStyle?.emoji;
  const emojis = emojiConfig?.values || ['😢', '😕', '😐', '🙂', '😄'];
  return (
    <View style={containerStyle}>
      {emojis.map((emoji: string, index: number) => {
        const isSelected = index === selectedRating - 1;
        return (
          <TouchableOpacity key={index} onPress={() => onRatingSelected(index)} activeOpacity={1} style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: isSelected ? (emojiConfig?.selected?.stylingContainer?.fill || '#fff3ed') : (emojiConfig?.unselected?.stylingContainer?.fill || '#f0f0f0'), borderWidth: isSelected ? (emojiConfig?.selected?.stylingContainer?.borderWidth || 2) : (emojiConfig?.unselected?.stylingContainer?.borderWidth || 1), borderColor: isSelected ? (emojiConfig?.selected?.stylingContainer?.border || '#FE6B35') : (emojiConfig?.unselected?.stylingContainer?.border || '#cccccc'), justifyContent: 'center', alignItems: 'center', marginRight: index < emojis.length - 1 ? 8 : 0 }}>
            <Text style={{ fontSize: 24 }}>{emoji}</Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
};

const NumberRating = ({ ratingStyle, selectedRating, onRatingSelected, containerStyle }: { ratingStyle: any; selectedRating: number; onRatingSelected: (index: number) => void; containerStyle: any }) => {
  const numberConfig = ratingStyle?.number;
  const isHighRatingMode = selectedRating >= 4;
  return (
    <View style={containerStyle}>
      {Array.from({ length: 5 }).map((_, index) => {
        const isSelected = index < selectedRating;
        const containerFill = !isSelected ? (numberConfig?.unselected?.stylingContainer?.fill || '#ededed') : isHighRatingMode ? (numberConfig?.high?.stylingContainer?.fill || '#42e6f5') : (numberConfig?.low?.stylingContainer?.fill || '#87ff66');
        const containerBorder = !isSelected ? (numberConfig?.unselected?.stylingContainer?.border || '#FE6B35') : isHighRatingMode ? (numberConfig?.high?.stylingContainer?.border || '#f75555') : (numberConfig?.low?.stylingContainer?.border || '#ff4242');
        const borderWidth = !isSelected ? (numberConfig?.unselected?.stylingContainer?.borderWidth || 0) : isHighRatingMode ? (numberConfig?.high?.stylingContainer?.borderWidth || 0) : (numberConfig?.low?.stylingContainer?.borderWidth || 1);
        const textColor = !isSelected ? (numberConfig?.unselected?.stylingNumber?.text || numberConfig?.stylingNumber?.text || '#FE6B35') : (numberConfig?.stylingNumber?.text || '#000000');
        const textSize = numberConfig?.stylingNumber?.textSize || 16;
        return (
          <TouchableOpacity key={index} onPress={() => onRatingSelected(index)} activeOpacity={1} style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: containerFill, borderWidth, borderColor: containerBorder, justifyContent: 'center', alignItems: 'center', marginRight: index < 4 ? 8 : 0 }}>
            <Text style={{ fontSize: textSize > 0 ? textSize : 16, color: textColor, fontWeight: 'bold' }}>{index + 1}</Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { position: 'absolute' },
  card: {},
  thanksContainer: { alignItems: 'center' },
  thanksTitle: { fontWeight: 'bold', marginTop: 16 },
  thanksDescription: { marginTop: 4, textAlign: 'center' },
  title: { fontWeight: 'bold' },
  description: { marginTop: 4 },
  feedbackContainer: { marginTop: 16 },
  optionButton: { borderWidth: 1, borderRadius: 24, paddingVertical: 12, paddingHorizontal: 16, marginVertical: 4, width: '100%' },
  optionText: {},
  inputContainer: { height: 92, borderWidth: 1, borderRadius: 18, overflow: 'hidden' },
  input: { flex: 1, padding: 16 },
});

const viewed = new Set<string>();
