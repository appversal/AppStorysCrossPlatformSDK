import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Dimensions, FlatList, Image, NativeScrollEvent, NativeSyntheticEvent,
  TouchableOpacity, View,
} from 'react-native';
import LottieView from 'lottie-react-native';
import useScreen from '../domain/screen/useScreen';
import trackEvent from '../domain/actions/trackEvent';
import checkForCache from '../domain/actions/utils/checkForCache';
import AppStorys from '../index';

interface WidgetImage {
  id: string;
  image?: string;
  lottie_data?: string;
  link?: string;
  order: number;
}

interface CachedWidgetImage extends WidgetImage {
  cachedImagePath?: string;
}

interface WidgetsProps {
  leftPadding?: number;
  rightPadding?: number;
  position?: string;
}

export function Widgets({ leftPadding = 0, rightPadding = 0, position }: WidgetsProps) {
  const { campaigns } = useScreen();
  const flatlistRef = useRef<FlatList<CachedWidgetImage> | null>(null);
  const screenWidth = Dimensions.get('window').width;
  const [activeIndex, setActiveIndex] = useState(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const [widgetHeight, setWidgetHeight] = useState<number>(100);

  const [bottomLeftRadius, setBottomLeftRadius] = useState(0);
  const [bottomRightRadius, setBottomRightRadius] = useState(0);
  const [topLeftRadius, setTopLeftRadius] = useState(0);
  const [topRightRadius, setTopRightRadius] = useState(0);
  const [bottomMargin, setBottomMargin] = useState(0);
  const [topMargin, setTopMargin] = useState(0);
  const [leftMargin, setLeftMargin] = useState(0);
  const [rightMargin, setRightMargin] = useState(0);

  const [cachedImages, setCachedImages] = useState<CachedWidgetImage[]>([]);
  const [imagesLoaded, setImagesLoaded] = useState(false);

  // Find matching WID campaign — filter by position if provided
  const data = useMemo(() => {
    const widCampaigns = campaigns.filter((c) => c.campaign_type === 'WID') as any[];
    if (!widCampaigns.length) return null;
    if (position) {
      return widCampaigns.find((c) => c.details?.position === position || c.position === position) ?? null;
    }
    return widCampaigns[0] ?? null;
  }, [campaigns, position]);

  const contentWidth = screenWidth - leftMargin - rightMargin - leftPadding - rightPadding;

  useEffect(() => {
    if (!data?.details?.widget_images) return;
    setImagesLoaded(false);

    const cacheImages = async () => {
      let ratio: number | null = null;
      const promises = (data.details.widget_images as WidgetImage[]).map(async (item) => {
        if (!item.image) return item;
        const result = await checkForCache(item.image);
        if (!ratio && result?.ratio) { ratio = result.ratio; setWidgetHeight(contentWidth * ratio); }
        return { ...item, cachedImagePath: result?.path };
      });

      try {
        const results = await Promise.all(promises);
        results.sort((a, b) => a.order - b.order);
        setCachedImages(results);

        if (data.details.styling) {
          const s = data.details.styling;
          setBottomLeftRadius(parseInt(s.bottomLeftRadius ?? '0'));
          setBottomRightRadius(parseInt(s.bottomRightRadius ?? '0'));
          setTopLeftRadius(parseInt(s.topLeftRadius ?? '0'));
          setTopRightRadius(parseInt(s.topRightRadius ?? '0'));
          setBottomMargin(parseInt(s.bottomMargin ?? '0'));
          setTopMargin(parseInt(s.topMargin ?? '0'));
          setLeftMargin(parseInt(s.leftMargin ?? '0'));
          setRightMargin(parseInt(s.rightMargin ?? '0'));
        }
      } catch { }
      finally { setImagesLoaded(true); }
    };

    void cacheImages();
  }, [data, contentWidth]);

  const extendedImages = useMemo<CachedWidgetImage[]>(() => {
    if (!imagesLoaded || !cachedImages.length) return [];
    return cachedImages.filter((item): item is CachedWidgetImage => item !== undefined);
  }, [cachedImages, imagesLoaded]);

  const totalSlides = useMemo(() => {
    if (!data) return 0;
    if (data.details?.type === 'half') return Math.ceil(data.details.widget_images.length / 2);
    return data.details?.widget_images?.length ?? 0;
  }, [data]);

  const scrollToNextImage = () => {
    if (!data || !flatlistRef.current || !extendedImages.length || data.details?.type !== 'full') return;
    if (activeIndex === data.details.widget_images.length - 1) {
      if (intervalRef.current) { clearInterval(intervalRef.current); intervalRef.current = null; }
      return;
    }
    flatlistRef.current.scrollToOffset({ offset: contentWidth * (activeIndex + 1), animated: true });
  };

  useEffect(() => {
    if (data?.details?.type === 'full' && activeIndex < data.details.widget_images.length - 1) {
      if (intervalRef.current) clearInterval(intervalRef.current);
      intervalRef.current = setInterval(scrollToNextImage, 5000);
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [activeIndex, data, extendedImages.length]);

  const trackedRef = useRef<string[]>([]);

  const trackImpression = (id: string) => {
    if (data && !trackedRef.current.includes(id)) {
      trackedRef.current.push(id);
      void trackEvent('viewed', data.id ?? data.campaign_id, { widget_image: id });
    }
  };

  const handleViewableItemsChanged = ({ viewableItems }: { viewableItems: { item: CachedWidgetImage }[] }) => {
    viewableItems.forEach(({ item }) => trackImpression(item.id));
  };

  const renderFullItem = ({ item, index }: { item: CachedWidgetImage; index: number }) => (
    <View key={`${item.order}-${index}`} style={{ width: contentWidth }}>
      <TouchableOpacity activeOpacity={1} onPress={() => {
        if (data && item.link) {
          void trackEvent('clicked', data.id ?? data.campaign_id, { widget_image: item.id });
          AppStorys.handleNavigation(item.link);
        }
      }}>
        {item.lottie_data ? (
          <LottieView source={{ uri: item.lottie_data }} autoPlay loop style={{ height: widgetHeight, width: contentWidth }} resizeMode="contain" />
        ) : (
          <Image
            source={{ uri: item.cachedImagePath ?? item.image }}
            style={{ borderTopRightRadius: topRightRadius, borderTopLeftRadius: topLeftRadius, borderBottomRightRadius: bottomRightRadius, borderBottomLeftRadius: bottomLeftRadius, height: widgetHeight, width: contentWidth, resizeMode: 'cover' }}
          />
        )}
      </TouchableOpacity>
    </View>
  );

  const renderHalfItem = ({ item, index }: { item: CachedWidgetImage; index: number }) => {
    const hw = contentWidth * 0.455;
    const hm = contentWidth * 0.03;
    return (
      <View key={`${item.order}-${index}`} style={{ width: hw, marginLeft: hm }}>
        <TouchableOpacity activeOpacity={1} onPress={() => {
          if (data && item.link) {
            void trackEvent('clicked', data.id ?? data.campaign_id, { widget_image: item.id });
            AppStorys.handleNavigation(item.link);
          }
        }}>
          {item.lottie_data ? (
            <LottieView source={{ uri: item.lottie_data }} autoPlay loop style={{ height: (widgetHeight / 2) - (contentWidth * 0.045), width: hw }} resizeMode="contain" />
          ) : (
            <Image
              source={{ uri: item.cachedImagePath ?? item.image }}
              style={{ borderTopRightRadius: topRightRadius, borderTopLeftRadius: topLeftRadius, borderBottomRightRadius: bottomRightRadius, borderBottomLeftRadius: bottomLeftRadius, height: (widgetHeight / 2) - (contentWidth * 0.045), width: hw, resizeMode: 'cover' }}
            />
          )}
        </TouchableOpacity>
      </View>
    );
  };

  const handleScroll = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    if (!data || data.details?.type !== 'full') return;
    const idx = Math.round(e.nativeEvent.contentOffset.x / contentWidth);
    setActiveIndex(idx);
  };

  const handleScrollHalf = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    setActiveIndex(Math.round(e.nativeEvent.contentOffset.x / contentWidth));
  };

  const renderDots = () =>
    Array.from({ length: totalSlides }).map((_, i) => (
      <View key={i} style={{ backgroundColor: activeIndex === i ? 'black' : 'grey', height: 6, width: activeIndex === i ? 12 : 6, borderRadius: 5, marginHorizontal: 3, marginVertical: 6 }} />
    ));

  if (!data || !data.details?.widget_images || !imagesLoaded) return null;

  const isHalf = data.details.type === 'half';
  const showDots = isHalf
    ? data.details.widget_images.length > 2
    : data.details.widget_images.length > 1;

  return (
    <View style={{ width: '100%', backgroundColor: 'transparent', marginTop: topMargin, marginBottom: bottomMargin, paddingLeft: leftMargin, paddingRight: rightMargin }}>
      <FlatList
        data={extendedImages}
        ref={flatlistRef}
        getItemLayout={!isHalf ? (_, i) => ({ length: contentWidth, offset: contentWidth * i, index: i }) : undefined}
        renderItem={isHalf ? renderHalfItem : renderFullItem}
        keyExtractor={(item, i) => `${item.image}-${i}`}
        horizontal
        pagingEnabled
        onViewableItemsChanged={handleViewableItemsChanged}
        viewabilityConfig={{ viewAreaCoveragePercentThreshold: 50 }}
        onScroll={isHalf ? handleScrollHalf : handleScroll}
        showsHorizontalScrollIndicator={false}
        initialScrollIndex={!isHalf ? 0 : undefined}
        onLayout={() => { if (!isHalf) flatlistRef.current?.scrollToOffset({ offset: 0, animated: false }); }}
        scrollEnabled
        contentContainerStyle={{ paddingRight: isHalf ? contentWidth * 0.03 : 0 }}
      />
      {showDots && (
        <View style={{ flexDirection: 'row', justifyContent: 'center' }}>{renderDots()}</View>
      )}
    </View>
  );
}

export default Widgets;
