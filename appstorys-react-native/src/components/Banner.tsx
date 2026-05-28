import { useCallback, useEffect, useState } from 'react';
import { Dimensions, Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import LottieView from 'lottie-react-native';
import trackEvent from '../domain/actions/trackEvent';
import usePadding from '../domain/hooks/usePadding';
import viaAppStorys, { removeTrackedEvent } from '../domain/actions/utils/viaAppStorys';
import CrossButton from './common/CrossButton';
import healthCheck from '../domain/actions/utils/healthCheck';
import checkForCache from '../domain/actions/utils/checkForCache';
import AppStorys from '../index';
import { isNullOrEmpty } from '../domain/actions/utils/helperFunctions';
import useScreen from '../domain/screen/useScreen';

export default function Banner() {
  const { width } = Dimensions.get('window');

  const [isBannerVisible, setIsBannerVisible] = useState(true);
  const [imagePath, setImagePath] = useState<string | null>(null);
  const [lottieData, setLottieData] = useState<any>(null);
  const [lottieAspectRatio, setLottieAspectRatio] = useState<number | null>(null);
  const [isLottie, setIsLottie] = useState(false);
  const [bannerHeight, setBannerHeight] = useState<number>(100);
  const [componentLoadStart] = useState<number>(Date.now());

  const [bottomLeftRadius, setBottomLeftRadius] = useState<number>(0);
  const [bottomRightRadius, setBottomRightRadius] = useState<number>(0);
  const [topLeftRadius, setTopLeftRadius] = useState<number>(0);
  const [topRightRadius, setTopRightRadius] = useState<number>(0);
  const [marginBottom, setMarginBottom] = useState<number>(0);
  const [marginLeft, setMarginLeft] = useState<number>(0);
  const [marginRight, setMarginRight] = useState<number>(0);
  const [crossButtonConfig, setCrossButtonConfig] = useState<any>(null);

  // KMP: read campaign from ScreenContext instead of Zustand useCampaigns hook
  const { campaigns } = useScreen();
  const data = campaigns.find((c) => c.campaign_type === 'BAN') as any;
  const padding = usePadding('BAN')?.bottom || 0;

  // Reset visibility whenever the campaign ID changes (including undefined → id cycle
  // when navigating away and back). Mirrors Flutter's `if (banner == null) _visible = true`.
  useEffect(() => {
    setIsBannerVisible(true);
  }, [data?.id]);

  const closeBanner = useCallback(() => {
    setIsBannerVisible(false);
    void healthCheck({ component: 'banner', action: 'banner_closed', success: true, campaignId: data?.id, closeMethod: 'user_action' });
  }, [data?.id]);

  useEffect(() => {
    if (data && data.id) {
      const bannerInitStart = Date.now();
      void trackEvent('viewed', data.id);
      void healthCheck({ component: 'banner', action: 'banner_init', duration: Date.now() - componentLoadStart, success: true, campaignId: data.id });

      if (data.details.lottie_data && data.details.lottie_data !== '') {
        setIsLottie(true);
        const cacheStart = Date.now();
        checkForCache(data.details.lottie_data, 'video').then(async (result) => {
          if (!result) return;
          try {
            const response = await fetch(result.path);
            const json = await response.json();
            setLottieData(json);
            let aspectRatio: number | null = null;
            if (json.w && json.h && json.w > 0 && json.h > 0) {
              aspectRatio = json.h / json.w;
              setLottieAspectRatio(aspectRatio);
            }
            if (data.details.styling) {
              setBottomLeftRadius(parseInt(data.details.styling.bottomLeftRadius || '0'));
              setBottomRightRadius(parseInt(data.details.styling.bottomRightRadius || '0'));
              setTopLeftRadius(parseInt(data.details.styling.topLeftRadius || '0'));
              setTopRightRadius(parseInt(data.details.styling.topRightRadius || '0'));
              setMarginBottom(parseInt(data.details.styling.marginBottom || '0'));
              setMarginLeft(parseInt(data.details.styling.marginLeft || '0'));
              setMarginRight(parseInt(data.details.styling.marginRight || '0'));
              if (data.details.styling.crossButton) setCrossButtonConfig(data.details.styling.crossButton);
            }
            const bannerWidth = width - (marginLeft + marginRight);
            if (data.details.height && !isNullOrEmpty(data.details.image)) {
              setBannerHeight(data.details.height);
            } else if (aspectRatio) {
              setBannerHeight(bannerWidth * aspectRatio);
            } else {
              setBannerHeight(bannerWidth * 0.5);
            }
            void healthCheck({ component: 'banner', action: 'lottie_setup_complete', duration: Date.now() - bannerInitStart, success: true, campaignId: data.id });
          } catch (error) {
            void healthCheck({ component: 'banner', action: 'lottie_parse_error', duration: Date.now() - cacheStart, success: false, campaignId: data.id });
          }
        }).catch(() => void healthCheck({ component: 'banner', action: 'lottie_cache_error', success: false, campaignId: data.id }));
      } else if (data.details.image && data.details.image !== '') {
        setIsLottie(false);
        const cacheStart = Date.now();
        checkForCache(data.details.image).then((result) => {
          if (!result) return;
          setImagePath(result.path);
          if (data.details.styling) {
            setBottomLeftRadius(parseInt(data.details.styling.bottomLeftRadius || '0'));
            setBottomRightRadius(parseInt(data.details.styling.bottomRightRadius || '0'));
            setTopLeftRadius(parseInt(data.details.styling.topLeftRadius || '0'));
            setTopRightRadius(parseInt(data.details.styling.topRightRadius || '0'));
            setMarginBottom(parseInt(data.details.styling.marginBottom || '0'));
            setMarginLeft(parseInt(data.details.styling.marginLeft || '0'));
            setMarginRight(parseInt(data.details.styling.marginRight || '0'));
            if (data.details.styling.crossButton) setCrossButtonConfig(data.details.styling.crossButton);
          }
          const bannerWidth = width - (marginLeft + marginRight);
          if (result.ratio) setBannerHeight(bannerWidth * result.ratio);
          void healthCheck({ component: 'banner', action: 'banner_setup_complete', duration: Date.now() - bannerInitStart, success: true, campaignId: data.id });
        }).catch(() => void healthCheck({ component: 'banner', action: 'image_cache_error', duration: Date.now() - cacheStart, success: false, campaignId: data.id }));
      }
    }
  }, [data, width, componentLoadStart]);

  const bannerWidth = width - marginLeft - marginRight;

  return (
    <>
      {data && data.details && (data.details.image !== '' || data.details.lottie_data !== '') && isBannerVisible && (
        <View style={{ position: 'absolute', left: marginLeft, right: marginRight, bottom: marginBottom + padding, alignItems: 'center', justifyContent: 'flex-end' }}>
          <TouchableOpacity
            activeOpacity={1}
            onPress={async () => {
              if (data.details.link) {
                void trackEvent('clicked', data.id);
                viaAppStorys(`viaAppStorys${data.details.link}`);
                try {
                  AppStorys.handleNavigation(data.details.link);
                } catch { }
              }
            }}
            style={[styles.banner, { width: bannerWidth, height: bannerHeight, borderTopRightRadius: topRightRadius, borderTopLeftRadius: topLeftRadius, borderBottomRightRadius: bottomRightRadius, borderBottomLeftRadius: bottomLeftRadius, backgroundColor: 'transparent' }]}
          >
            {isLottie && lottieData && (
              <LottieView source={lottieData} autoPlay loop style={{ width: bannerWidth, height: bannerHeight, borderTopRightRadius: topRightRadius, borderTopLeftRadius: topLeftRadius, borderBottomRightRadius: bottomRightRadius, borderBottomLeftRadius: bottomLeftRadius, overflow: 'hidden' }} resizeMode="contain" />
            )}
            {!isLottie && imagePath && (
              <Image source={{ uri: imagePath }} style={{ width: bannerWidth, height: bannerHeight, resizeMode: 'cover', borderTopRightRadius: topRightRadius, borderTopLeftRadius: topLeftRadius, borderBottomRightRadius: bottomRightRadius, borderBottomLeftRadius: bottomLeftRadius }} />
            )}
            {crossButtonConfig && (
              <CrossButton config={crossButtonConfig} onPress={() => { closeBanner(); removeTrackedEvent(`viaAppStorys${data.id}`); }} style={{ position: 'absolute', top: 0, right: 0 }} />
            )}
          </TouchableOpacity>
        </View>
      )}
    </>
  );
}

export { Banner };

const styles = StyleSheet.create({
  banner: { alignItems: 'center', justifyContent: 'center', position: 'relative' },
});
