import { useState, useEffect } from 'react';
import { CaptureServiceStore, CaptureServiceActions } from './types';

type StoreState = CaptureServiceStore & CaptureServiceActions;

const listeners = new Set<() => void>();

const state: StoreState = {
  isCapturing: {},
  setIsCapturing: (screenName, capturing) => {
    state.isCapturing = { ...state.isCapturing, [screenName]: capturing };
    listeners.forEach(fn => fn());
  },
};

function useCaptureServiceStore<T>(selector: (s: StoreState) => T): T {
  const [, rerender] = useState(0);
  useEffect(() => {
    const notify = () => rerender(n => n + 1);
    listeners.add(notify);
    return () => { listeners.delete(notify); };
  }, []);
  return selector(state);
}

useCaptureServiceStore.getState = (): StoreState => state;

export { useCaptureServiceStore };
