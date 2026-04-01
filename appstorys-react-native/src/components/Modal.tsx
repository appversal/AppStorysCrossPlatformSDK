import React from 'react';
import { Modal as RNModal, Pressable, StyleSheet, Text, View } from 'react-native';
import AppStorys, { CampaignData } from '../index';

interface ModalProps {
  campaigns: CampaignData[];
  visible: boolean;
  onClose: () => void;
}

export function Modal({ campaigns, visible, onClose }: ModalProps) {
  const campaign = campaigns.find((item) => item.campaign_type === 'MOD');
  if (!campaign) return null;

  const campaignId = campaign.campaign_id ?? campaign.id ?? '';

  const handleClose = async () => {
    if (campaignId) await AppStorys.dismissCampaign(campaignId);
    onClose();
  };

  return (
    <RNModal visible={visible} transparent animationType="fade" onRequestClose={handleClose}>
      <Pressable style={styles.overlay} onPress={handleClose}>
        <View style={styles.card}>
          <Text style={styles.title}>Campaign Modal</Text>
          <Text style={styles.subtitle}>{campaignId || 'No campaign id'}</Text>
        </View>
      </Pressable>
    </RNModal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  card: { backgroundColor: '#fff', borderRadius: 12, width: '100%', padding: 16 },
  title: { fontWeight: '700', fontSize: 16 },
  subtitle: { marginTop: 8, color: '#444' },
});

