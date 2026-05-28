import { ActivityIndicator, Dimensions, Platform, View } from 'react-native';
import { useEffect, useState } from 'react';
import Video from 'react-native-video';
import { PipData } from './types';
import trackEvent from '../../domain/actions/trackEvent';
import { removeTrackedEvent } from '../../domain/actions/utils/viaAppStorys';
import PipControls from '../common/PipControls';
import Cta, { mapAlignment } from '../common/Cta';
import AppStorys from '../../index';

interface PipScreenProps {
  campaignId: string;
  params: PipData;
  onClose: () => void;
  onMinimize: () => void;
}

export default function PipScreen({ campaignId, params, onClose, onMinimize }: PipScreenProps) {
  const { height } = Dimensions.get('window');
  const [mute, setMute] = useState(false);
  const [isVideoLoading, setIsVideoLoading] = useState(true);

  const cta = params.styling.cta;

  return (
    <View style={{ flex: 1, backgroundColor: 'black' }}>
      <View style={{ flex: 1 }}>
        <Video
          repeat
          resizeMode="contain"
          muted={mute}
          controls={false}
          source={{ uri: params.largeVideoUrl }}
          paused={isVideoLoading}
          onLoadStart={() => setIsVideoLoading(true)}
          onLoad={() => setIsVideoLoading(false)}
          onError={() => setIsVideoLoading(false)}
          style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, opacity: isVideoLoading ? 0 : 1 }}
        />
        {isVideoLoading && (
          <View style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center', backgroundColor: 'black' }}>
            <ActivityIndicator size="large" color="white" />
          </View>
        )}
      </View>

      <PipControls
        styling={params.styling}
        mode="LARGE"
        muted={!mute}
        expanded={true}
        onClose={() => { onClose(); removeTrackedEvent(`viaAppStorys${campaignId}`); }}
        onToggleMute={() => setMute(m => !m)}
        onToggleExpand={onMinimize}
        containerStyle={{ paddingTop: Platform.OS === 'ios' ? height * 0.08 : 20 }}
      />

      {params.link && params.button_text && (
        <Cta
          cta={cta}
          buttonText={params.button_text}
          onPress={() => {
            if (params.link) AppStorys.handleNavigation(params.link);
            trackEvent('clicked', params.id);
          }}
        />
      )}
    </View>
  );
}
