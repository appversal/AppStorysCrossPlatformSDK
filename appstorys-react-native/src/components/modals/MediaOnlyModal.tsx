import { useEffect, useState } from 'react';
import { ActivityIndicator, Modal, StyleSheet, TouchableOpacity, View } from 'react-native';
import ModalMediaRenderer from './ModalMediaRenderer';
import CrossButton from '../common/CrossButton';
import checkForCache from '../../domain/actions/utils/checkForCache';

interface MediaOnlyModalProps {
  modal: any;
  onClose: () => void;
  onModalClick: (link?: string) => void;
}

export default function MediaOnlyModal({ modal, onClose, onModalClick }: MediaOnlyModalProps) {
  const [isMediaLoaded, setIsMediaLoaded] = useState(false);
  const [cachedMediaPath, setCachedMediaPath] = useState<string | null>(null);
  const [mediaAspectRatio, setMediaAspectRatio] = useState<number | null>(null);

  const appearance = modal.styling?.appearance;
  const modalWidth = parseFloat(modal.size || '300');
  const modalHeight = mediaAspectRatio ? modalWidth * mediaAspectRatio : modalWidth;

  const cornerRadius = appearance?.cornerRadius;
  const borderRadiusStyle = {
    borderTopLeftRadius: parseFloat(cornerRadius?.topLeft || modal.borderRadius || '16'),
    borderTopRightRadius: parseFloat(cornerRadius?.topRight || modal.borderRadius || '16'),
    borderBottomLeftRadius: parseFloat(cornerRadius?.bottomLeft || modal.borderRadius || '16'),
    borderBottomRightRadius: parseFloat(cornerRadius?.bottomRight || modal.borderRadius || '16'),
  };

  const backdrop = appearance?.backdrop;
  let backdropColor = backdrop?.color || appearance?.backdropColor || '#000000';
  if (backdropColor.toLowerCase() === 'black') backdropColor = '#000000';
  if (backdropColor.toLowerCase() === 'white') backdropColor = '#FFFFFF';
  const backdropOpacity = parseFloat(backdrop?.opacity || appearance?.backdropOpacity || modal.backgroundOpacity || '50') / 100;
  const backdropEnabled = (appearance?.enableBackdrop ?? modal.enableBackdrop) !== false;

  const crossButton = modal.styling?.crossButton;
  const crossEnabled = (crossButton?.enableCrossButton ?? crossButton?.enabled ?? modal.enableCrossButton) !== false;
  const crossColors = crossButton?.color || crossButton?.default?.color || crossButton?.colors;
  const crossMargin = crossButton?.default?.spacing?.margin || crossButton?.margin;
  const crossConfig = {
    color: { fill: crossColors?.fill || 'rgba(0,0,0,0.6)', cross: crossColors?.cross || '#FFFFFF', stroke: crossColors?.stroke || 'transparent' },
    enabled: crossEnabled,
    image: crossButton?.uploadImage?.url || crossButton?.default?.crossButtonImage || modal.crossButtonImage || '',
    margin: { top: crossMargin?.top || 0, right: crossMargin?.right || 0, bottom: crossMargin?.bottom || 0, left: crossMargin?.left || 0 },
    size: crossButton?.default?.size || crossButton?.size || 32,
  };

  const mediaUrl = modal.chooseMediaType?.url || modal.resolvedMedia?.url || modal.url || '';

  useEffect(() => {
    if (!mediaUrl) return;
    const mediaType = mediaUrl.toLowerCase().endsWith('.mp4') || mediaUrl.toLowerCase().endsWith('.mov') || mediaUrl.toLowerCase().endsWith('.webm') ? 'video' : 'image';
    checkForCache(mediaUrl, mediaType).then((result: any) => {
      if (result?.path) {
        setCachedMediaPath(result.path);
        if (result.ratio !== null) setMediaAspectRatio(result.ratio);
      }
    });
  }, [mediaUrl]);

  return (
    <Modal visible={true} transparent={true} animationType="fade" onRequestClose={onClose}>
      <View style={[styles.overlay, { backgroundColor: backdropEnabled ? `${backdropColor}${Math.round(backdropOpacity * 255).toString(16).padStart(2, '0')}` : 'transparent' }]}>
        <TouchableOpacity style={StyleSheet.absoluteFill} activeOpacity={1} onPress={onClose} />
        <View style={{ ...styles.modalContainer, width: modalWidth, height: modalHeight, backgroundColor: 'transparent', ...borderRadiusStyle }}>
          {!isMediaLoaded && <View style={styles.loadingContainer}><ActivityIndicator size="large" color="#FFFFFF" /></View>}
          <TouchableOpacity activeOpacity={1} onPress={() => onModalClick(modal.redirection?.url || modal.link)}
            style={{ width: modalWidth, height: modalHeight, overflow: 'visible', position: 'relative', ...borderRadiusStyle, opacity: isMediaLoaded ? 1 : 0 }}>
            {crossEnabled && <CrossButton config={crossConfig} onPress={onClose} style={{ position: 'absolute', top: 0, right: 0, zIndex: 10 }} />}
            <ModalMediaRenderer mediaUrl={cachedMediaPath || mediaUrl} style={{ width: modalWidth, height: modalHeight, ...borderRadiusStyle }} contentScale="contain" muted={false} onLoadEnd={() => setIsMediaLoaded(true)} onError={() => setIsMediaLoaded(true)} />
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  modalContainer: { overflow: 'visible', zIndex: 2 },
  loadingContainer: { ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.5)' },
});
