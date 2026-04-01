import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface SpinWheelProps {
  campaigns: CampaignData[];
}

const REWARDS = ['5% OFF', '10% OFF', 'Free Shipping', 'Try Again'];

export function SpinWheel({ campaigns }: SpinWheelProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'SPW');
  const [result, setResult] = useState<string | null>(null);

  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const spin = async () => {
    const prize = REWARDS[Math.floor(Math.random() * REWARDS.length)];
    setResult(prize);
    if (campaignId) {
      await AppStorys.trackEvent('spun', campaignId, { prize });
    }
  };

  return (
    <View style={styles.card}>
      <Text style={styles.title}>Spin Wheel</Text>
      <Pressable style={styles.button} onPress={spin}>
        <Text style={styles.buttonText}>Spin</Text>
      </Pressable>
      {result ? <Text style={styles.result}>Result: {result}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: { padding: 14, borderWidth: 1, borderColor: '#ddd', borderRadius: 10 },
  title: { fontWeight: '700', marginBottom: 10 },
  button: { backgroundColor: '#222', borderRadius: 8, paddingVertical: 10 },
  buttonText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
  result: { marginTop: 10, color: '#333' },
});

