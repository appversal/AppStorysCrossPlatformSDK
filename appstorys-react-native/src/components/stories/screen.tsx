import { SetStateAction, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator, Animated, Dimensions, Image, PanResponder,
  Platform, Share, Text, TouchableWithoutFeedback, View,
} from 'react-native';
import Video from 'react-native-video';
import { StoryData, StorySlide } from './types';
import trackEvent from '../../domain/actions/trackEvent';
import StoryControls from './StoryControls';
import Cta from '../common/Cta';
import checkForCache from '../../domain/actions/utils/checkForCache';
import { personalizeText } from '../../domain/actions/utils/personalization';
import AppStorys from '../../index';

interface StoriesScreenProps {
  params: StoryData | null;
  onClose: () => void;
  onSlideViewed?: (slideId: string) => void;
}

export default function StoriesScreen({ params, onClose, onSlideViewed }: StoriesScreenProps) {
  const { height, width } = Dimensions.get('window');

  const [content, setContent] = useState<StorySlide[]>([]);
  const [currentGroupIndex, setCurrentGroupIndex] = useState(0);
  const [current, setCurrent] = useState(0);
  const [currentStorySlide, setCurrentStorySlide] = useState(0);
  const [videoDuration, setVideoDuration] = useState(5);
  const [isVideoLoading, setIsVideoLoading] = useState(false);
  const [isImageLoading, setIsImageLoading] = useState(false);
  const [mute, setMute] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [cachedImagePath, setCachedImagePath] = useState<string | null>(null);
  const [cachedVideoPath, setCachedVideoPath] = useState<string | null>(null);

  const animationRef = useRef<any>(null);
  const pauseTime = useRef(0);
  const pressStartTime = useRef(0);
  const touchStartPosition = useRef({ x: 0, y: 0 });
  const isPanGestureActive = useRef(false);
  const translateY = useRef(new Animated.Value(0)).current;
  const modalOpacity = useRef(new Animated.Value(1)).current;
  const progress = useRef(new Animated.Value(0)).current;

  const groups = params?.groups ?? [];

  const loadStoryGroup = (groupIndex: number) => {
    const group = groups[groupIndex];
    if (!group) { close(); return; }

    const slides = group.slides ?? [];
    if (slides.length === 0) {
      const next = groupIndex + 1;
      if (next < groups.length) loadStoryGroup(next);
      else close();
      return;
    }

    progress.setValue(0);
    setContent(slides.map((s) => ({ ...s, finish: 0 })));
    setCurrent(0);
    setCurrentStorySlide(0);
  };

  const start = (duration: number) => {
    const slide = groups[currentGroupIndex]?.slides?.[currentStorySlide];
    if (slide?.id && params?.campaignId) {
      void trackEvent('viewed', params.campaignId, { story_slide: slide.id });
      onSlideViewed?.(slide.id);
      setCurrentStorySlide((n) => n + 1);
    }
    animationRef.current = Animated.timing(progress, { toValue: 1, duration, useNativeDriver: false });
    animationRef.current.start(({ finished }: { finished: boolean }) => { if (finished) next(); });
  };

  const pause = () => {
    setIsPaused(true);
    animationRef.current?.stop();
    progress.stopAnimation((v: number) => { pauseTime.current = v; });
  };

  const resume = (duration: number) => {
    setIsPaused(false);
    if (pauseTime.current > 0) {
      const remaining = duration * (1 - pauseTime.current);
      animationRef.current = Animated.timing(progress, { toValue: 1, duration: remaining, useNativeDriver: false });
      animationRef.current.start(({ finished }: { finished: boolean }) => { if (finished) next(); });
    }
  };

  const next = () => {
    pauseTime.current = 0;
    if (current !== content.length - 1) {
      const tmp = [...content];
      if (tmp[current]) tmp[current].finish = 1;
      setContent(tmp);
      setCurrent((n) => n + 1);
      progress.setValue(0);
    } else {
      let ng = currentGroupIndex + 1;
      while (ng < groups.length && !(groups[ng]?.slides?.length)) ng++;
      if (ng < groups.length) { setCurrentGroupIndex(ng); loadStoryGroup(ng); }
      else close();
    }
  };

  const previous = () => {
    pauseTime.current = 0;
    if (current > 0) {
      const tmp = [...content];
      if (tmp[current]) tmp[current].finish = 0;
      setContent(tmp);
      progress.setValue(0);
      setCurrent((n) => n - 1);
    } else {
      let pg = currentGroupIndex - 1;
      while (pg >= 0 && !(groups[pg]?.slides?.length)) pg--;
      if (pg >= 0) { setCurrentGroupIndex(pg); loadStoryGroup(pg); }
      else close();
    }
  };

  const close = () => {
    progress.setValue(0);
    pauseTime.current = 0;
    animationRef.current?.stop();
    onClose();
  };

  const resetDismissAnimation = () => {
    Animated.parallel([
      Animated.spring(translateY, { toValue: 0, useNativeDriver: true, tension: 65, friction: 10 }),
      Animated.timing(modalOpacity, { toValue: 1, duration: 200, useNativeDriver: true }),
    ]).start();
    const dur = content[current]?.video ? videoDuration * 1000 : 5000;
    resume(dur);
  };

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => false,
      onMoveShouldSetPanResponder: (_, g) => {
        const ok = Math.abs(g.dy) > 10 && Math.abs(g.dy) > Math.abs(g.dx);
        if (ok) isPanGestureActive.current = true;
        return ok;
      },
      onPanResponderGrant: () => pause(),
      onPanResponderMove: (_, g) => { if (g.dy > 0) translateY.setValue(g.dy); },
      onPanResponderRelease: (_, g) => {
        if (g.dy > 50 || g.vy > 0.5) {
          Animated.parallel([
            Animated.timing(translateY, { toValue: height, duration: 200, useNativeDriver: true }),
            Animated.timing(modalOpacity, { toValue: 0, duration: 150, useNativeDriver: true }),
          ]).start(({ finished }) => { if (finished) close(); });
        } else resetDismissAnimation();
        isPanGestureActive.current = false;
      },
      onPanResponderTerminate: () => { resetDismissAnimation(); isPanGestureActive.current = false; },
    }),
  ).current;

  const handlePressIn = (e: any) => {
    touchStartPosition.current = { x: e.nativeEvent.pageX, y: e.nativeEvent.pageY };
    pressStartTime.current = Date.now();
    isPanGestureActive.current = false;
    pause();
  };

  const handlePressOut = (e: any, direction: 'left' | 'right') => {
    const dur = content[current]?.video ? videoDuration * 1000 : 5000;
    resume(dur);
    if (isPanGestureActive.current) return;
    const dt = Date.now() - pressStartTime.current;
    const dx = Math.abs(e.nativeEvent.pageX - touchStartPosition.current.x);
    const dy = Math.abs(e.nativeEvent.pageY - touchStartPosition.current.y);
    if (dt < 200 && dx < 20 && dy < 20) {
      direction === 'left' ? previous() : next();
    }
  };

  useEffect(() => {
    content.forEach((item) => {
      if (item.video) void checkForCache(item.video, 'video');
      else if (item.image) void checkForCache(item.image, 'image');
    });
  }, [content]);

  useEffect(() => {
    if (!params) return;
    setCurrentGroupIndex(params.initialGroupIndex);
    loadStoryGroup(params.initialGroupIndex);
  }, [params]);

  useEffect(() => {
    setCachedImagePath(null);
    setCachedVideoPath(null);
    if (content[current]?.video) {
      setIsVideoLoading(true);
      setIsImageLoading(false);
      checkForCache(content[current].video!).then((r) => { if (r) setCachedVideoPath(r.path); });
    } else if (content[current]?.image) {
      setIsImageLoading(true);
      setIsVideoLoading(false);
      checkForCache(content[current].image!).then((r) => { if (r) setCachedImagePath(r.path); });
    } else {
      setIsVideoLoading(false);
      setIsImageLoading(false);
    }
  }, [current, content]);

  const shareContent = async () => {
    try {
      void trackEvent('shared', params?.campaignId, { story_slide: content[current]?.id ?? '' });
      await Share.share({ message: 'Check this out: ' + (content[current]?.link ?? '') });
    } catch { }
  };

  const topPad = Platform.OS === 'ios' ? height * 0.07 : height * 0.02;

  return (
    <Animated.View
      style={{ flex: 1, backgroundColor: 'black', paddingTop: topPad, paddingBottom: topPad, transform: [{ translateY }], opacity: modalOpacity }}
      {...panResponder.panHandlers}
    >
      {/* Image slide */}
      {content[current]?.image && (
        <>
          {isImageLoading && !cachedImagePath && (
            <View style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.5)' }}>
              <ActivityIndicator size="large" color="white" />
            </View>
          )}
          {cachedImagePath && (
            <Image
              source={{ uri: cachedImagePath }}
              onLoadStart={() => setIsImageLoading(true)}
              onLoadEnd={() => { setIsImageLoading(false); progress.setValue(0); start(5000); }}
              onError={() => setIsImageLoading(false)}
              style={{ height: '100%', width, resizeMode: 'contain', top: 0 }}
            />
          )}
        </>
      )}

      {/* Video slide */}
      {content[current]?.video && (
        <>
          {isVideoLoading && !cachedVideoPath && (
            <View style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.5)' }}>
              <ActivityIndicator size="large" color="white" />
            </View>
          )}
          {cachedVideoPath && (
            <Video
              source={{ uri: cachedVideoPath }}
              style={{ height: '100%', width }}
              resizeMode="contain"
              muted={mute}
              controls={false}
              disableFocus
              ignoreSilentSwitch="ignore"
              playInBackground={false}
              preventsDisplaySleepDuringVideoPlayback
              onLoadStart={() => setIsVideoLoading(true)}
              onLoad={(d: { duration: SetStateAction<number> }) => { setVideoDuration(d.duration as number); setIsVideoLoading(false); progress.setValue(0); start((d.duration as number) * 1000); }}
              onError={() => setIsVideoLoading(false)}
              onEnd={next}
              paused={isVideoLoading || isPaused}
            />
          )}
        </>
      )}

      {/* Progress bars */}
      <View style={{ width: width - 5, position: 'absolute', top: Platform.OS === 'ios' ? height * 0.08 : height * 0.03, justifyContent: 'space-evenly', alignItems: 'center', flexDirection: 'row' }}>
        {content.map((_, i) => (
          <View key={i} style={{ flexDirection: 'row', flex: 1, height: 3, backgroundColor: 'grey', marginLeft: 5, borderRadius: 2 }}>
            <Animated.View style={{ flex: current === i ? progress : (content[i]?.finish ?? 1), height: 3, borderRadius: 2, backgroundColor: 'rgba(211,202,202,1)' }} />
          </View>
        ))}
      </View>

      {/* Group header */}
      <View style={{ width, height: 50, flexDirection: 'row', justifyContent: 'space-between', position: 'absolute', top: Platform.OS === 'ios' ? height * 0.094 : height * 0.045 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', width: '100%', paddingHorizontal: 20 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            {groups[currentGroupIndex]?.thumbnail && (
              <Image source={{ uri: groups[currentGroupIndex].thumbnail }} style={{ width: 40, height: 40, borderRadius: 20 }} />
            )}
            {groups[currentGroupIndex]?.name && (
              <Text style={{ marginLeft: 12, fontSize: 15, fontWeight: '500', color: 'white' }}>
                {personalizeText(groups[currentGroupIndex].name!)}
              </Text>
            )}
          </View>
        </View>
      </View>

      {/* Controls */}
      {groups[currentGroupIndex]?.styling && (
        <StoryControls
          styling={groups[currentGroupIndex].styling!}
          muted={!mute}
          onClose={close}
          onToggleMute={() => setMute((m) => !m)}
          onShare={shareContent}
          hasVideo={!!(content[current]?.video)}
          hasLink={!!(content[current]?.link && content[current]?.button_text)}
          containerStyle={{ marginTop: (Platform.OS === 'ios' ? height * 0.08 : height * 0.03) + 3 }}
        />
      )}

      {/* Left / right tap zones */}
      <View style={{ marginTop: height * 0.15, width, height, position: 'absolute', top: 0, flexDirection: 'row', justifyContent: 'space-between' }}>
        <TouchableWithoutFeedback onPressIn={handlePressIn} onPressOut={(e) => handlePressOut(e, 'left')}>
          <View style={{ width: '50%', height: '100%' }} />
        </TouchableWithoutFeedback>
        <TouchableWithoutFeedback onPressIn={handlePressIn} onPressOut={(e) => handlePressOut(e, 'right')}>
          <View style={{ width: '50%', height: '100%' }} />
        </TouchableWithoutFeedback>
      </View>

      {/* CTA */}
      {content[current]?.button_text && content[current]?.link && (() => {
        const cta = content[current]?.styling?.cta;
        return (
          <Cta
            cta={cta}
            buttonText={content[current].button_text}
            onPress={() => {
              const link = content[current]?.link;
              if (link && params?.campaignId) {
                AppStorys.handleNavigation(link);
                void trackEvent('clicked', params.campaignId, { story_slide: content[current]?.id ?? '' });
              }
            }}
          />
        );
      })()}
    </Animated.View>
  );
}
