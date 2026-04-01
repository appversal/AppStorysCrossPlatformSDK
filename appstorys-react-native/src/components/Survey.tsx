import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface SurveyProps {
  campaigns: CampaignData[];
  userId?: string;
}

export function Survey({ campaigns, userId = '' }: SurveyProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'SUR');
  const [comment, setComment] = useState('');

  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const submit = async (choice: string) => {
    if (!campaignId) return;
    await AppStorys.captureSurveyResponse(campaignId, [choice], comment || undefined);
    await AppStorys.trackEvent('submitted', campaignId, { userId, choice });
  };

  return (
    <View style={styles.card}>
      <Text style={styles.title}>Survey</Text>
      <TextInput
        placeholder="Additional comment (optional)"
        value={comment}
        onChangeText={setComment}
        style={styles.input}
      />
      <View style={styles.row}>
        <Pressable style={styles.button} onPress={() => submit('YES')}>
          <Text style={styles.buttonText}>Yes</Text>
        </Pressable>
        <Pressable style={styles.button} onPress={() => submit('NO')}>
          <Text style={styles.buttonText}>No</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { padding: 12, borderRadius: 10, borderWidth: 1, borderColor: '#ddd' },
  title: { fontWeight: '600', marginBottom: 10 },
  input: { borderWidth: 1, borderColor: '#ccc', borderRadius: 8, paddingHorizontal: 10, paddingVertical: 8, marginBottom: 10 },
  row: { flexDirection: 'row', gap: 10 },
  button: { flex: 1, backgroundColor: '#222', borderRadius: 8, paddingVertical: 10 },
  buttonText: { textAlign: 'center', color: '#fff', fontWeight: '600' },
});

