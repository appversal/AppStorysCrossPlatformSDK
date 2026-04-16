// AppStorys Banner widget for displaying campaign banners in Flutter.
// Subscribes to the AppstorysFlutter.campaignsStream EventChannel and renders
// BAN-type campaigns. No polling — native pushes data the moment the CDN fetch
// completes via the AppStorysCore StateFlow → EventChannel pipeline.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';

/// A widget that displays an AppStorys banner campaign.
///
/// This widget:
/// - Fetches banner campaigns from the AppStorys backend
/// - Displays images, Lottie animations, or GIFs
/// - Tracks "viewed" events on initialization
/// - Tracks "clicked" events when the banner is tapped
/// - Supports responsive sizing based on device width
/// - Provides a close button to dismiss the banner
class AppStorysBanner extends StatefulWidget {
  /// The AppStorys API instance to use for fetching campaigns.
  final AppstorysFlutter appStorys;

  /// Height of the banner if no campaign is available. Default: 92.
  final double height;

  /// Width of the banner. Default: full screen width.
  final double width;

  /// Elevation/shadow of the banner. Default: 0.
  final double elevation;

  /// Margins around the banner. Default: 12 on all sides.
  final EdgeInsets margin;

  /// Optional border radius. If null, uses styling from campaign.
  final BorderRadius? borderRadius;

  /// Callback when banner is dismissed.
  final VoidCallback? onDismissed;

  const AppStorysBanner({
    super.key,
    required this.appStorys,
    this.height = 92,
    this.width = double.infinity,
    this.elevation = 0,
    this.margin = const EdgeInsets.all(12),
    this.borderRadius,
    this.onDismissed,
  });

  @override
  State<AppStorysBanner> createState() => _AppStorysBannerState();
}

