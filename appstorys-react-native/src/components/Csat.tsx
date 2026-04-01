import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface CsatProps {
  campaigns: CampaignData[];
  userId?: string;
}

export function Csat({ campaigns, userId = '' }: CsatProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'CSA');
  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const submitRating = async (rating: number) => {
    if (!campaignId) return;
    await AppStorys.captureCsatResponse(campaignId, rating);
    await AppStorys.trackEvent('rated', campaignId, { userId, rating });
  };

  return (
    <View style={styles.card}>
      <Text style={styles.title}>How was your experience?</Text>
      <View style={styles.row}>
        {[1, 2, 3, 4, 5].map((rating) => (
          <Pressable key={rating} style={styles.badge} onPress={() => submitRating(rating)}>
            <Text style={styles.badgeText}>{rating}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { padding: 12, borderRadius: 10, borderWidth: 1, borderColor: '#ddd' },
  title: { fontWeight: '600', marginBottom: 10 },
  row: { flexDirection: 'row', gap: 8 },
  badge: { width: 36, height: 36, borderRadius: 18, backgroundColor: '#efefef', justifyContent: 'center', alignItems: 'center' },
  badgeText: { fontWeight: '600' },
});

