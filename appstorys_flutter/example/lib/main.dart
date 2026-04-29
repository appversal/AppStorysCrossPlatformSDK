import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appstorys_flutter/appstorys_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppstorysFlutter _appstorys;

  @override
  void initState() {
    super.initState();
    _appstorys = AppstorysFlutter();
    _init();
  }

  Future<void> _init() async {
    await _appstorys.initialize(
      appId: 'f69bdccf-b20f-4938-b39e-7075d76db791',
      accountId: '12a9eac5-94ee-4735-9aa6-b8a94cb8fbbb',
      userId: 'yash1',
    );
    await _appstorys.getScreenCampaigns(screenName: 'Home Screen Flutter');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppStorys Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: HomeScreen(appstorys: _appstorys),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppstorysFlutter appstorys;

  const HomeScreen({super.key, required this.appstorys});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  StreamSubscription<String>? _campaignsSub;

  static const _screenNames = [
    'Home Screen Flutter',
    'Products',
    'Profile',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _campaignsSub = widget.appstorys.campaignsStream.listen((json) {
      final decoded = jsonDecode(json);
      if (decoded is! List) return;
      final campaigns = decoded
          .whereType<Map>()
          .map((e) => Map<String, Object?>.from(e))
          .toList();

      final ttpCount = campaigns.where((c) => c['campaign_type'] == 'TTP').length;
      debugPrint('[TooltipTest] campaigns received: ${campaigns.length}, TTP: $ttpCount');

      if (ttpCount > 0 && mounted) {
        widget.appstorys.processTooltips(context, campaigns);
      }
    });
  }

  @override
  void dispose() {
    _campaignsSub?.cancel();
    TooltipManager.reset();
    super.dispose();
  }

  Future<void> _onTabTapped(int index) async {
    TooltipManager.reset();
    setState(() => _selectedIndex = index);
    await widget.appstorys.getScreenCampaigns(screenName: _screenNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildScreen(_selectedIndex),
          AppStorysBanner(appStorys: widget.appstorys, height: 120),
          AppStorysFloater(
            appStorys: widget.appstorys,
            onTap: (link) async {
              final uri = Uri.tryParse(link);
              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          widget.appstorys.captureScreenWidget(
            screenName: _screenNames[_selectedIndex],
            screenContext: context,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return const _HomeTab();
      case 1: return const _ShopTab();
      case 2: return const _ProfileTab();
      case 3: return _SettingsTab(appstorys: widget.appstorys);
      default: return const _HomeTab();
    }
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Good morning, Yash 👋'),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.indigo.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 120), // space for banner
              // ValueKey tags must match the `target` field in the AppStorys dashboard
              _SectionHeader(key: const ValueKey('featured_deals'), title: 'Featured Deals'),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _DealCard(title: '50% Off Electronics', color: Colors.orange.shade100),
                    _DealCard(title: 'Buy 2 Get 1 Free', color: Colors.green.shade100),
                    _DealCard(title: 'Flash Sale: 6PM', color: Colors.red.shade100),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(key: const ValueKey('categories'), title: 'Categories'),
              const SizedBox(height: 12),
              Row(
                key: const ValueKey('categories_row'),
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CategoryChip(icon: Icons.phone_android, label: 'Electronics'),
                  _CategoryChip(icon: Icons.checkroom, label: 'Fashion'),
                  _CategoryChip(icon: Icons.blender, label: 'Home'),
                  _CategoryChip(icon: Icons.sports_soccer, label: 'Sports'),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(key: const ValueKey('trending_now'), title: 'Trending Now'),
              const SizedBox(height: 12),
              ..._trendingProducts.map((p) => _ProductListTile(product: p)),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Shop Tab ─────────────────────────────────────────────────────────────────

class _ShopTab extends StatelessWidget {
  const _ShopTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Shop'), pinned: true),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ProductGridCard(product: _allProducts[i]),
              childCount: _allProducts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('My Profile'), pinned: true),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.indigo.shade100,
                child: const Text('YD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: Text('Yash Demo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const Center(child: Text('yash1@appstorys.co', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 24),
            _InfoTile(icon: Icons.local_shipping_outlined, title: 'My Orders', subtitle: '3 active orders'),
            _InfoTile(icon: Icons.favorite_outline, title: 'Wishlist', subtitle: '12 saved items'),
            _InfoTile(icon: Icons.card_giftcard_outlined, title: 'Rewards', subtitle: '480 points'),
            _InfoTile(icon: Icons.location_on_outlined, title: 'Saved Addresses', subtitle: '2 addresses'),
          ]),
        ),
      ],
    );
  }
}

// ─── Settings Tab ─────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final AppstorysFlutter appstorys;

  const _SettingsTab({required this.appstorys});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Settings'), pinned: true),
        SliverList(
          delegate: SliverChildListDelegate([
            const _SectionHeader(title: 'Account', padding: EdgeInsets.fromLTRB(16, 20, 16, 8)),
            _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications'),
            _SettingsTile(icon: Icons.lock_outline, title: 'Privacy & Security'),
            _SettingsTile(icon: Icons.language_outlined, title: 'Language'),
            const _SectionHeader(title: 'SDK Debug', padding: EdgeInsets.fromLTRB(16, 20, 16, 8)),
            _SettingsTile(
              icon: Icons.track_changes,
              title: 'Track Test Event',
              onTap: () async {
                await appstorys.trackEvent(event: 'settings_opened');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event tracked: settings_opened')),
                  );
                }
              },
            ),
            const _SectionHeader(title: 'Support', padding: EdgeInsets.fromLTRB(16, 20, 16, 8)),
            _SettingsTile(icon: Icons.help_outline, title: 'Help Center'),
            _SettingsTile(icon: Icons.info_outline, title: 'About'),
          ]),
        ),
      ],
    );
  }
}

