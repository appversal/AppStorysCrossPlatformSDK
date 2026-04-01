import { useCallback, useEffect, useState } from 'react';
import AppStorys from '../index';

export interface UseAppStorysOptions {
  appId: string;
  accountId: string;
  userId?: string;
  autoInitialize?: boolean;
}

export function useAppStorys(options: UseAppStorysOptions) {
  const { appId, accountId, userId = '', autoInitialize = true } = options;
  const [initializing, setInitializing] = useState(false);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const refreshReadyState = useCallback(async () => {
    try {
      const sdkReady = await AppStorys.isReady();
      setReady(sdkReady);
      return sdkReady;
    } catch (e) {
      const err = e instanceof Error ? e : new Error('Failed to query SDK ready state');
      setError(err);
      setReady(false);
      return false;
    }
  }, []);

  const initialize = useCallback(async () => {
    setInitializing(true);
    setError(null);
    try {
      await AppStorys.initialize(appId, accountId, userId);
      await refreshReadyState();
      return true;
    } catch (e) {
      const err = e instanceof Error ? e : new Error('Failed to initialize AppStorys');
      setError(err);
      setReady(false);
      return false;
    } finally {
      setInitializing(false);
    }
  }, [accountId, appId, refreshReadyState, userId]);

  useEffect(() => {
    if (autoInitialize) {
      initialize();
    }
  }, [autoInitialize, initialize]);

  return { initialize, refreshReadyState, initializing, ready, error };
}

