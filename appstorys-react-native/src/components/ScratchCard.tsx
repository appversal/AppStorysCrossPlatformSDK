import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface ScratchCardProps {
  campaigns: CampaignData[];
}

export function ScratchCard({ campaigns }: ScratchCardProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'SCR');
  const [revealed, setRevealed] = useState(false);

  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const reveal = async () => {
    setRevealed(true);
    if (campaignId) await AppStorys.trackEvent('revealed', campaignId);
  };

  return (
    <Pressable style={styles.card} onPress={reveal}>
      <Text style={styles.title}>Scratch Card</Text>
      <Text>{revealed ? 'Reward unlocked!' : 'Tap to reveal'}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { padding: 14, borderWidth: 1, borderColor: '#ddd', borderRadius: 10, backgroundColor: '#fafafa' },
  title: { fontWeight: '700', marginBottom: 6 },
});

