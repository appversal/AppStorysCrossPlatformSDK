import { useEffect, useState } from 'react';
import { Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import trackEvent from '../domain/actions/trackEvent';
import usePadding from '../domain/hooks/usePadding';
import viaAppStorys from '../domain/actions/utils/viaAppStorys';
import checkForCache from '../domain/actions/utils/checkForCache';
import AppStorys from '../index';
import LottieView from 'lottie-react-native';
import useScreen from '../domain/screen/useScreen';

export default function Floater() {
  const [imagePath, setImagePath] = useState<string | null>(null);
  const [lottieData, setLottieData] = useState<any>(null);
  const [isLottie, setIsLottie] = useState(false);
  const [bottomLeftRadius, setBottomLeftRadius] = useState(0);
  const [bottomRightRadius, setBottomRightRadius] = useState(0);
  const [topLeftRadius, setTopLeftRadius] = useState(0);
  const [topRightRadius, setTopRightRadius] = useState(0);

  const { campaigns } = useScreen();
  const data = campaigns.find((c) => c.campaign_type === 'FLT') as any;
  const padding = usePadding('FLT')?.bottom || 0;

  useEffect(() => {
    if (!data) return;
    void trackEvent('viewed', data.id);

    if (data.details.lottie_data && data.details.lottie_data !== '') {
      setIsLottie(true);
      checkForCache(data.details.lottie_data, 'video').then(async (result) => {
        if (!result) return;
        try {
          const response = await fetch(result.path);
          const json = await response.json();
          setLottieData(json);
          if (data.details.styling) {
            setBottomLeftRadius(parseInt(data.details.styling['bottomLeftRadius'] || '0'));
            setBottomRightRadius(parseInt(data.details.styling['bottomRightRadius'] || '0'));
            setTopLeftRadius(parseInt(data.details.styling['topLeftRadius'] || '0'));
            setTopRightRadius(parseInt(data.details.styling['topRightRadius'] || '0'));
          }
        } catch { }
      });
    } else if (data.details.image && data.details.image !== '') {
      setIsLottie(false);
      checkForCache(data.details.image).then((result) => {
        if (!result) return;
        setImagePath(result.path);
        if (data.details.styling) {
          setBottomLeftRadius(parseInt(data.details.styling['bottomLeftRadius'] || '0'));
          setBottomRightRadius(parseInt(data.details.styling['bottomRightRadius'] || '0'));
          setTopLeftRadius(parseInt(data.details.styling['topLeftRadius'] || '0'));
          setTopRightRadius(parseInt(data.details.styling['topRightRadius'] || '0'));
        }
      });
    }
  }, [data]);

  return (
    <>
      {data && data.details && data.details.image !== '' && (
        <View style={{
          position: 'absolute',
          left: data.details.position === 'left' ? parseInt(data.details.styling['marginLeft'] || '0') : undefined,
          right: (data.details.position === 'right' || data.details.position === '' || data.details.position == null)
            ? parseInt(data.details.styling['marginRight'] || '0') : undefined,
          bottom: parseInt(data.details.styling['marginBottom'] || '0') + padding,
          justifyContent: 'flex-end',
        }}>
          <TouchableOpacity
            activeOpacity={1}
            onPress={() => {
              if (data.details.link) {
                void trackEvent('clicked', data.id);
                viaAppStorys(`viaAppStorys${data.details.link}`);
                AppStorys.handleNavigation(data.details.link);
              }
            }}
            style={{
              width: data.details.width ?? 60,
              height: data.details.height ?? 60,
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: 'rgba(0,0,0,0)',
              overflow: 'hidden',
              borderBottomLeftRadius: bottomLeftRadius,
              borderBottomRightRadius: bottomRightRadius,
              borderTopLeftRadius: topLeftRadius,
              borderTopRightRadius: topRightRadius,
            }}
          >
            {isLottie && lottieData && (
              <LottieView source={lottieData} autoPlay loop style={{ width: '100%', height: '100%' }} resizeMode="contain" />
            )}
            {!isLottie && imagePath && (
              <Image source={{ uri: imagePath }} style={styles.image} />
            )}
          </TouchableOpacity>
        </View>
      )}
    </>
  );
}

export { Floater };

const styles = StyleSheet.create({
  image: { width: '100%', height: '100%', resizeMode: 'cover' },
});
