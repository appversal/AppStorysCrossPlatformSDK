import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../tooltips/capture_manager.dart';

/// Persistent floating overlay that renders Banner, Floater, PiP, BottomSheet,
/// and Modal campaigns above your screen content.
///
/// Place this inside your screen's root Stack (as a sibling of your scrollable
/// body), equivalent to spreading Kotlin's `overlayElements()` into a Compose
/// Box. Stories and Widget campaigns are NOT rendered here — use
/// [AppStorysStories] and [AppStorysWidget] inline inside your scroll view.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     MyScrollableBody(),
///     AppStorysOverlay(
///       appStorys: _appstorys,
///       screenName: 'Home Screen',
///       bottomPadding: kBottomNavigationBarHeight,
///       onLinkTap: (link) => launchUrl(Uri.parse(link)),
///     ),
///   ],
/// )
/// ```
class AppStorysOverlay extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;

  /// Pass your BottomNavigationBar height so overlays sit above it.
  final double bottomPadding;

  /// Pass your AppBar height if you want PiP to stay below it.
  final double topPadding;

  /// Screen name passed to the capture button (test-user tool).
  /// When omitted the button still works but the captured layout is
  /// uploaded without a screen name.
  final String? screenName;

  const AppStorysOverlay({
    super.key,
    required this.appStorys,
    this.onLinkTap,
    this.bottomPadding = 0,
    this.topPadding = 0,
    this.screenName,
  });

  @override
  State<AppStorysOverlay> createState() => _AppStorysOverlayState();
}

class _AppStorysOverlayState extends State<AppStorysOverlay> {
  StreamSubscription<String>? _campaignsSubscription;
  String? _pendingTooltipPayload;
  bool _tooltipProcessScheduled = false;

  @override
  void initState() {
    super.initState();
    _subscribeToCampaigns();
  }

  @override
  void didUpdateWidget(covariant AppStorysOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appStorys != widget.appStorys) {
      _unsubscribeFromCampaigns();
      _subscribeToCampaigns();
    }
  }

  @override
  void dispose() {
    _unsubscribeFromCampaigns();
    super.dispose();
  }

  void _subscribeToCampaigns() {
    _campaignsSubscription = widget.appStorys.campaignsStream.listen(
      _queueTooltipProcessing,
      onError: (_) {},
    );
  }

  void _unsubscribeFromCampaigns() {
    _campaignsSubscription?.cancel();
    _campaignsSubscription = null;
  }

  void _queueTooltipProcessing(String json) {
    _pendingTooltipPayload = json;
    if (_tooltipProcessScheduled) return;
    _tooltipProcessScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _tooltipProcessScheduled = false;
      if (!mounted || _pendingTooltipPayload == null) return;

      final payload = _pendingTooltipPayload!;
      _pendingTooltipPayload = null;

      final campaigns = _parseCampaigns(payload);
      if (campaigns.isEmpty) return;

      await widget.appStorys.processTooltips(context, campaigns);
    });
  }

  List<Map<String, Object?>> _parseCampaigns(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [

          AppStorysBanner(
            appStorys: widget.appStorys,
            bottomPadding: widget.bottomPadding,
            onTap: widget.onLinkTap,
          ),

          AppStorysFloater(
            appStorys: widget.appStorys,
            bottomPadding: widget.bottomPadding,
            onTap: widget.onLinkTap,
          ),

          AppStorysPip(
            appStorys: widget.appStorys,
            bottomPadding: widget.bottomPadding,
            topPadding: widget.topPadding,
            onLinkTap: widget.onLinkTap,
          ),

          AppStorysBottomSheet(
            appStorys: widget.appStorys,
            onLinkTap: widget.onLinkTap,
          ),

          AppStorysModal(
            appStorys: widget.appStorys,
            onLinkTap: widget.onLinkTap,
          ),

          AppStorysCsat(
            appStorys: widget.appStorys,
            onLinkTap: widget.onLinkTap,
          ),

          AppStorysSurvey(
            appStorys: widget.appStorys,
            onLinkTap: widget.onLinkTap,
          ),

          AppStorysScratchCard(
            appStorys: widget.appStorys,
            onLinkTap: widget.onLinkTap,
          ),

          AppStorysSpinWheel(
            appStorys: widget.appStorys,
            onLinkTap: widget.onLinkTap,
          ),

          widget.appStorys.captureScreenWidget(
            screenName: widget.screenName ?? '',
            screenContext: context,
          ),

        ],
      ),
    );
  }
}
