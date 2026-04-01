import React, { useEffect, useState } from 'react';
import {
	SafeAreaView,
	ScrollView,
	View,
	Text,
	Image,
	TouchableOpacity,
	StyleSheet,
	Dimensions,
	Linking,
	ActivityIndicator,
} from 'react-native';
import AppStorys, { CampaignData } from 'appstorys-react-native';

const SCREEN_WIDTH = Dimensions.get('window').width;

function toFloat(value: unknown): number {
	if (typeof value === 'number' && Number.isFinite(value)) return value;
	if (typeof value === 'string') {
		const parsed = parseFloat(value);
		return Number.isFinite(parsed) ? parsed : 0;
	}
	return 0;
}

export default function App() {
	const [status, setStatus] = useState('Initializing...');
	const [userId, setUserId] = useState('');
	const [campaigns, setCampaigns] = useState<CampaignData[]>([]);
	const [bannerVisible, setBannerVisible] = useState(true);
	const [events, setEvents] = useState<string[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		async function init() {
			try {
				// Step 1: initialize SDK
				setStatus('Calling initialize...');
				await AppStorys.initialize(
					'f69bdccf-b20f-4938-b39e-7075d76db791',
					'12a9eac5-94ee-4735-9aa6-b8a94cb8fbbb',
					'yash1'
				);
				setStatus('Initialized. Getting user ID...');

				const uid = await AppStorys.getUserId();
				setUserId(uid);
				setStatus(`User: ${uid}. Fetching campaigns...`);

				// Step 2: fetch campaigns for the test screen
				await AppStorys.getScreenCampaigns('Home Screen React');

				setStatus('Waiting for campaign data...');
				await new Promise((r) => setTimeout(r, 2500));

				// Step 3: read cached campaigns
				const data = await AppStorys.getCampaigns();
				setCampaigns(data);
				setStatus(`Loaded ${data.length} campaigns`);

				// Step 4: track default banner impression if present
				const banner = data.find((c) => c.campaign_type === 'BAN');
				if (banner) {
					const id = banner.campaign_id ?? banner.id ?? '';
					await AppStorys.trackEvent('viewed', id);
					setEvents((prev) => [...prev, `viewed -> ${id}`]);
					setStatus(`Banner found: ${id}`);
				} else {
					setStatus(`No banner. Types: ${data.map((c) => c.campaign_type).join(', ') || 'none'}`);
				}
			} catch (e: any) {
				const msg = e?.message ?? String(e);
				setError(msg);
				setStatus(`Error: ${msg}`);
			} finally {
				setLoading(false);
			}
		}
		init();
	}, []);

	const banner = campaigns.find((c) => c.campaign_type === 'BAN');
	const details = (banner?.details as Record<string, any> | undefined) ?? banner ?? {};
	const imageUrl = details?.image ?? banner?.image;
	const styling = (details?.styling ?? banner?.styling ?? {}) as Record<string, any>;
	const campaignId = banner?.campaign_id ?? banner?.id ?? '';

	const tl = toFloat(styling?.topLeftRadius);
	const tr = toFloat(styling?.topRightRadius);
	const bl = toFloat(styling?.bottomLeftRadius);
	const br = toFloat(styling?.bottomRightRadius);
	const mb = toFloat(styling?.marginBottom);
	const ml = toFloat(styling?.marginLeft);
	const mr = toFloat(styling?.marginRight);

	const w = toFloat(details?.width ?? banner?.width);
	const h = toFloat(details?.height ?? banner?.height);
	const availableWidth = SCREEN_WIDTH - ml - mr;
	const imageHeight = w > 0 && h > 0 ? availableWidth * (h / w) : undefined;

	const crossButton = (styling?.crossButton ?? {}) as Record<string, any>;
	const showClose = crossButton?.enabled === true || styling?.enableCloseButton === true;

	const handleBannerTap = async () => {
		if (campaignId) {
			await AppStorys.trackEvent('clicked', campaignId);
			setEvents((prev) => [...prev, `clicked -> ${campaignId}`]);
		}
		const link = details?.link ?? banner?.link;
		if (typeof link === 'string' && link.startsWith('http')) {
			try {
				await Linking.openURL(link);
			} catch (_) { }
		}
	};

	const handleDismiss = async () => {
		if (campaignId) {
			await AppStorys.dismissCampaign(campaignId);
			setEvents((prev) => [...prev, `dismissed -> ${campaignId}`]);
		}
		setBannerVisible(false);
	};

	return (
		<SafeAreaView style={styles.container}>
			<ScrollView contentContainerStyle={styles.scroll}>
				<Text style={styles.title}>AppStorys - React Native Test</Text>

				<View style={styles.card}>
					<Text style={styles.cardTitle}>SDK Status</Text>
					<Text style={styles.small}>Status: {status}</Text>
					<Text style={styles.small}>User ID: {userId || 'not set'}</Text>
					<Text style={styles.small}>Campaigns: {campaigns.length}</Text>
					<Text style={styles.small}>
						Types: {campaigns.map((c) => c.campaign_type).join(', ') || 'none'}
					</Text>
					{error && <Text style={styles.error}>Error: {error}</Text>}
					{loading && <ActivityIndicator style={{ marginTop: 8 }} />}
				</View>

				<View style={styles.card}>
					<Text style={styles.cardTitle}>Banner Campaign</Text>
					{banner && imageUrl && bannerVisible ? (
						<View style={{ marginTop: 8, marginBottom: mb, marginLeft: ml, marginRight: mr }}>
							<TouchableOpacity activeOpacity={0.9} onPress={handleBannerTap}>
								<Image
									source={{ uri: imageUrl }}
									style={{
										width: '100%' as any,
										height: imageHeight ?? 150,
										borderTopLeftRadius: tl,
										borderTopRightRadius: tr,
										borderBottomLeftRadius: bl,
										borderBottomRightRadius: br,
									}}
									resizeMode="cover"
									onError={(e) => {
										setEvents((prev) => [...prev, `image error: ${e.nativeEvent.error}`]);
									}}
								/>
							</TouchableOpacity>
							{showClose && (
								<TouchableOpacity style={styles.closeBtn} onPress={handleDismiss}>
									<View style={styles.closeBtnInner}>
										<Text style={styles.closeBtnText}>X</Text>
									</View>
								</TouchableOpacity>
							)}
						</View>
					) : banner && !imageUrl ? (
						<View style={{ marginTop: 8 }}>
							<Text style={styles.small}>Banner found but no image URL.</Text>
							<Text style={styles.tiny}>Details keys: {Object.keys(details).join(', ')}</Text>
							<Text style={styles.tiny}>Image field: {String(details?.image ?? 'undefined')}</Text>
						</View>
					) : !banner ? (
						<Text style={[styles.small, { marginTop: 8 }]}>
							No BAN campaign found in {campaigns.length} campaigns.
						</Text>
					) : (
						<Text style={[styles.small, { marginTop: 8 }]}>Banner dismissed.</Text>
					)}
				</View>

				<View style={styles.card}>
					<Text style={styles.cardTitle}>Raw Campaign Data</Text>
					{campaigns.length === 0 ? (
						<Text style={styles.small}>No campaigns loaded.</Text>
					) : (
						campaigns.map((c, i) => (
							<View key={i} style={styles.campaignRow}>
								<Text style={styles.campaignType}>
									[{c.campaign_type}] {c.campaign_id ?? c.id}
								</Text>
								<Text style={styles.tiny}>
									screen: {c.screen ?? 'none'} | position: {c.position ?? 'none'}
								</Text>
								<Text style={styles.tiny}>
									image: {String(c.details?.image ?? c.image ?? 'none').substring(0, 60)}
								</Text>
								<Text style={styles.tiny}>trigger: {String(c.trigger_event ?? 'none')}</Text>
							</View>
						))
					)}
				</View>

				<View style={styles.card}>
					<Text style={styles.cardTitle}>Event Log</Text>
					{events.length === 0 ? (
						<Text style={styles.small}>No events tracked yet.</Text>
					) : (
						events.map((e, i) => (
							<Text key={i} style={styles.small}>- {e}</Text>
						))
					)}
				</View>

				<View style={styles.card}>
					<Text style={styles.cardTitle}>Campaign Types Present</Text>
					{[
						'BAN', 'FLT', 'WID', 'MOD', 'BTS', 'STR', 'REL', 'PIP', 'CSAT', 'SUR', 'SCRT', 'SPW', 'MIL',
						'STRK', 'TTP',
					].map((type) => {
						const count = campaigns.filter((c) => c.campaign_type === type).length;
						return (
							<Text key={type} style={[styles.small, { color: count > 0 ? '#22c55e' : '#999' }]}>
								{type}: {count} campaign{count !== 1 ? 's' : ''}
							</Text>
						);
					})}
				</View>
			</ScrollView>
		</SafeAreaView>
	);
}

