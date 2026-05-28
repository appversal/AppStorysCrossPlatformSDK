import { useCallback } from 'react';
import CaptureService from './CaptureService';
import { Alert } from 'react-native';
import useScreen from '../screen/useScreen';

export default function useCapture() {
  const { name, options, context: { measureAll } } = useScreen();
  return useCallback(async () => {
    try {
      if (CaptureService.getIsCapturing(name)) {
        Alert.alert('Info', `${name} capture is already in progress`);
        return;
      }

      const measurements = await measureAll();
      CaptureService.clearLayoutData(name);
      measurements.forEach(({ id, size, position }) => {
        CaptureService.addLayoutInfo(name, id, {
          x: position.x,
          y: position.y,
          width: size.width,
          height: size.height,
        });
      });

      const success = await CaptureService.takeScreenshot(name, options?.positionList);
      if (success) {
        Alert.alert('Success', `${name} captured successfully`);
      } else {
        Alert.alert('Error', `Failed to capture ${name}`);
      }
    } catch (error) {
      Alert.alert('Error', `Failed to capture ${name}: ${error}`);
    }
  }, [name, options, measureAll]);
}
