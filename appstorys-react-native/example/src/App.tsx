/**
 * AppStorys React Native — Example App
 *
 * KMP architecture:
 *   - AppStorys.initialize() once at root
 *   - <Screen name="..."> wraps each screen — provides ScreenProvider + Overlay
 *   - Overlay automatically renders Banner, Floater, Csat, Survey, BottomSheet, Modal, CaptureScreenButton
 *   - No manual campaign prop passing — all components read from ScreenContext
 */
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Linking,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import AppStorys, { Screen, Stories, Widgets, Measurable } from 'appstorys-react-native';

// ─── SDK credentials ────────────────────────────────────────────────────────
const APP_ID     = 'f69bdccf-b20f-4938-b39e-7075d76db791';
const ACCOUNT_ID = '12a9eac5-94ee-4735-9aa6-b8a94cb8fbbb';
const USER_ID    = 'yash1';

// ─── Screen names must match what is configured in the AppStorys dashboard ──
const SCREENS = [
  'Home Screen Kotlin',
  'Products',
  'Profile',
  'Settings',
] as const;

type TabIdx = 0 | 1 | 2 | 3;
const TAB_LABELS = ['Home', 'Shop', 'Profile', 'Settings'] as const;

// ─── Root ────────────────────────────────────────────────────────────────────

export default function App() {
  const [initialized, setInitialized] = useState(false);
  const [initError, setInitError]     = useState<string | null>(null);
  const [tab, setTab]                 = useState<TabIdx>(0);

  useEffect(() => {
    AppStorys.initialize(APP_ID, ACCOUNT_ID, USER_ID)
      .then(() => setInitialized(true))
      .catch((e: any) => setInitError(e?.message ?? String(e)));
  }, []);

  if (initError) {
    return (
      <SafeAreaView style={styles.center}>
        <Text style={styles.errorText}>SDK init failed:{'\n'}{initError}</Text>
      </SafeAreaView>
    );
  }

  if (!initialized) {
    return (
      <SafeAreaView style={styles.center}>
        <ActivityIndicator size="large" color="#4f46e5" />
        <Text style={styles.initLabel}>Initializing AppStorys...</Text>
      </SafeAreaView>
    );
  }

  const renderScreen = () => {
    switch (tab) {
      case 0: return <HomeTab />;
      case 1: return <ShopTab />;
      case 2: return <ProfileTab />;
      case 3: return <SettingsTab />;
    }
  };

  return (
    // SafeAreaProvider required by react-native-safe-area-context (used in Screen/Overlay)
    <SafeAreaProvider>
      <SafeAreaView style={styles.root}>
        {/* Screen wraps each screen — provides ScreenProvider + Overlay.
            Overlay auto-renders Banner, Floater, Csat, Survey, BottomSheet, Modal. */}
        <View style={styles.body}>
          <Screen name={SCREENS[tab]} options={{ positionList: ['widget_one', 'widget_two'] }}>
            {renderScreen()}
          </Screen>
        </View>

        {/* Bottom tab bar */}
        <View style={styles.tabBar}>
          {TAB_LABELS.map((label, i) => {
            const active = tab === i;
            return (
              <TouchableOpacity
                key={label}
                style={styles.tabItem}
                onPress={() => setTab(i as TabIdx)}
                activeOpacity={0.7}
              >
                <Text style={[styles.tabLabel, active && styles.tabLabelActive]}>
                  {label}
                </Text>
                {active && <View style={styles.tabIndicator} />}
              </TouchableOpacity>
            );
          })}
        </View>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

function HomeTab() {
  const [hasStories, setHasStories] = useState(false);

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Measurable appstorys="home-app-bar">
        <View style={styles.appBar}>
          <Text style={styles.appBarTitle}>Good morning, Yash 👋</Text>
        </View>
      </Measurable>

      {/* Stories — inline, reads STR campaign from ScreenContext */}
      <View style={styles.section}>
        {hasStories && <SectionHeader title="Featured Stories" />}
        <Measurable appstorys="home-stories-row">
          <View onLayout={(e) => setHasStories(e.nativeEvent.layout.height > 0)}>
            <Stories />
          </View>
        </Measurable>
      </View>

      {/* Widgets — position widget_one */}
      <Measurable appstorys="home-widget-one">
        <Widgets leftPadding={16} rightPadding={16} position="widget_one" />
      </Measurable>

      {/* Mock: Featured Deals */}
      <View style={styles.section}>
        <Measurable appstorys="home-deals-header">
          <SectionHeader title="Featured Deals" />
        </Measurable>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          {DEALS.map((d, i) => (
            <Measurable key={d.title} appstorys={`home-deal-card-${i}`}>
              <DealCard {...d} />
            </Measurable>
          ))}
        </ScrollView>
      </View>

      {/* Widgets — position widget_two */}
      <Measurable appstorys="home-widget-two">
        <Widgets leftPadding={16} rightPadding={16} position="widget_two" />
      </Measurable>

      {/* Mock: Categories */}
      <View style={styles.section}>
        <Measurable appstorys="home-categories-header">
          <SectionHeader title="Categories" />
        </Measurable>
        <View style={styles.categories}>
          {CATEGORIES.map((c) => (
            <Measurable key={c.label} appstorys={`home-category-${c.label.toLowerCase()}`}>
              <CategoryChip {...c} />
            </Measurable>
          ))}
        </View>
      </View>

      {/* Mock: Trending */}
      <View style={styles.section}>
        <Measurable appstorys="home-trending-header">
          <SectionHeader title="Trending Now" />
        </Measurable>
        {TRENDING.map((p, i) => (
          <Measurable key={p.name} appstorys={`home-trending-item-${i}`}>
            <ProductTile {...p} />
          </Measurable>
        ))}
      </View>
    </ScrollView>
  );
}

// ─── Shop Tab ────────────────────────────────────────────────────────────────

function ShopTab() {
  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.screenTitle}>Shop</Text>
      <View style={styles.grid}>
        {PRODUCTS.map((p) => <ProductGridCard key={p.name} {...p} />)}
      </View>
    </ScrollView>
  );
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

