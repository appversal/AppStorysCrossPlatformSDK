import { captureScreen } from 'react-native-view-shot';
import { NativeModules } from 'react-native';
import { LayoutFrame, LayoutInfo } from './types';
import { useCaptureServiceStore } from './store';

const { AppStorysReactNative } = NativeModules;

class CaptureService {
  private static layoutData: Record<string, LayoutInfo[]> = {};

  static getIsCapturing(screenName: string): boolean {
    return useCaptureServiceStore.getState().isCapturing[screenName] || false;
  }

  static addLayoutInfo(screenName: string, id: string, layout: LayoutFrame) {
    if (!this.layoutData[screenName]) this.layoutData[screenName] = [];
    const infos = this.layoutData[screenName];
    const existingIndex = infos.findIndex((item) => item.id === id);
    const layoutInfo: LayoutInfo = { id, frame: layout };
    if (existingIndex >= 0) {
      infos[existingIndex] = layoutInfo;
    } else {
      infos.push(layoutInfo);
    }
  }

  static clearLayoutData(screenName: string) {
    this.layoutData[screenName] = [];
  }

  static async takeScreenshot(screenName: string, positionList?: string[]): Promise<boolean> {
    try {
      if (!screenName) return false;
      this.setIsCapturing(screenName, true);
      await new Promise((resolve) => setTimeout(resolve, 100));

      const screenshotPath = await captureScreen({ format: 'png', quality: 1.0 });
      const children = JSON.stringify(this.layoutData[screenName]);

      await AppStorysReactNative.identifyElements(screenName, children, screenshotPath);
      return true;
    } catch (error) {
      console.error('Screenshot failed:', error);
      return false;
    } finally {
      this.setIsCapturing(screenName, false);
    }
  }

  private static setIsCapturing(screenName: string, capturing: boolean) {
    useCaptureServiceStore.getState().setIsCapturing(screenName, capturing);
  }
}

export default CaptureService;
