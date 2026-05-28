import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Animated, Dimensions, Modal, PanResponder, Platform, Pressable, StyleSheet, View } from 'react-native';
import Video from 'react-native-video';
import useScreen from '../domain/screen/useScreen';
import PipScreen from './pip/screen';
import { PipData } from './pip/types';
import trackEvent from '../domain/actions/trackEvent';
import usePadding from '../domain/hooks/usePadding';
import { removeTrackedEvent } from '../domain/actions/utils/viaAppStorys';
import PipControls from './common/PipControls';
import checkForCache from '../domain/actions/utils/checkForCache';

export default function Pip() {
  const { width, height } = Dimensions.get('window');

  const [selectedPipData, setSelectedPipData] = useState<PipData | null>(null);
  const [isVisible, setIsVisible] = useState(true);
  const [cachedSmallVideoPath, setCachedSmallVideoPath] = useState<string | null>(null);
  const [cachedLargeVideoPath, setCachedLargeVideoPath] = useState<string | null>(null);
  const [isSmallVideoCached, setIsSmallVideoCached] = useState(false);
  const [mute, setMute] = useState(true);
  const [isVideoLoading, setIsVideoLoading] = useState(false);

  // KMP: read from ScreenContext instead of Zustand useCampaigns hook
  const { campaigns } = useScreen();
  const data = campaigns.find((c) => c.campaign_type === 'PIP') as any;

  const padding = usePadding('PIP');
  const topPadding = padding?.top || 0;
  const bottomPadding = padding?.bottom || 0;

  const pipHeight = data?.details?.height || 200;
  const pipWidth = data?.details?.width || 140;
  const pipBottomValue = pipHeight + 20;

  const MAX_X = width - pipWidth - 20;
  const MAX_Y = height - (bottomPadding + topPadding + pipHeight) - 20;
  const MIN_X = 20;
  const MIN_Y = Platform.OS === 'ios' ? 60 : 20;

  const initialX = data?.details?.position === 'right' ? width - (pipWidth + 20) : 20;
  const initialY = height - (bottomPadding + pipBottomValue);

  const pan = useRef(new Animated.ValueXY()).current;
  const offsetRef = useRef({ x: initialX, y: initialY });

  const smallSrc = cachedSmallVideoPath || data?.details?.small_video || '';
  const largeSrc = cachedLargeVideoPath || data?.details?.large_video || '';

  const isPlayable = (u?: string) => !!u && (/^https?:\/\//i.test(u) || /^file:\/\//i.test(u));

  const constrainPosition = (x: number, y: number) => ({
    x: Math.min(Math.max(x, MIN_X), MAX_X),
    y: Math.min(Math.max(y, MIN_Y), MAX_Y),
  });

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: (_, gs) => Math.abs(gs.dx) > 5 || Math.abs(gs.dy) > 5,
      onPanResponderMove: Animated.event([null, { dx: pan.x, dy: pan.y }], { useNativeDriver: false }),
      onPanResponderRelease: (_, gs) => {
        const next = constrainPosition(offsetRef.current.x + gs.dx, offsetRef.current.y + gs.dy);
        offsetRef.current = next;
        pan.setOffset(next);
        pan.setValue({ x: 0, y: 0 });
      },
    })
  ).current;

  useEffect(() => {
    pan.setOffset({ x: initialX, y: initialY });
  }, []);

  useEffect(() => {
    if (!data?.id) return;

    void trackEvent('viewed', data.id);
    setIsVideoLoading(false);
    setCachedSmallVideoPath(null);
    setCachedLargeVideoPath(null);
    setIsSmallVideoCached(false);
    setIsVisible(true);

    if (data.details?.small_video) {
      setIsVideoLoading(true);
      checkForCache(data.details.small_video, 'video').then((res) => {
        if (res?.path) { setCachedSmallVideoPath(res.path); setIsSmallVideoCached(true); }
      });
    }
    if (data.details?.large_video) {
      checkForCache(data.details.large_video, 'video').then((res) => {
        if (res?.path) setCachedLargeVideoPath(res.path);
      });
    }
  }, [data?.id]);

  const closePip = () => setIsVisible(false);
  const closeModal = () => { setSelectedPipData(null); setIsVisible(true); };
  const closeFullPip = () => { setSelectedPipData(null); setIsVisible(false); if (data?.id) removeTrackedEvent(`viaAppStorys${data.id}`); };

  const expandPip = () => {
    if (!data || !isPlayable(largeSrc)) return;
    closePip();
    setSelectedPipData({ id: data.id, link: data.details?.link, button_text: data.details?.button_text, largeVideoUrl: largeSrc, styling: data.details?.styling });
    void trackEvent('viewed', data.id);
  };

  if (!data) return null;

  return (
    <View pointerEvents="box-none" style={[StyleSheet.absoluteFill, { zIndex: 999998, top: topPadding, bottom: bottomPadding }]}>
      {isVisible && (
        <Animated.View
          {...panResponder.panHandlers}
          style={{ backgroundColor: 'black', width: pipWidth, height: pipHeight, position: 'absolute', borderRadius: 15, overflow: 'hidden', zIndex: 999999, elevation: 999999, transform: [{ translateX: pan.x }, { translateY: Animated.subtract(pan.y, new Animated.Value(topPadding)) }] }}
        >
          <Pressable onPress={expandPip} style={{ flex: 1 }}>
            {isVideoLoading && (
              <View style={{ ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center', backgroundColor: 'black', borderRadius: 15 }}>
                {!isSmallVideoCached && <ActivityIndicator size="large" color="white" />}
              </View>
            )}
            {cachedSmallVideoPath && isPlayable(smallSrc) && (
              <Video
                repeat
                resizeMode="contain"
                muted={mute}
                controls={false}
                source={{ uri: smallSrc }}
                paused={isVideoLoading}
                onLoadStart={() => setIsVideoLoading(true)}
                onLoad={() => setIsVideoLoading(false)}
                onError={() => setIsVideoLoading(false)}
                style={{ ...StyleSheet.absoluteFillObject, borderRadius: 15, opacity: isVideoLoading ? 0 : 1 }}
              />
            )}
          </Pressable>
          <PipControls
            styling={data.details?.styling}
            mode="SMALL"
            muted={!mute}
            expanded={false}
            onClose={() => { closePip(); removeTrackedEvent(`viaAppStorys${data.id}`); }}
            onToggleMute={() => setMute(m => !m)}
            onToggleExpand={expandPip}
          />
        </Animated.View>
      )}

      <Modal visible={!!selectedPipData} transparent={false} animationType="fade">
        {selectedPipData && (
          <PipScreen campaignId={data.id} params={selectedPipData} onClose={closeFullPip} onMinimize={closeModal} />
        )}
      </Modal>
    </View>
  );
}

export { Pip };
