import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface BottomSheetProps {
  campaigns: CampaignData[];
  visible: boolean;
  onClose: () => void;
}

export function BottomSheet({ campaigns, visible, onClose }: BottomSheetProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'BOT');
  if (!campaign || !visible) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const handleClose = async () => {
    if (campaignId) await AppStorys.dismissCampaign(campaignId);
    onClose();
  };

  return (
    <View style={styles.overlay} pointerEvents="box-none">
      <View style={styles.sheet}>
        <Text style={styles.title}>Bottom Sheet Campaign</Text>
        <Text style={styles.subtitle}>{campaignId || 'No campaign id'}</Text>
        <Pressable style={styles.button} onPress={handleClose}>
          <Text style={styles.buttonText}>Close</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: { position: 'absolute', left: 0, right: 0, top: 0, bottom: 0, justifyContent: 'flex-end' },
  sheet: {
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    backgroundColor: '#fff',
    padding: 16,
    elevation: 4,
  },
  title: { fontWeight: '700', fontSize: 16 },
  subtitle: { marginTop: 8, color: '#444' },
  button: { marginTop: 12, backgroundColor: '#222', borderRadius: 8, paddingVertical: 10 },
  buttonText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
});