// ─── Reusable small widgets ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsets padding;

  const _SectionHeader({super.key, required this.title, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _DealCard extends StatelessWidget {
  final String title;
  final Color color;

  const _DealCard({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_offer, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tap to explore', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final _Product product;

  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Icon(product.icon, color: Colors.indigo)),
        title: Text(product.name),
        subtitle: Text(product.category, style: const TextStyle(fontSize: 12)),
        trailing: Text(product.price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final _Product product;

  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: Colors.indigo.shade50,
              alignment: Alignment.center,
              child: Icon(product.icon, size: 48, color: Colors.indigo.shade300),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(product.category, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(product.price, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ─── Mock data ────────────────────────────────────────────────────────────────

class _Product {
  final String name;
  final String category;
  final String price;
  final IconData icon;

  const _Product({required this.name, required this.category, required this.price, required this.icon});
}

const _trendingProducts = [
  _Product(name: 'Wireless Earbuds', category: 'Electronics', price: '₹1,299', icon: Icons.headphones),
  _Product(name: 'Running Shoes', category: 'Sports', price: '₹2,499', icon: Icons.directions_run),
  _Product(name: 'Smart Watch', category: 'Electronics', price: '₹4,999', icon: Icons.watch),
];

const _allProducts = [
  _Product(name: 'Wireless Earbuds', category: 'Electronics', price: '₹1,299', icon: Icons.headphones),
  _Product(name: 'Running Shoes', category: 'Sports', price: '₹2,499', icon: Icons.directions_run),
  _Product(name: 'Smart Watch', category: 'Electronics', price: '₹4,999', icon: Icons.watch),
  _Product(name: 'Denim Jacket', category: 'Fashion', price: '₹1,899', icon: Icons.checkroom),
  _Product(name: 'Coffee Maker', category: 'Home', price: '₹3,199', icon: Icons.coffee),
  _Product(name: 'Yoga Mat', category: 'Sports', price: '₹699', icon: Icons.sports_gymnastics),
  _Product(name: 'Bluetooth Speaker', category: 'Electronics', price: '₹2,199', icon: Icons.speaker),
  _Product(name: 'Backpack', category: 'Fashion', price: '₹1,099', icon: Icons.backpack),
];