class _AppStorysBannerState extends State<AppStorysBanner> {
  BannerCampaign? _currentBanner;
  bool _showBanner = true;
  bool _isLoading = true;
  // Stream subscription replaces the old Timer-based retry loop.
  // Cancelled in dispose() to prevent setState after unmount.
  StreamSubscription<String>? _campaignsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToCampaigns();
  }

  @override
  void dispose() {
    _campaignsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToCampaigns() {
    // campaignsStream is a broadcast stream cached on the AppstorysFlutter instance.
    // StateFlow semantics guarantee the current value arrives immediately — no delay needed.
    _campaignsSubscription = widget.appStorys.campaignsStream.listen(
      _onCampaignsUpdate,
      onError: (Object error) {
        debugPrint('❌ [BANNER] Stream error: $error');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _onCampaignsUpdate(String json) {
    final List<dynamic> allCampaigns;
    try {
      allCampaigns = jsonDecode(json) as List<dynamic>;
    } catch (e) {
      debugPrint('❌ [BANNER] Failed to parse campaigns JSON: $e');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Filter to BAN-type only — the stream carries all campaign types.
    final bannerCampaigns = allCampaigns
        .whereType<Map>()
        .where((c) => c['campaign_type'] == 'BAN')
        .map((c) => c.map((k, v) => MapEntry('$k', v)))
        .toList();

    if (bannerCampaigns.isEmpty) {
      // Empty emission means either no campaigns yet or screen changed.
      // Stay in loading state; next non-empty emission will render.
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final rawCampaign = bannerCampaigns.first;
    final details = rawCampaign['details'] is Map
        ? Map<String, dynamic>.from(rawCampaign['details'] as Map)
        : <String, dynamic>{};

    // Defensive variant flattening — shared-core resolves variants before emitting,
    // but kept here for forward compatibility with any legacy campaign payloads.
    final variantsRaw = details['variants'];
    Map<String, dynamic> firstVariant = const <String, dynamic>{};
    if (variantsRaw is Map) {
      final variantValues = variantsRaw.values
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
      if (variantValues.isNotEmpty) firstVariant = variantValues.first;
    }

    final normalized = <String, dynamic>{
      ...details,
      ...firstVariant,
      'image': details['image'] ?? firstVariant['image'],
      'link': details['link'] ?? firstVariant['link'],
      'width': details['width'] ?? firstVariant['width'],
      'height': details['height'] ?? firstVariant['height'],
      'styling': details['styling'] ?? firstVariant['styling'],
      'id': (rawCampaign['id'] ?? details['id'] ?? firstVariant['id'])?.toString() ?? '',
    };

    debugPrint('🔵 [BANNER] Received campaign via stream: id=${normalized['id']}');

    final banner = BannerCampaign.fromJson(normalized);

    if (mounted) {
      setState(() {
        _currentBanner = banner;
        _isLoading = false;
      });
    }

    if (banner.id.isNotEmpty) {
      widget.appStorys
          .trackEvent(event: 'viewed', campaignId: banner.id)
          .catchError((Object e) {
        debugPrint('❌ [BANNER] Error tracking viewed event: $e');
        return null;
      });
    }
  }

  double _calculateResponsiveHeight({
    required double? bannerWidth,
    required double? bannerHeight,
    required double screenWidth,
  }) {
    if (bannerWidth != null && bannerHeight != null && bannerWidth > 0) {
      final aspectRatio = bannerHeight / bannerWidth;
      final marginLeft = _currentBanner?.styling?.marginLeft ?? 0;
      final marginRight = _currentBanner?.styling?.marginRight ?? 0;
      final availableWidth = screenWidth - marginLeft - marginRight;
      return availableWidth * aspectRatio;
    }
    return widget.height;
  }

  BorderRadius _getBorderRadius() {
    if (widget.borderRadius != null) return widget.borderRadius!;

    final styling = _currentBanner?.styling;
    return BorderRadius.only(
      topLeft: Radius.circular(styling?.topLeftRadius ?? 0),
      topRight: Radius.circular(styling?.topRightRadius ?? 0),
      bottomLeft: Radius.circular(styling?.bottomLeftRadius ?? 0),
      bottomRight: Radius.circular(styling?.bottomRightRadius ?? 0),
    );
  }

  Future<void> _handleBannerTap() async {
    final link = _currentBanner?.link;
    debugPrint('🔵 [BANNER] Tapped | link: $link');

    if (link?.isNotEmpty == true) {
      try {
        await widget.appStorys.trackEvent(
          event: 'clicked',
          campaignId: _currentBanner!.id,
        );
        // TODO: Implement handleNavigation using url_launcher
        // await launchUrl(Uri.parse(link!));
      } catch (e) {
        debugPrint('❌ [BANNER] Error tracking clicked event: $e');
      }
    } else {
      debugPrint('❌ [BANNER] Link is null or empty — nothing to do');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 [BANNER] Build called - loading=$_isLoading, shown=$_showBanner, hasBanner=${_currentBanner != null}');
    
    if (!_showBanner || _currentBanner == null) {
      debugPrint('🔵 [BANNER] Returning shrink - shown=$_showBanner, hasBanner=${_currentBanner != null}');
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      debugPrint('🔵 [BANNER] Still loading, showing shrink');
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = _calculateResponsiveHeight(
      bannerWidth: _currentBanner!.width,
      bannerHeight: _currentBanner!.height,
      screenWidth: screenWidth,
    );

    final isLottie = isLottieUrl(_currentBanner!.lottieData);
    final isImage =
        !isLottie && (_currentBanner!.image?.isNotEmpty ?? false);
    final borderRadius = _getBorderRadius();
    
    debugPrint('🔵 [BANNER] Building banner - height=$bannerHeight, isLottie=$isLottie, isImage=$isImage');

    // If used inside a Stack, return Positioned
    // Otherwise, return Container with padding
    return _buildBannerContent(bannerHeight, isLottie, isImage, borderRadius);
  }

  Widget _buildBannerContent(double bannerHeight, bool isLottie, bool isImage, BorderRadius borderRadius) {
    final marginLeft = _currentBanner!.styling?.marginLeft ?? widget.margin.left;
    final marginRight = _currentBanner!.styling?.marginRight ?? widget.margin.right;
    final marginBottom = _currentBanner!.styling?.marginBottom ?? widget.margin.bottom;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: EdgeInsets.only(
        left: marginLeft,
        right: marginRight,
        bottom: marginBottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              elevation: widget.elevation,
              child: GestureDetector(
                onTap: _handleBannerTap,
                child: Container(
                  height: bannerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: borderRadius,
                    image: isImage
                        ? DecorationImage(
                            image: NetworkImage(_currentBanner!.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: isLottie
                      ? ClipRRect(
                          borderRadius: borderRadius,
                          child: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Text(
                                'Lottie: ${_currentBanner!.lottieData}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            if (_currentBanner!.styling?.crossButton?.enabled == true)
              Positioned(
                top: 0,
                right: 0,
                child: CrossButton(
                  onTap: () {
                    setState(() {
                      _showBanner = false;
                    });
                    widget.onDismissed?.call();
                  },
                  iconSize: _currentBanner!.styling?.crossButton?.size ?? 18,
                  styling: _currentBanner!.styling?.crossButton != null
                      ? {
                          'color': _currentBanner!.styling!.crossButton!.colorObj,
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}









