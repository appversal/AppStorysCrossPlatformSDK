// Full Survey UI — data from KMP ScreenContext instead of Zustand useCampaigns
import { Animated, Dimensions, Easing, Image, Modal, ScrollView, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { useEffect, useRef, useState, useMemo } from 'react';
import trackEvent from '../domain/actions/trackEvent';
import AppStorys from '../index';
import useScreen from '../domain/screen/useScreen';

const getFontStyles = (decoration: string[] = [], defaultWeight: '400' | '500' | '700' = '400') => ({
  fontWeight: decoration.includes('bold') ? ('700' as const) : defaultWeight,
  fontStyle: decoration.includes('italic') ? ('italic' as const) : ('normal' as const),
  textDecorationLine: decoration.includes('underline') ? ('underline' as const) : decoration.includes('line-through') ? ('line-through' as const) : ('none' as const),
});

export default function Survey() {
  const { height, width } = Dimensions.get('window');
  const [showSurvey, setShowSurvey] = useState(false);
  const [selectedOptions, setSelectedOptions] = useState<string[]>([]);
  const [otherText, setOtherText] = useState('');
  const [currentSlideIndex, setCurrentSlideIndex] = useState(0);
  const [isFinished, setIsFinished] = useState(false);
  const slideAnim = useRef(new Animated.Value(height)).current;

  const { campaigns } = useScreen();
  const data = campaigns.find((c) => c.campaign_type === 'SUR') as any;
  const sortedSlides = useMemo(() => {
    if (!data?.details?.slides) return [];
    return [...data.details.slides].sort((a: any, b: any) => (a.order || 0) - (b.order || 0));
  }, [data?.details?.slides]);

  const animateIn = () => Animated.timing(slideAnim, { toValue: 0, duration: 500, useNativeDriver: true, easing: Easing.out(Easing.exp) }).start();

  useEffect(() => {
    if (data && data.id && !viewed.has(data.id)) {
      try {
        const displayDelay = (data.details?.styling as any)?.appearance?.displayDelay ?? 0;
        const delay = typeof displayDelay === 'string' ? parseInt(displayDelay) : displayDelay;
        setTimeout(async () => {
          void trackEvent('viewed', data.id);
          setShowSurvey(true);
          animateIn();
          viewed.add(data.id);
        }, delay * 1000);
      } catch { }
    }
  }, [data]);

  const closeSurvey = () => Animated.timing(slideAnim, { toValue: height, duration: 400, useNativeDriver: true, easing: Easing.in(Easing.exp) }).start(() => setShowSurvey(false));

  const handleThankYouClick = () => {
    const config = data?.details?.thankYouButtonConfig;
    if (config?.enabled) {
      if (config.action === 'via-appstorys-campaign' && config.redirectUrl) {
        void AppStorys.trackEvent(`viaAppStorys${config.redirectUrl}`);
      } else if (config.redirectUrl) {
        AppStorys.handleNavigation(config.redirectUrl);
      }
    }
    closeSurvey();
  };

  const toggleOption = (value: string) => setSelectedOptions((prev) => prev.includes(value) ? prev.filter((i) => i !== value) : [...prev, value]);
  const currentSlide = sortedSlides[currentSlideIndex];

  const handleSubmit = () => {
    if (data && currentSlide && (selectedOptions.length > 0 || currentSlide.additionalComment?.enabled)) {
      void trackEvent('survey captured', data.details.id, { slideId: currentSlide.id, selectedOptions, otherText: otherText || '' });
      let nextSlideTarget: string | undefined;
      if (currentSlide.logic && Array.isArray(currentSlide.logic)) {
        for (const rule of currentSlide.logic) {
          if (rule.selectOption && rule.selectOption.some((opt: string) => selectedOptions.includes(opt))) { nextSlideTarget = rule.redirectTo; break; }
        }
      }
      if (nextSlideTarget === 'thank-you') { setIsFinished(true); setSelectedOptions([]); setOtherText(''); return; }
      else if (nextSlideTarget) {
        const nextIndex = sortedSlides.findIndex((s: any) => s.id === nextSlideTarget);
        if (nextIndex !== -1) { setCurrentSlideIndex(nextIndex); setSelectedOptions([]); setOtherText(''); return; }
      }
      if (currentSlideIndex < sortedSlides.length - 1) { setCurrentSlideIndex((prev) => prev + 1); setSelectedOptions([]); setOtherText(''); }
      else if (data.details.styling?.content?.isThankyouPage) setIsFinished(true);
      else closeSurvey();
    }
  };

  if (!showSurvey || !data || !data.details) return null;
  if (!isFinished && !currentSlide) return null;

  const styling = data.details.styling || {};
  const appearance = styling.appearance || {};
  const crossBtnStyle = styling.crossButton?.color || {};
  const ctaStyle = styling.cta || {};
  const titleStyle = styling.title?.textStyle || {};
  const subtitleStyle = styling.subtitle?.textStyle || {};
  const optionsStyle = styling.options || {};
  const thankYouPage = styling.thankyouPage || {};

  const getBackdropColor = () => {
    const baseColor = appearance.backdropColor || '#000000';
    const opacity = appearance.backdropOpacity != null ? Number(appearance.backdropOpacity) / 100 : 0.4;
    if (baseColor.startsWith('#')) { const r = parseInt(baseColor.slice(1, 3), 16); const g = parseInt(baseColor.slice(3, 5), 16); const b = parseInt(baseColor.slice(5, 7), 16); return `rgba(${r},${g},${b},${opacity})`; }
    return baseColor;
  };

  const romanNumerals = ['i','ii','iii','iv','v','vi','vii','viii','ix','x'];
  const surveyOptions = currentSlide?.options ? Object.entries(currentSlide.options).map(([_, value], index) => {
    const stylePrefix = optionsStyle.optionListStyle?.toLowerCase() || 'alphabet';
    let prefix = '';
    if (stylePrefix === 'alphabet') prefix = String.fromCharCode(97 + index) + '.';
    else if (stylePrefix === 'bullet' || stylePrefix === 'bulleted') prefix = '•';
    else if (stylePrefix === 'roman') prefix = (romanNumerals[index] || (index + 1)) + '.';
    else prefix = (index + 1) + '.';
    return { id: prefix, name: value as string };
  }) : [];
  if (currentSlide?.additionalComment?.enabled) surveyOptions.push({ id: String.fromCharCode(65 + surveyOptions.length), name: 'Others' });

  return (
    <Modal visible={true} transparent={true} animationType="none" onRequestClose={closeSurvey}>
      <View style={{ position: 'absolute', height, width, backgroundColor: getBackdropColor() }}>
        <Animated.View style={{ position: 'absolute', bottom: 0, width, maxHeight: height * 0.85, backgroundColor: appearance.backgroundColor || '#FFFFFF', borderTopLeftRadius: appearance.cornerRadius?.topLeft || 18, borderTopRightRadius: appearance.cornerRadius?.topRight || 18, transform: [{ translateY: slideAnim }], paddingHorizontal: 20, paddingTop: 16, paddingBottom: 60 }}>
          <TouchableOpacity activeOpacity={0.7} style={{ position: 'absolute', right: (styling.crossButton?.margin?.right !== undefined) ? Number(styling.crossButton.margin.right) : 10, top: (styling.crossButton?.margin?.top !== undefined) ? Number(styling.crossButton.margin.top) : 10, backgroundColor: crossBtnStyle.fill || 'transparent', borderColor: crossBtnStyle.stroke || 'transparent', borderWidth: crossBtnStyle.stroke ? 1 : 0, padding: 10, borderRadius: 25, zIndex: 10 }} onPress={closeSurvey}>
            <Image source={require('../assets/images/close.png')} style={{ tintColor: crossBtnStyle.cross || '#000000', width: styling.crossButton?.size || 12, height: styling.crossButton?.size || 12 }} />
          </TouchableOpacity>

          {isFinished ? (
            <View style={{ width: '100%', alignItems: 'center' }}>
              {data.details.thankYouImage && <Image source={{ uri: data.details.thankYouImage }} style={{ width: thankYouPage.imageStyle?.width || 80, height: thankYouPage.imageStyle?.height || 80, marginTop: thankYouPage.imageStyle?.margin?.top ?? 0, marginBottom: thankYouPage.imageStyle?.margin?.bottom ?? 16, borderRadius: (thankYouPage.imageStyle?.width || 80) / 2 }} />}
              <Text style={{ color: thankYouPage.title?.textStyle?.color || titleStyle.color || '#111827', fontSize: thankYouPage.title?.textStyle?.fontSize || 22, fontWeight: '700', textAlign: thankYouPage.title?.textStyle?.textAlign || 'center', marginBottom: 8, width: '100%' }}>{data.details.thankYouTitle || 'Thank You!'}</Text>
              <Text style={{ color: thankYouPage.subtitle?.textStyle?.color || subtitleStyle.color || '#6B7280', fontSize: thankYouPage.subtitle?.textStyle?.fontSize || 16, textAlign: thankYouPage.subtitle?.textStyle?.textAlign || 'center', marginBottom: 24, width: '100%' }}>{data.details.thankYouText || 'We appreciate your feedback.'}</Text>
              <TouchableOpacity activeOpacity={0.7} onPress={handleThankYouClick} style={{ backgroundColor: (thankYouPage.cta || ctaStyle).container?.backgroundColor || '#1f35db', borderTopLeftRadius: (thankYouPage.cta || ctaStyle).cornerRadius?.topLeft ?? 12, borderTopRightRadius: (thankYouPage.cta || ctaStyle).cornerRadius?.topRight ?? 12, borderBottomLeftRadius: (thankYouPage.cta || ctaStyle).cornerRadius?.bottomLeft ?? 12, borderBottomRightRadius: (thankYouPage.cta || ctaStyle).cornerRadius?.bottomRight ?? 12, paddingVertical: 20, paddingHorizontal: 16, width: '100%', alignItems: 'center', justifyContent: 'center' }}>
                <Text style={{ color: (thankYouPage.cta || ctaStyle).text?.color || '#ffffff', fontSize: (thankYouPage.cta || ctaStyle).text?.fontSize || 18, textAlign: 'center', ...getFontStyles((thankYouPage.cta || ctaStyle).text?.fontDecoration, '500') }}>{data.details.thankYouButtonText || 'Done'}</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <ScrollView showsVerticalScrollIndicator={false} style={{ flex: 1 }} contentContainerStyle={{ flexGrow: 1, paddingBottom: 45 }}>
              {currentSlide?.title && currentSlide.title !== currentSlide.question ? <View style={{ justifyContent: 'center', marginBottom: titleStyle.margin?.bottom || 12, marginTop: titleStyle.margin?.top || 0 }}><Text style={{ color: titleStyle.color || '#111827', fontSize: titleStyle.fontSize || 20, textAlign: titleStyle.textAlign || 'center', ...getFontStyles(titleStyle.fontDecoration, '500') }}>{currentSlide.title}</Text></View> : null}
              <Text style={{ color: titleStyle.color || '#111827', fontSize: titleStyle.fontSize || 20, textAlign: titleStyle.textAlign || 'left', ...getFontStyles(titleStyle.fontDecoration, '700'), marginBottom: titleStyle.margin?.bottom || 12 }}>{currentSlide?.question}</Text>
              {currentSlide?.subtitle ? <Text style={{ color: subtitleStyle.color || '#6B7280', fontSize: subtitleStyle.fontSize || 16, textAlign: subtitleStyle.textAlign || 'left', ...getFontStyles(subtitleStyle.fontDecoration), marginBottom: subtitleStyle.margin?.bottom || 16 }}>{currentSlide.subtitle}</Text> : null}
              {surveyOptions.map((option: any, index: number) => {
                const isSelected = selectedOptions.includes(option.name);
                const currentOptionStyle = isSelected ? optionsStyle.selectedOptions : optionsStyle.nonSelectedOptions;
                const currentColors = currentOptionStyle?.colors || {};
                return (
                  <TouchableOpacity key={`${option.id}-${index}`} activeOpacity={0.7} onPress={() => toggleOption(option.name)} style={{ marginBottom: optionsStyle.bulletSpacing || optionsStyle.optionsSpacing || 12, padding: 16, flexDirection: 'row', alignItems: 'center', backgroundColor: currentColors.background || (isSelected ? '#F3F4F6' : '#FFFFFF'), borderColor: currentColors.border || (isSelected ? '#111827' : '#E5E7EB'), borderWidth: 1, borderTopLeftRadius: optionsStyle.cornerRadius?.topLeft ?? 12, borderTopRightRadius: optionsStyle.cornerRadius?.topRight ?? 12, borderBottomLeftRadius: optionsStyle.cornerRadius?.bottomLeft ?? 12, borderBottomRightRadius: optionsStyle.cornerRadius?.bottomRight ?? 12 }}>
                    {optionsStyle.optionListStyle?.toLowerCase() === 'bulleted' && (
                      <View style={{ width: 20, height: 20, borderRadius: 10, borderWidth: 1.5, borderColor: isSelected ? (currentColors.border || '#111827') : '#D1D5DB', justifyContent: 'center', alignItems: 'center', marginRight: 12 }}>
                        {isSelected && <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: currentColors.text || '#111827' }} />}
                      </View>
                    )}
                    <Text style={{ color: currentColors.text || '#111827', fontSize: currentOptionStyle?.textStyle?.fontSize || 14, fontWeight: '500', flex: 1 }}>
                      {optionsStyle.optionListStyle?.toLowerCase() !== 'bulleted' && <Text style={{ fontWeight: '700' }}>{option.id} </Text>}
                      {option.name}
                    </Text>
                  </TouchableOpacity>
                );
              })}
              {selectedOptions.includes('Others') && <TextInput style={{ height: height * 0.057, marginBottom: width * 0.04, backgroundColor: optionsStyle.additionalComments?.colors?.background || 'white', borderRadius: 8, borderWidth: 2.5, borderColor: optionsStyle.additionalComments?.colors?.border || '#E5E7EB', paddingHorizontal: height * 0.015, color: optionsStyle.additionalComments?.colors?.text || 'black' }} placeholder={currentSlide?.additionalComment?.placeholder || 'Please enter Others text…'} placeholderTextColor="black" value={otherText} onChangeText={setOtherText} maxLength={200} />}
              <TouchableOpacity activeOpacity={0.7} onPress={handleSubmit} style={{ backgroundColor: ctaStyle.container?.backgroundColor || '#1f35db', borderTopLeftRadius: ctaStyle.cornerRadius?.topLeft ?? 12, borderTopRightRadius: ctaStyle.cornerRadius?.topRight ?? 12, borderBottomLeftRadius: ctaStyle.cornerRadius?.bottomLeft ?? 12, borderBottomRightRadius: ctaStyle.cornerRadius?.bottomRight ?? 12, paddingVertical: 14, paddingHorizontal: 16, width: '100%', alignItems: 'center', justifyContent: 'center', marginTop: ctaStyle.margin?.top || 0 }}>
                <Text style={{ color: ctaStyle.text?.color || '#ffffff', fontSize: ctaStyle.text?.fontSize || 18, ...getFontStyles(ctaStyle.text?.fontDecoration, '500') }}>{currentSlide?.submitButtonText || 'SUBMIT'}</Text>
              </TouchableOpacity>
              {sortedSlides.length > 0 && <View style={{ flexDirection: 'row', justifyContent: 'center', marginTop: 16, marginBottom: 12 }}>{sortedSlides.map((_: any, i: number) => <View key={i} style={{ width: i === currentSlideIndex ? 14 : 6, height: 6, borderRadius: 3, backgroundColor: i === currentSlideIndex ? '#111827' : '#E5E7EB', marginHorizontal: 3 }} />)}</View>}
            </ScrollView>
          )}
        </Animated.View>
      </View>
    </Modal>
  );
}

export { Survey };
const viewed = new Set<string>();

