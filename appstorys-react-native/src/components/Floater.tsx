import React from 'react';
import { Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface FloaterProps {
  campaigns: CampaignData[];
}

export function Floater({ campaigns }: FloaterProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'FLT');
  if (!campaign) return null;

  const details = (campaign.details as Record<string, any> | undefined) ?? campaign;
  const image = details.image ?? campaign.image;
  const link = details.link ?? campaign.link;
  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  if (!image) return null;

  const onPress = async () => {
    if (campaignId) await AppStorys.trackEvent('clicked', campaignId);
    if (link) await AppStorys.handleNavigation(link);
  };

  return (
    <View style={styles.container} pointerEvents="box-none">
      <TouchableOpacity onPress={onPress} activeOpacity={0.9}>
        <Image source={{ uri: image }} style={styles.image} resizeMode="cover" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    right: 16,
    bottom: 16,
  },
  image: {
    width: 64,
    height: 64,
    borderRadius: 32,
  },
});