function ProfileTab() {
  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.screenTitle}>My Profile</Text>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>YD</Text>
      </View>
      <Text style={styles.profileName}>Yash Demo</Text>
      <Text style={styles.profileEmail}>yash1@appstorys.co</Text>
      <View style={styles.section}>
        {PROFILE_TILES.map((t) => <InfoTile key={t.title} {...t} />)}
      </View>
    </ScrollView>
  );
}

// ─── Settings Tab ─────────────────────────────────────────────────────────────

function SettingsTab() {
  const [snack, setSnack] = useState('');

  const trackTestEvent = async () => {
    await AppStorys.trackEvent('settings_opened');
    setSnack('Event tracked: settings_opened');
    setTimeout(() => setSnack(''), 2500);
  };

  return (
    <ScrollView contentContainerStyle={styles.scroll}>
      <Text style={styles.screenTitle}>Settings</Text>

      <SectionHeader title="Account" />
      <InfoTile title="Notifications"      subtitle="Manage push alerts" />
      <InfoTile title="Privacy & Security" subtitle="Data and permissions" />
      <InfoTile title="Language"           subtitle="English" />

      <SectionHeader title="SDK Debug" />
      <Pressable style={styles.debugButton} onPress={trackTestEvent}>
        <Text style={styles.debugButtonText}>Track Test Event</Text>
      </Pressable>
      {snack ? <Text style={styles.snack}>{snack}</Text> : null}

      <SectionHeader title="Support" />
      <InfoTile title="Help Center" subtitle="FAQs and guides" />
      <InfoTile title="About" subtitle="AppStorys SDK" onPress={() =>
        Linking.openURL('https://appversal.com').catch(() => {})
      } />
    </ScrollView>
  );
}

// ─── Shared UI primitives ─────────────────────────────────────────────────────

