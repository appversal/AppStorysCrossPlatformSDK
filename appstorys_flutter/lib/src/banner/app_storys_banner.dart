// AppStorys Banner widget for displaying campaign banners in Flutter.
// Subscribes to the AppstorysFlutter.campaignsStream EventChannel and renders
// BAN-type campaigns. No polling — native pushes data the moment the CDN fetch
// completes via the AppStorysCore StateFlow → EventChannel pipeline.

import 'dart:convert';
import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';

/// A widget that displays an AppStorys banner campaign.
///
/// This widget:
/// - Fetches banner campaigns from the AppStorys backend
/// - Displays images, Lottie animations, or GIFs
/// - Tracks "viewed" events on initialization
/// - Tracks "clicked" events when the banner is tapped
/// - Supports responsive sizing based on device width
/// - Provides a close button to dismiss the banner


/// PUBLIC widget (used by app)
class AppStorysBanner extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final double height;
  final double width;
  final double elevation;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onDismissed;
  /// Extra space below the banner — pass the host BottomNavigationBar height
  /// so the banner sits above it. Added on top of any backend-configured margin.
  final double bottomPadding;
  /// Callback for handling banner link clicks — receives the link (URL or screen name).
  final void Function(String link)? onTap;

  const AppStorysBanner({
    super.key,
    required this.appStorys,
    this.height = 92,
    this.width = double.infinity,
    this.elevation = 0,
    this.margin = const EdgeInsets.all(12),
    this.borderRadius,
    this.onDismissed,
    this.bottomPadding = 0,
    this.onTap,
  });

  @override
  State<AppStorysBanner> createState() => _AppStorysBannerState();
}

