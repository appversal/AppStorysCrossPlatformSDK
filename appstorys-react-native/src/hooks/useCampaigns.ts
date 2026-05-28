import { useState, useEffect, useCallback } from 'react';
import { NativeEventEmitter, NativeModules } from 'react-native';
import AppStorys, { CampaignData } from '../index';
import { normalizeCampaign, parseCampaignsJson, filterCampaignsByType } from '../utils';
import { setPersonalizationData } from '../domain/actions/utils/personalization';

const { AppStorysReactNative } = NativeModules;
const emitter = new NativeEventEmitter(AppStorysReactNative);

export function useCampaigns(screenName: string) {
  const [campaigns, setCampaigns] = useState<CampaignData[]>([]);
  const [loading, setLoading] = useState(true);
  const [isTestUser, setIsTestUser] = useState(false);

  useEffect(() => {
    setLoading(true);
    setCampaigns([]);

    // Subscribe before triggering the fetch so no emission is missed.
    // Native emits wrapper: {"c":[...],"s":boolean} — mirrors Flutter's EventChannel format.
    const subscription = emitter.addListener('onCampaignsUpdate', (payload: string) => {
      try {
        const wrapper = JSON.parse(payload) as { c: unknown; s?: boolean };
        if (Array.isArray(wrapper.c)) {
          setCampaigns(wrapper.c.map((item: any) => normalizeCampaign(item ?? {})));
          setIsTestUser(wrapper.s ?? false);
        } else {
          // Fallback: handle a plain JSON array string from an older bridge version.
          setCampaigns(parseCampaignsJson(payload));
        }
      } catch {
        setCampaigns(parseCampaignsJson(payload));
      }
      setLoading(false);
      // Refresh personalization tokens whenever campaigns update.
      AppStorys.getPersonalizationData().then(setPersonalizationData).catch(() => {});
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

  return { campaigns, loading, refresh, getCampaignsByType, isTestUser };
}
