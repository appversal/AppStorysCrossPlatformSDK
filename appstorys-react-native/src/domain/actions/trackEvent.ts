import AppStorys from '../../index';

export default async function trackEvent(
  event: string,
  campaignId?: string | null,
  metadata?: Record<string, any>,
): Promise<void> {
  try {
    await AppStorys.trackEvent(event, campaignId ?? null, metadata ?? null);
  } catch { }
}