/// STATE (logic)
class _AppStorysBannerState extends State<AppStorysBanner>
    with CampaignsStreamMixin {
  BannerCampaign? _banner;
  bool _visible = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    subscribeToCampaigns(
      widget.appStorys.campaignsStream,
      _handleCampaigns,
      onError: _stopLoading,
    );
  }

  void _stopLoading() {
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _handleCampaigns(String json) {
    final banner = _parseBanner(json);

    if (!mounted) return;

    final isNewCampaign = banner?.id != _banner?.id;

    setState(() {
      _banner = banner;
      _loading = false;
      if (banner == null) _visible = true;
    });

    if (isNewCampaign) _trackView(banner);
  }

  BannerCampaign? _parseBanner(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;

      final raw = data
          .whereType<Map>()
          .firstWhere(
            (c) => c['campaign_type'] == 'BAN',
        orElse: () => {},
      );

      if (raw.isEmpty) return null;

      return BannerCampaign.fromJson(_normalizeCampaign(raw));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalizeCampaign(Map raw) {
    final details = Map<String, dynamic>.from(raw['details'] ?? {});
    final variant = _extractVariant(details);

    return {
      ...details,
      ...variant,
      'image': details['image'] ?? variant['image'],
      'link': details['link'] ?? variant['link'],
      'width': details['width'] ?? variant['width'],
      'height': details['height'] ?? variant['height'],
      'styling': details['styling'] ?? variant['styling'],
      'id': (raw['id'] ?? details['id'] ?? variant['id'])?.toString() ?? '',
    };
  }

  Map<String, dynamic> _extractVariant(Map<String, dynamic> details) {
    final variants = details['variants'];

    if (variants is Map) {
      final list = variants.values
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      if (list.isNotEmpty) return list.first;
    }

    return {};
  }

  void _trackView(BannerCampaign? banner) {
    if (banner?.id.isEmpty ?? true) return;

    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: banner!.id)
        .catchError((_) {});

    // Dismiss the banner from core after tracking the view.
    // This prevents it from re-appearing when navigating back to the same screen,
    // matching Kotlin's approach of using disableCampaign() for overlay campaigns.
    widget.appStorys.dismissCampaign(banner.id).catchError((_) {});
  }

  Future<void> _onTap() async {
    final banner = _banner;
    if (banner?.id.isEmpty ?? true) return;

    await widget.appStorys
        .trackEvent(event: 'clicked', campaignId: banner!.id)
        .catchError((_) {});

    final link = banner.link;
    if (link?.isNotEmpty == true) {
      widget.onTap?.call(link!);
    }
  }

  BorderRadius _resolveBorderRadius() {
    if (widget.borderRadius != null) return widget.borderRadius!;

    final s = _banner?.styling;

    return BorderRadius.only(
      topLeft: Radius.circular(s?.topLeftRadius ?? 0),
      topRight: Radius.circular(s?.topRightRadius ?? 0),
      bottomLeft: Radius.circular(s?.bottomLeftRadius ?? 0),
      bottomRight: Radius.circular(s?.bottomRightRadius ?? 0),
    );
  }

  double? get _aspectRatio {
    final b = _banner;
    if (b?.width != null &&
        b?.height != null &&
        b!.width! > 0 &&
        b.height! > 0) {
      return b.height! / b.width!;
    }
    return null;
  }

  double? get _forcedHeight {
    final b = _banner;
    if (b?.width == null && b?.height != null) {
      return b!.height;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;

    if (!_visible || banner == null || _loading) {
      return const SizedBox.shrink();
    }

    final borderRadius = _resolveBorderRadius();
    final isLottie = isLottieUrl(banner.lottieData);
    final isImage = !isLottie && (banner.image?.isNotEmpty ?? false);

    return _BannerView(
      banner: banner,
      borderRadius: borderRadius,
      elevation: widget.elevation,
      margin: widget.margin,
      bottomPadding: widget.bottomPadding,
      forcedHeight: _forcedHeight,
      aspectRatio: _aspectRatio,
      isImage: isImage,
      isLottie: isLottie,
      onTap: _onTap,
      onClose: () {
        setState(() => _visible = false);
        widget.onDismissed?.call();
      },
    );
  }
}

/// UI LAYER (separate clean widget)
class _BannerView extends StatelessWidget {
  final BannerCampaign banner;
  final BorderRadius borderRadius;
  final double elevation;
  final EdgeInsets margin;
  final double bottomPadding;
  final double? forcedHeight;
  final double? aspectRatio;
  final bool isImage;
  final bool isLottie;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _BannerView({
    required this.banner,
    required this.borderRadius,
    required this.elevation,
    required this.margin,
    required this.bottomPadding,
    required this.forcedHeight,
    required this.aspectRatio,
    required this.isImage,
    required this.isLottie,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final fit = forcedHeight != null ? BoxFit.fill : BoxFit.fitWidth;

    Widget content = GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          image: isImage
              ? DecorationImage(
            image: NetworkImage(banner.image!),
            fit: fit,
          )
              : null,
        ),
        child: isLottie ? _lottieFallback() : const SizedBox.shrink(),
      ),
    );

    if (forcedHeight != null) {
      content = SizedBox(
        height: forcedHeight,
        width: double.infinity,
        child: content,
      );
    } else if (aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: 1 / aspectRatio!,
        child: content,
      );
    }

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: EdgeInsets.only(
        left: banner.styling?.marginLeft ?? margin.left,
        right: banner.styling?.marginRight ?? margin.right,
        bottom: (banner.styling?.marginBottom ?? margin.bottom) + bottomPadding,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              elevation: elevation,
              color: Colors.transparent,
              child: content,
            ),
            if (banner.styling?.crossButton?.enabled == true)
              Positioned(
                top: banner.styling?.crossButton?.margin?.top ?? 0,
                right: banner.styling?.crossButton?.margin?.right ?? 0,
                child: CrossButton(
                  onTap: onClose,
                  iconSize: banner.styling?.crossButton?.size ?? 18,
                  styling: {
                    'color': banner.styling?.crossButton?.colorObj,
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lottieFallback() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Text(
        'Lottie: ${banner.lottieData}',
        textAlign: TextAlign.center,
      ),
    );
  }
}