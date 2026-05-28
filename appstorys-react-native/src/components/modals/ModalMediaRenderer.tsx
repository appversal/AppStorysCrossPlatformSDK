import { useEffect, useMemo, useState } from 'react';
import { Image, ImageStyle, StyleSheet } from 'react-native';
import LottieView from 'lottie-react-native';
import checkForCache from '../../domain/actions/utils/checkForCache';

interface ModalMediaRendererProps {
  mediaUrl?: string;
  mediaType?: 'image' | 'video' | 'lottie' | 'gif';
  style?: ImageStyle;
  contentScale?: 'cover' | 'contain' | 'stretch';
  muted?: boolean;
  paused?: boolean;
  onLoadStart?: () => void;
  onLoadEnd?: () => void;
  onError?: () => void;
  onDimensions?: (width: number, height: number) => void;
}

export default function ModalMediaRenderer({
  mediaUrl, mediaType: explicitMediaType, style, contentScale = 'contain',
  muted = false, paused = false, onLoadStart, onLoadEnd, onError, onDimensions,
}: ModalMediaRendererProps) {
  const [cachedPath, setCachedPath] = useState<string | null>(null);

  const mediaType = useMemo(() => {
    if (explicitMediaType) return explicitMediaType;
    if (!mediaUrl) return 'image';
    const lowerUrl = mediaUrl.toLowerCase();
    if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.m4v') ||
      lowerUrl.endsWith('.avi') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.m3u8')) return 'video';
    if (lowerUrl.endsWith('.gif')) return 'gif';
    if (lowerUrl.endsWith('.json') || mediaUrl.trimStart().startsWith('{') || mediaUrl.trimStart().startsWith('[')) return 'lottie';
    return 'image';
  }, [mediaUrl, explicitMediaType]);

  useEffect(() => {
    if (!mediaUrl) { onError?.(); return; }
    setCachedPath(null);
    onLoadStart?.();
    if (mediaType === 'lottie') return;

    checkForCache(mediaUrl, mediaType)
      .then((result: any) => {
        if (result?.path) { setCachedPath(result.path); onLoadEnd?.(); }
        else onError?.();
      })
      .catch(() => onError?.());
  }, [mediaUrl, mediaType]);

  const resizeMode = contentScale === 'cover' ? 'cover' : contentScale === 'stretch' ? 'stretch' : 'contain';

  if (mediaType === 'video') {
    // react-native-video is optional — render placeholder if not installed
    try {
      const Video = require('react-native-video').default;
      if (!cachedPath) return null;
      return (
        <Video
          source={{ uri: cachedPath }}
          style={{ ...styles.media, ...style }}
          resizeMode={resizeMode}
          muted={muted}
          repeat
          paused={paused}
          controls={false}
          pointerEvents="none"
          onLoad={(data: any) => { if (data.naturalSize) onDimensions?.(data.naturalSize.width, data.naturalSize.height); }}
          onError={onError}
        />
      );
    } catch {
      return null;
    }
  }

  if (mediaType === 'lottie') {
    return <LottieRenderer cachedPath={cachedPath} mediaUrl={mediaUrl} style={style} onLoadEnd={onLoadEnd} onError={onError} />;
  }

  if (!cachedPath) return null;
  return (
    <Image
      source={{ uri: cachedPath }}
      style={StyleSheet.flatten([styles.media, style]) as ImageStyle}
      resizeMode={resizeMode}
      onLoad={(e) => { const { width, height } = e.nativeEvent.source; onDimensions?.(width, height); }}
      onError={onError}
    />
  );
}

const styles = StyleSheet.create({ media: { width: '100%', height: '100%' } });

function LottieRenderer({ cachedPath, mediaUrl, style, onLoadEnd, onError }:
  { cachedPath?: string | null; mediaUrl?: string; style?: ImageStyle; onLoadEnd?: () => void; onError?: () => void }) {
  const [animationJson, setAnimationJson] = useState<any>(null);

  useEffect(() => {
    const load = async () => {
      try {
        if (!mediaUrl) return;
        let json;
        if (mediaUrl.trimStart().startsWith('{') || mediaUrl.trimStart().startsWith('[')) {
          json = JSON.parse(mediaUrl);
        } else {
          const uri = cachedPath || mediaUrl;
          const res = await fetch(uri);
          json = await res.json();
        }
        setAnimationJson(json);
        onLoadEnd?.();
      } catch { onError?.(); }
    };
    load();
  }, [cachedPath, mediaUrl]);

  if (!animationJson) return null;
  return (
    <LottieView source={animationJson} autoPlay loop style={{ ...StyleSheet.flatten(styles.media), ...style }} onAnimationFailure={onError} />
  );
}
