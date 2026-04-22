import { useState, useEffect, useCallback } from 'react';
import { NativeEventEmitter, NativeModules } from 'react-native';
import AppStorys, { CampaignData } from '../index';
import { parseCampaignsJson, filterCampaignsByType } from '../utils/campaignParser';

const { AppStorysReactNative } = NativeModules;
const emitter = new NativeEventEmitter(AppStorysReactNative);

export function useCampaigns(screenName: string) {
  const [campaigns, setCampaigns] = useState<CampaignData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    setCampaigns([]);

    // Subscribe before triggering the fetch so no emission is missed.
    const subscription = emitter.addListener('onCampaignsUpdate', (json: string) => {
      setCampaigns(parseCampaignsJson(json));
      setLoading(false);
    });

    // Trigger the native fetch. Data arrives via the subscription above, not the return value.
    AppStorys.getScreenCampaigns(screenName).catch(() => setLoading(false));

    return () => subscription.remove();
  }, [screenName]);

  const getCampaignsByType = useCallback(
    (type: string) => filterCampaignsByType(campaigns, type),
    [campaigns]
  );

  const refresh = useCallback(() => {
    setLoading(true);
    AppStorys.getScreenCampaigns(screenName).catch(() => setLoading(false));
  }, [screenName]);

  return { campaigns, loading, refresh, getCampaignsByType };
}
