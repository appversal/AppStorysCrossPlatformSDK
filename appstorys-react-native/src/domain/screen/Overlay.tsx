import { StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ScreenProviderProps } from './types';
import { useCaptureServiceStore } from '../capture/store';
import Modal from '../../components/Modal';
import Banner from '../../components/Banner';
import Floater from '../../components/Floater';
import Pip from '../../components/Pip';
import Csat from '../../components/Csat';
import BottomSheet from '../../components/BottomSheet';
import Survey from '../../components/Survey';
import CaptureScreenButton from '../../components/CaptureScreenButton';

export default function Overlay({ name }: { name: ScreenProviderProps['name'] }) {
  const isCapturing = useCaptureServiceStore((state) => state.isCapturing)[name];

  if (isCapturing) return null;

  return (
    <SafeAreaView
      style={StyleSheet.absoluteFill}
      pointerEvents="box-none"
      edges={['top', 'left', 'right', 'bottom']}
    >
      <Banner />
      <Floater />
      <Pip />
      <Csat />
      <Survey />
      <BottomSheet />
      <Modal />
      <CaptureScreenButton />
    </SafeAreaView>
  );
}
