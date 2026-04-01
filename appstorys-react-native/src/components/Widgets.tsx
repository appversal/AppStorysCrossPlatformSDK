import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { CampaignData } from '../index';

interface WidgetsProps {
  campaigns: CampaignData[];
}

export function Widgets({ campaigns }: WidgetsProps) {
  const widgets = campaigns.filter((campaign) => campaign.campaign_type === 'WID');
  if (!widgets.length) return null;

  return (
    <View style={styles.container}>
      {widgets.map((campaign, index) => (
        <View key={campaign.campaign_id ?? campaign.id ?? `widget-${index}`} style={styles.card}>
          <Text style={styles.title}>Widget Campaign</Text>
          <Text style={styles.id}>{campaign.campaign_id ?? campaign.id}</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { gap: 10 },
  card: { borderWidth: 1, borderColor: '#ddd', borderRadius: 10, padding: 12 },
  title: { fontWeight: '600', color: '#222' },
  id: { marginTop: 4, color: '#666' },
});

