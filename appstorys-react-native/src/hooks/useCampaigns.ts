import { useState, useEffect, useCallback } from 'react';
import AppStorys, { CampaignData } from '../index';

export function useCampaigns(screenName: string) {
  const [campaigns, setCampaigns] = useState<CampaignData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchCampaigns = useCallback(async () => {
    setLoading(true);
    try {
      await AppStorys.getScreenCampaigns(screenName);
      // Allow native layer to finish async campaign fetch before reading JSON.
      await new Promise((resolve) => setTimeout(resolve, 1500));
      const data = await AppStorys.getCampaigns();
      setCampaigns(data);
    } catch (e) {
      console.error('Error fetching campaigns:', e);
      setCampaigns([]);
    }
    setLoading(false);
  }, [screenName]);

  useEffect(() => {
    fetchCampaigns();
  }, [fetchCampaigns]);

  const getCampaignsByType = useCallback(
    (type: string) => campaigns.filter((campaign) => campaign.campaign_type === type),
    [campaigns]
  );

  return { campaigns, loading, refresh: fetchCampaigns, getCampaignsByType };
}

