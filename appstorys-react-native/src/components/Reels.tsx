import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface ReelsProps {
  campaigns: CampaignData[];
  userId?: string;
}

export function Reels({ campaigns, userId = '' }: ReelsProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'REL');
  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const like = async (isLiked: boolean) => {
    if (!campaignId) return;
    await AppStorys.sendReelLikeStatus(campaignId, isLiked);
    await AppStorys.trackEvent(isLiked ? 'liked' : 'disliked', campaignId, { userId });
  };

  return (
    <View style={styles.card}>
      <Text style={styles.title}>Reel Campaign</Text>
      <View style={styles.row}>
        <Pressable style={styles.button} onPress={() => like(true)}>
          <Text style={styles.buttonText}>Like</Text>
        </Pressable>
        <Pressable style={styles.button} onPress={() => like(false)}>
          <Text style={styles.buttonText}>Dislike</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { padding: 12, borderWidth: 1, borderColor: '#ddd', borderRadius: 10 },
  title: { fontWeight: '600', marginBottom: 10 },
  row: { flexDirection: 'row', gap: 10 },
  button: { flex: 1, backgroundColor: '#222', borderRadius: 8, paddingVertical: 10 },
  buttonText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
});

