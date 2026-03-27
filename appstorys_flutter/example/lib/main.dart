import 'package:flutter/material.dart';
import 'dart:async';

import 'package:appstorys_flutter/appstorys_flutter.dart';

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
  String _currentScreen = 'home';

  @override
  void initState() {
    super.initState();
    _appstorys = AppstorysFlutter();
    _initializeAppStorys();
  }

  Future<void> _initializeAppStorys() async {
    try {
      // Initialize the AppStorys SDK
      await _appstorys.initialize(
        appId: 'f69bdccf-b20f-4938-b39e-7075d76db791',
        accountId: '12a9eac5-94ee-4735-9aa6-b8a94cb8fbbb',
        userId: 'yash1',
      );

      // Fetch campaigns for the home screen
      await _appstorys.getScreenCampaigns(screenName: 'Home Screen Flutter');
      debugPrint('✅ AppStorys initialized and campaigns loaded');
    } catch (e) {
      debugPrint('❌ AppStorys init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppStorys Demo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(
        appstorys: _appstorys,
        onScreenChanged: (screenName) {
          setState(() => _currentScreen = screenName);
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppstorysFlutter appstorys;
  final Function(String) onScreenChanged;

  const HomeScreen({
    super.key,
    required this.appstorys,
    required this.onScreenChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _screenNames = ['Home Screen Flutter', 'Products', 'Profile', 'Settings'];

  Future<void> _loadScreenCampaigns(String screenName) async {
    try {
      await widget.appstorys.getScreenCampaigns(screenName: screenName);
      debugPrint('✅ Campaigns loaded for: $screenName');
    } catch (e) {
      debugPrint('❌ Error loading campaigns for $screenName: $e');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final screenName = _screenNames[index];
    widget.onScreenChanged(screenName);
    _loadScreenCampaigns(screenName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppStorys Demo'),
        elevation: 2,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Main content based on selected tab
          _buildContent(),
          
          // AppStorys Banner overlay (positioned at top)
          AppStorysBanner(
            appStorys: widget.appstorys,
            height: 120,
            margin: const EdgeInsets.all(16),
            onDismissed: () {
              debugPrint('✅ Banner dismissed by user');
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildProductsTab();
      case 2:
        return _buildProfileTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 150), // Space for banner
          const Text(
            'Welcome to AppStorys',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Personalized campaigns and engagement at scale',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildFeatureCard(
            icon: Icons.campaign,
            title: 'Dynamic Campaigns',
            description: 'Show personalized content based on user behavior',
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.analytics,
            title: 'Real-time Analytics',
            description: 'Track engagement and conversion metrics',
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.bolt,
            title: 'High Performance',
            description: 'KMP-powered SDK for all platforms',
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _trackCustomEvent('cta_clicked'),
            icon: const Icon(Icons.touch_app),
            label: const Text('Track Custom Event'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 150), // Space for banner
          const Text(
            'Featured Products',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...[
            _buildProductCard('Premium Plan', '\$99/month', '✓ All features\n✓ Priority support'),
            _buildProductCard('Standard Plan', '\$49/month', '✓ Core features\n✓ Email support'),
            _buildProductCard('Starter Plan', '\$9/month', '✓ Basic features\n✓ Community'),
          ]
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: e,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 150), // Space for banner
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[100],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileField('Name', 'Yash Demo User'),
          _buildProfileField('Email', 'yash1@appstorys.co'),
          _buildProfileField('User ID', 'yash1'),
          _buildProfileField('Status', 'Identified User'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _trackCustomEvent('profile_viewed'),
            icon: const Icon(Icons.visibility),
            label: const Text('Track Profile View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 150), // Space for banner
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSettingsTile('Notifications', 'Manage campaign notifications', () {}),
          _buildSettingsTile('Privacy', 'Control data usage and tracking', () {}),
          _buildSettingsTile('About', 'App version and information', () {}),
          _buildSettingsTile('Help & Support', 'Contact support team', () {}),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(String name, String price, String features) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(features, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _trackCustomEvent('product_selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Select Plan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }

  Future<void> _trackCustomEvent(String eventName) async {
    try {
      await widget.appstorys.trackEvent(
        event: eventName,
        metadata: <String, Object?>{'screen': _screenNames[_selectedIndex]},
      );
      debugPrint('✅ Event tracked: $eventName');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event tracked: $eventName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error tracking event: $e');
    }
  }
}

