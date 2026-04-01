import React from 'react';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface StoriesProps {
  campaigns: CampaignData[];
}

export function Stories({ campaigns }: StoriesProps) {
  const items = campaigns.filter((item) => item.campaign_type === 'STR');
  if (!items.length) return null;

  return (
    <ScrollView horizontal style={styles.container} showsHorizontalScrollIndicator={false}>
      {items.map((item, index) => {
        const campaignId = item.campaign_id ?? item.id ?? `story-${index}`;
        const details = (item.details as Record<string, any> | undefined) ?? item;
        const label = String(details.title ?? `Story ${index + 1}`);
        const link = details.link ?? item.link;

        const onPress = async () => {
          if (campaignId) await AppStorys.trackEvent('clicked', campaignId);
          if (link) await AppStorys.handleNavigation(link);
        };

        return (
          <TouchableOpacity key={campaignId} style={styles.item} onPress={onPress}>
            <View style={styles.avatar} />
            <Text style={styles.label} numberOfLines={1}>
              {label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { paddingVertical: 8 },
  item: { alignItems: 'center', width: 72, marginRight: 10 },
  avatar: { width: 56, height: 56, borderRadius: 28, backgroundColor: '#ddd', marginBottom: 6 },
  label: { fontSize: 11, color: '#333', textAlign: 'center' },
});

