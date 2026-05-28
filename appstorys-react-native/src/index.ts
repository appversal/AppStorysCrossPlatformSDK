import { NativeModules, Linking } from 'react-native';

const { AppStorysReactNative } = NativeModules;

export interface CampaignData {
  id?: string;
  campaign_id?: string;
  campaign_type?: string;
  screen?: string;
  position?: string;
  trigger_event?: string;
  details?: Record<string, any>;
  image?: string;
  link?: string;
  width?: number;
  height?: number;
  styling?: Record<string, any>;
  lottie_data?: string;
}

export const AppStorys = {
  initialize: (appId: string, accountId: string, userId: string = ''): Promise<boolean> =>
    AppStorysReactNative.initialize(appId, accountId, userId),

  getScreenCampaigns: (screenName: string): Promise<boolean> =>
    AppStorysReactNative.getScreenCampaigns(screenName),

  getCampaigns: async (): Promise<CampaignData[]> => {
    const json = await AppStorysReactNative.getCampaignsJson();
    if (!json || json === '[]') return [];
    return JSON.parse(json);
  },

  getCampaignsByType: async (type: string): Promise<CampaignData[]> => {
    const json = await AppStorysReactNative.getCampaignsByTypeJson(type);
    if (!json || json === '[]') return [];
    return JSON.parse(json);
  },

  getPersonalizationData: async (): Promise<Record<string, string>> => {
    const json = await AppStorysReactNative.getPersonalizationDataJson();
    if (!json || json === '{}') return {};
    return JSON.parse(json);
  },

  getUserId: (): Promise<string> => AppStorysReactNative.getUserId(),
  isReady: (): Promise<boolean> => AppStorysReactNative.isReady(),

  trackEvent: (event: string, campaignId?: string | null, metadata?: Record<string, any>): Promise<boolean> =>
    AppStorysReactNative.trackEvent(campaignId ?? null, event, metadata ?? null),

  setUserId: (userId: string): Promise<boolean> =>
    AppStorysReactNative.setUserId(userId),

  setUserProperties: (attributes: Record<string, any>): Promise<boolean> =>
    AppStorysReactNative.setUserProperties(attributes),

  dismissCampaign: (campaignId: string): Promise<boolean> =>
    AppStorysReactNative.dismissCampaign(campaignId),

  captureCsatResponse: (
    csatId: string,
    rating: number,
    feedbackOption?: string,
    additionalComments?: string
  ): Promise<boolean> =>
    AppStorysReactNative.captureCsatResponse(
      csatId,
      '',
      rating,
      feedbackOption ?? null,
      additionalComments ?? null
    ),

  captureSurveyResponse: (
    surveyId: string,
    responseOptions: string[],
    comment?: string
  ): Promise<boolean> =>
    AppStorysReactNative.captureSurveyResponse(surveyId, '', responseOptions, comment ?? null),

  sendReelLikeStatus: (campaignId: string, isLiked: boolean): Promise<boolean> =>
    AppStorysReactNative.sendReelLikeStatus(campaignId, '', isLiked),

    personalizeText: (text: string): Promise<string> =>
        AppStorysReactNative.personalizeText(text),

  handleNavigation: async (link: string): Promise<void> => {
    // Navigation is handled by the host app for deep links and internal routes.
    if (!link) return;
    if (link.startsWith('http://') || link.startsWith('https://')) {
      try {
        await Linking.openURL(link);
      } catch (_) { }
    }
  },
};

export default AppStorys;

export * from './components';
export * from './hooks';
export * from './utils';
