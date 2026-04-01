import React, { useEffect, useMemo, useState } from 'react';
import { Dimensions, Image, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface BannerProps {
  campaigns: CampaignData[];
  onDismiss?: (campaignId: string) => void;
}

function toFloat(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = parseFloat(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

export function Banner({ campaigns, onDismiss }: BannerProps) {
  const [visible, setVisible] = useState(true);

  const banner = useMemo(
    () => campaigns.find((campaign) => campaign.campaign_type === 'BAN'),
    [campaigns]
  );
  const details = (banner?.details as Record<string, any> | undefined) ?? banner ?? {};
  const styling = (details.styling ?? banner?.styling ?? {}) as Record<string, any>;
  const campaignId = banner?.campaign_id ?? banner?.id ?? '';
  const imageUrl = details.image ?? banner?.image;

  useEffect(() => {
    if (campaignId) {
      AppStorys.trackEvent('viewed', campaignId);
    }
  }, [campaignId]);

  if (!banner || !visible || !imageUrl) return null;

  const tl = toFloat(styling.topLeftRadius);
  const tr = toFloat(styling.topRightRadius);
  const bl = toFloat(styling.bottomLeftRadius);
  const br = toFloat(styling.bottomRightRadius);

  const mb = toFloat(styling.marginBottom);
  const ml = toFloat(styling.marginLeft);
  const mr = toFloat(styling.marginRight);

  const w = toFloat(details.width ?? banner.width);
  const h = toFloat(details.height ?? banner.height);
  const screenWidth = Dimensions.get('window').width;
  const availableWidth = screenWidth - ml - mr;
  const imageHeight = w > 0 && h > 0 ? availableWidth * (h / w) : h > 0 ? h : undefined;

  const crossButton = (styling.crossButton ?? {}) as Record<string, any>;
  const showClose = crossButton.enabled === true;

  const handlePress = async () => {
    const link = details.link ?? banner.link;
    if (campaignId) {
      await AppStorys.trackEvent('clicked', campaignId);
    }
    if (link) {
      await AppStorys.handleNavigation(link);
    }
  };

  const handleDismiss = async () => {
    if (campaignId) {
      await AppStorys.dismissCampaign(campaignId);
    }
    setVisible(false);
    onDismiss?.(campaignId);
  };

  return (
    <View style={{ marginBottom: mb, marginLeft: ml, marginRight: mr }}>
      <TouchableOpacity activeOpacity={0.9} onPress={handlePress}>
        <Image
          source={{ uri: imageUrl }}
          style={{
            width: '100%',
            height: imageHeight ?? 150,
            borderTopLeftRadius: tl,
            borderTopRightRadius: tr,
            borderBottomLeftRadius: bl,
            borderBottomRightRadius: br,
          }}
          resizeMode="cover"
        />
      </TouchableOpacity>

      {showClose && (
        <TouchableOpacity style={styles.closeBtn} onPress={handleDismiss}>
          <View style={styles.closeBtnInner}>
            <Text style={styles.closeX}>✕</Text>
          </View>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  closeBtn: { position: 'absolute', top: 4, right: 4 },
  closeBtnInner: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeX: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '700',
    lineHeight: 14,
  },
});

