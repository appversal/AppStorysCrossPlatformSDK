import { CampaignData } from '../index';

function toNumber(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

export function normalizeCampaign(input: Partial<CampaignData> & Record<string, any>): CampaignData {
  const details = (input.details ?? {}) as Record<string, any>;

  return {
    id: input.id,
    campaign_id: input.campaign_id ?? input.id,
    campaign_type: input.campaign_type,
    screen: input.screen,
    position: input.position,
    trigger_event: input.trigger_event,
    details,
    image: input.image ?? details.image,
    link: input.link ?? details.link,
    width: toNumber(input.width ?? details.width),
    height: toNumber(input.height ?? details.height),
    styling: input.styling ?? details.styling,
    lottie_data: input.lottie_data ?? details.lottie_data,
  };
}

export function parseCampaignsJson(json: string | null | undefined): CampaignData[] {
  if (!json || json === '[]') return [];
  try {
    const raw = JSON.parse(json);
    if (!Array.isArray(raw)) return [];
    return raw.map((item) => normalizeCampaign(item ?? {}));
  } catch {
    return [];
  }
}

export function filterCampaignsByType(campaigns: CampaignData[], type: string): CampaignData[] {
  return campaigns.filter((campaign) => campaign.campaign_type === type);
}

