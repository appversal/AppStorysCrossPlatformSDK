import { ActivityIndicator, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import useCapture from '../domain/capture/useCapture';
import { useCaptureServiceStore } from '../domain/capture/store';
import useScreen from '../domain/screen/useScreen';

export default function CaptureScreenButton() {
  const screen = useScreen();
  const isTestUser = screen.isTestUser;
  const screenName = screen.name;
  const isCapturing = useCaptureServiceStore((state) => state.isCapturing)[screenName];
  const handleCapture = useCapture();

  if (!isTestUser || !screenName) return null;

  return (
    <View style={styles.elevationContainer}>
      <TouchableOpacity
        activeOpacity={0.7}
        onPress={handleCapture}
        style={styles.buttonContainer}
        disabled={isCapturing}
      >
        {isCapturing ? (
          <ActivityIndicator />
        ) : (
          <Text style={styles.buttonText}>Capture Screen</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  elevationContainer: {
    position: 'absolute',
    bottom: 20,
    right: 20,
    borderRadius: 12,
    elevation: 4,
    backgroundColor: 'white',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    zIndex: 100000,
  },
  buttonContainer: {
    padding: 16,
    borderRadius: 12,
    backgroundColor: 'white',
  },
  buttonText: {
    fontSize: 16,
    color: '#222',
    textAlign: 'center',
  },
});
