import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface PipProps {
  campaigns: CampaignData[];
}

export function Pip({ campaigns }: PipProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'PIP');
  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';
  const link = (campaign.details as Record<string, any> | undefined)?.link ?? campaign.link;

  const onOpen = async () => {
    if (campaignId) await AppStorys.trackEvent('opened', campaignId);
    if (link) await AppStorys.handleNavigation(link);
  };

  return (
    <View style={styles.container}>
      <Pressable style={styles.pill} onPress={onOpen}>
        <Text style={styles.text}>Open PiP</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { alignItems: 'flex-end' },
  pill: { backgroundColor: '#111', borderRadius: 18, paddingHorizontal: 14, paddingVertical: 8 },
  text: { color: '#fff', fontWeight: '600' },
});