const styles = StyleSheet.create({
	container: { flex: 1, backgroundColor: '#f0f0f0' },
	scroll: { padding: 16, paddingBottom: 40 },
	title: { fontSize: 22, fontWeight: 'bold', marginBottom: 16, color: '#111' },
	card: {
		backgroundColor: '#fff',
		borderRadius: 12,
		padding: 16,
		marginBottom: 12,
		elevation: 2,
		shadowColor: '#000',
		shadowOpacity: 0.08,
		shadowRadius: 4,
		shadowOffset: { width: 0, height: 2 },
	},
	cardTitle: { fontSize: 15, fontWeight: '700', color: '#222', marginBottom: 4 },
	small: { fontSize: 12, color: '#555', marginTop: 2 },
	tiny: { fontSize: 10, color: '#999', marginTop: 1 },
	error: { fontSize: 12, color: '#ef4444', marginTop: 4, fontWeight: '600' },
	campaignRow: {
		paddingVertical: 6,
		borderBottomWidth: StyleSheet.hairlineWidth,
		borderBottomColor: '#eee',
	},
	campaignType: { fontSize: 12, fontWeight: '600', color: '#333' },
	closeBtn: { position: 'absolute', top: 12, right: 4 },
	closeBtnInner: {
		width: 28,
		height: 28,
		borderRadius: 14,
		backgroundColor: 'rgba(0,0,0,0.5)',
		justifyContent: 'center',
		alignItems: 'center',
	},
	closeBtnText: { color: '#fff', fontSize: 14 },
});

