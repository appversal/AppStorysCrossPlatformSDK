import { useCallback, useRef } from 'react';
import { PixelRatio, Platform } from 'react-native';
import { ScreenProviderProps } from './types';
import ScreenContext from './ScreenContext';
import { MeasurementData } from '../capture/types';
import { EdgeInsets, useSafeAreaInsets } from 'react-native-safe-area-context';
import { useCampaigns } from '../../hooks';

export default function ScreenProvider({ name, options, children }: ScreenProviderProps) {
  const insets = useSafeAreaInsets();
  const registeredRefs = useRef(new Map<string, any>());

  const { campaigns, isTestUser, loading } = useCampaigns(name);

  const register = useCallback((id: string, ref: any) => {
    registeredRefs.current.set(id, ref);
  }, []);

  const unregister = useCallback((id: string) => {
    registeredRefs.current.delete(id);
  }, []);

  const measureAll = useCallback(async () => {
    return new Promise<MeasurementData[]>((resolve) => {
      const data: MeasurementData[] = [];
      const refsToMeasure = Array.from(registeredRefs.current.entries());
      let measuredCount = 0;

      if (refsToMeasure.length === 0) return resolve(data);

      refsToMeasure.forEach(([id, ref]) => {
        if (ref && typeof ref.measureInWindow === 'function') {
          ref.measureInWindow((x: number, y: number, width: number, height: number) => {
            data.push(getMeasurementData(id, x, y, width, height, insets));
          });
        } else {
          console.warn(`Could not measure component with id: ${id}`);
        }
        measuredCount++;
        if (measuredCount === refsToMeasure.length) resolve(data);
      });
    });
  }, [insets]);

  const measure = useCallback(async (id: string) => {
    const ref = registeredRefs.current.get(id);
    if (!ref || typeof ref.measureInWindow !== 'function') return null;

    return new Promise<MeasurementData | null>((resolve) => {
      ref.measureInWindow((x: number, y: number, width: number, height: number) => {
        resolve(getMeasurementData(id, x, y, width, height, insets));
      });
    });
  }, [insets]);

  return (
    <ScreenContext.Provider value={{
      name,
      options,
      campaigns,
      isTestUser,
      loading,
      context: { register, unregister, measure, measureAll },
    }}>
      {children}
    </ScreenContext.Provider>
  );
}

function getMeasurementData(
  id: string,
  x: number,
  y: number,
  width: number,
  height: number,
  insets: EdgeInsets,
): MeasurementData {
  const pixelRatio = PixelRatio.get();
  const statusBarAdjustment =
    Platform.OS === 'ios' || (Platform.OS === 'android' && Platform.Version >= 35)
      ? insets.top
      : 0;

  return {
    id,
    size: {
      width: width * pixelRatio,
      height: height * pixelRatio,
      logicalWidth: width,
      logicalHeight: height,
    },
    position: {
      x: x * pixelRatio,
      y: (y + statusBarAdjustment) * pixelRatio,
      logicalX: x,
      logicalY: Platform.OS === 'android' ? y + statusBarAdjustment : y - statusBarAdjustment,
    },
    pixelRatio,
  };
}