function SectionHeader({ title }: { title: string }) {
  return <Text style={styles.sectionTitle}>{title}</Text>;
}

function DealCard({ title, color }: { title: string; color: string }) {
  return (
    <View style={[styles.dealCard, { backgroundColor: color }]}>
      <Text style={styles.dealTitle}>{title}</Text>
      <Text style={styles.dealSub}>Tap to explore</Text>
    </View>
  );
}

function CategoryChip({ label }: { label: string }) {
  return (
    <View style={styles.chip}>
      <Text style={styles.chipText}>{label}</Text>
    </View>
  );
}

function ProductTile({ name, category, price }: typeof TRENDING[number]) {
  return (
    <View style={styles.productTile}>
      <View style={styles.productTileIcon} />
      <View style={styles.productTileInfo}>
        <Text style={styles.productTileName}>{name}</Text>
        <Text style={styles.productTileCat}>{category}</Text>
      </View>
      <Text style={styles.productTilePrice}>{price}</Text>
    </View>
  );
}

function ProductGridCard({ name, category, price }: typeof PRODUCTS[number]) {
  return (
    <View style={styles.gridCard}>
      <View style={styles.gridCardImage} />
      <Text style={styles.gridCardName} numberOfLines={1}>{name}</Text>
      <Text style={styles.gridCardCat}>{category}</Text>
      <Text style={styles.gridCardPrice}>{price}</Text>
    </View>
  );
}

function InfoTile({ title, subtitle, onPress }: { title: string; subtitle?: string; onPress?: () => void }) {
  return (
    <TouchableOpacity style={styles.infoTile} onPress={onPress} activeOpacity={onPress ? 0.7 : 1}>
      <View style={styles.infoTileText}>
        <Text style={styles.infoTileTitle}>{title}</Text>
        {subtitle && <Text style={styles.infoTileSub}>{subtitle}</Text>}
      </View>
      <Text style={styles.chevron}>›</Text>
    </TouchableOpacity>
  );
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const DEALS = [
  { title: '50% Off Electronics', color: '#ffd7aa' },
  { title: 'Buy 2 Get 1 Free',    color: '#bbf7d0' },
  { title: 'Flash Sale: 6PM',     color: '#fecaca' },
];

const CATEGORIES = [
  { label: 'Electronics' },
  { label: 'Fashion'     },
  { label: 'Home'        },
  { label: 'Sports'      },
];

const TRENDING = [
  { name: 'Wireless Earbuds', category: 'Electronics', price: '₹1,299' },
  { name: 'Running Shoes',    category: 'Sports',      price: '₹2,499' },
  { name: 'Smart Watch',      category: 'Electronics', price: '₹4,999' },
];

const PRODUCTS = [
  { name: 'Wireless Earbuds',  category: 'Electronics', price: '₹1,299' },
  { name: 'Running Shoes',     category: 'Sports',      price: '₹2,499' },
  { name: 'Smart Watch',       category: 'Electronics', price: '₹4,999' },
  { name: 'Denim Jacket',      category: 'Fashion',     price: '₹1,899' },
  { name: 'Coffee Maker',      category: 'Home',        price: '₹3,199' },
  { name: 'Yoga Mat',          category: 'Sports',      price: '₹699'   },
  { name: 'Bluetooth Speaker', category: 'Electronics', price: '₹2,199' },
  { name: 'Backpack',          category: 'Fashion',     price: '₹1,099' },
];

const PROFILE_TILES = [
  { title: 'My Orders',       subtitle: '3 active orders' },
  { title: 'Wishlist',        subtitle: '12 saved items'  },
  { title: 'Rewards',         subtitle: '480 points'      },
  { title: 'Saved Addresses', subtitle: '2 addresses'     },
];

// ─── Styles ──────────────────────────────────────────────────────────────────

const INDIGO = '#4f46e5';

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: '#f5f5f5' },
  body:   { flex: 1 },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  scroll: { paddingBottom: 40 },

  initLabel: { marginTop: 12, color: '#555' },
  errorText: { color: '#ef4444', textAlign: 'center', fontSize: 14 },

  appBar: {
    backgroundColor: INDIGO,
    paddingVertical: 20,
    paddingHorizontal: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  appBarTitle: { color: '#fff', fontSize: 18, fontWeight: '700' },

  screenTitle: { fontSize: 22, fontWeight: '700', color: '#111', margin: 16 },

  section:      { paddingHorizontal: 16, marginTop: 16 },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: '#222', marginBottom: 12 },

  dealCard:  { width: 180, height: 120, borderRadius: 12, padding: 16, marginRight: 12, justifyContent: 'flex-end' },
  dealTitle: { fontWeight: '700', fontSize: 14 },
  dealSub:   { fontSize: 11, color: '#555', marginTop: 2 },

  categories: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip:       { backgroundColor: '#e0e7ff', borderRadius: 20, paddingVertical: 6, paddingHorizontal: 14 },
  chipText:   { color: INDIGO, fontWeight: '600', fontSize: 12 },

  productTile: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff',
    borderRadius: 10, padding: 12, marginBottom: 8, elevation: 1,
    shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 2, shadowOffset: { width: 0, height: 1 },
  },
  productTileIcon:  { width: 40, height: 40, borderRadius: 20, backgroundColor: '#e0e7ff', marginRight: 12 },
  productTileInfo:  { flex: 1 },
  productTileName:  { fontWeight: '600', color: '#222' },
  productTileCat:   { fontSize: 11, color: '#999', marginTop: 2 },
  productTilePrice: { fontWeight: '700', color: INDIGO },

  grid:          { flexDirection: 'row', flexWrap: 'wrap', padding: 8, gap: 8 },
  gridCard:      { width: '47%', backgroundColor: '#fff', borderRadius: 10, overflow: 'hidden', padding: 8 },
  gridCardImage: { height: 100, backgroundColor: '#e0e7ff', borderRadius: 8, marginBottom: 8 },
  gridCardName:  { fontWeight: '700', fontSize: 13, color: '#222' },
  gridCardCat:   { fontSize: 11, color: '#999' },
  gridCardPrice: { fontWeight: '700', color: INDIGO, marginTop: 4 },

  avatar:       { width: 88, height: 88, borderRadius: 44, backgroundColor: '#e0e7ff', alignSelf: 'center', marginTop: 24, justifyContent: 'center', alignItems: 'center' },
  avatarText:   { fontSize: 28, fontWeight: '700', color: INDIGO },
  profileName:  { textAlign: 'center', fontSize: 20, fontWeight: '700', marginTop: 8, color: '#111' },
  profileEmail: { textAlign: 'center', fontSize: 13, color: '#999', marginBottom: 4 },

  infoTile:      { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', padding: 14, marginBottom: 1 },
  infoTileText:  { flex: 1 },
  infoTileTitle: { fontWeight: '600', color: '#222' },
  infoTileSub:   { fontSize: 12, color: '#999', marginTop: 2 },
  chevron:       { fontSize: 20, color: '#ccc' },

  debugButton:     { margin: 16, backgroundColor: '#222', borderRadius: 10, paddingVertical: 14, alignItems: 'center' },
  debugButtonText: { color: '#fff', fontWeight: '600', fontSize: 15 },
  snack:           { textAlign: 'center', color: '#22c55e', marginTop: 8, fontWeight: '600' },

  tabBar:          { flexDirection: 'row', backgroundColor: '#fff', borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: '#ddd', paddingBottom: 4 },
  tabItem:         { flex: 1, alignItems: 'center', paddingTop: 10, paddingBottom: 4 },
  tabLabel:        { fontSize: 12, color: '#aaa', fontWeight: '500' },
  tabLabelActive:  { color: INDIGO, fontWeight: '700' },
  tabIndicator:    { width: 4, height: 4, borderRadius: 2, backgroundColor: INDIGO, marginTop: 3 },
});
