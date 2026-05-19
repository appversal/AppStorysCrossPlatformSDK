import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../appstorys_flutter.dart';
import '../utils/campaigns_stream_mixin.dart';
import '../utils/common_widgets.dart';
import '../utils/link_handler.dart';

/// PUBLIC widget
class AppStorysFloater extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onTap;
  /// Extra space below the floater — pass the host BottomNavigationBar height
  /// so the floater sits above it. Added on top of any backend-configured margin.
  final double bottomPadding;

  const AppStorysFloater({
    super.key,
    required this.appStorys,
    this.onTap,
    this.bottomPadding = 0,
  });

  @override
  State<AppStorysFloater> createState() => _AppStorysFloaterState();
}

/// STATE (logic)
class _AppStorysFloaterState extends State<AppStorysFloater>
    with CampaignsStreamMixin {
  FloaterCampaign? _floater;
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    subscribeToCampaigns(
      widget.appStorys.campaignsStream,
      _handleCampaigns,
    );
  }

  void _handleCampaigns(String json) {
    final floater = _parseFloater(json);

    if (!mounted) return;

    final isNewCampaign = floater?.id != _floater?.id;

    setState(() {
      _floater = floater;
      if (isNewCampaign) _visible = floater != null;
    });

    if (isNewCampaign) _trackView(floater);
  }

  // ── Parsing ─────────────────────────────────────────────

  FloaterCampaign? _parseFloater(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;

      final raw = data
          .whereType<Map>()
          .firstWhere(
            (c) => c['campaign_type'] == 'FLT',
        orElse: () => {},
      );

      if (raw.isEmpty) return null;

      return FloaterCampaign.fromJson(_normalize(raw));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalize(Map raw) {
    final details = Map<String, dynamic>.from(raw['details'] ?? {});

    return {
      ...details,
      'id': (raw['id'] ?? details['id'])?.toString() ?? '',
    };
  }

  // ── Tracking ────────────────────────────────────────────

  void _trackView(FloaterCampaign? f) {
    if (f?.id.isEmpty ?? true) return;

    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: f!.id)
        .catchError((_) {});
  }

  void _onTap() {
    final f = _floater;
    if (f == null) return;

    widget.appStorys
        .trackEvent(event: 'clicked', campaignId: f.id)
        .catchError((_) {});

    final link = f.link;
    if (link?.isNotEmpty == true) {
      LinkHandler.handle(link, widget.onTap);
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  BorderRadius _borderRadius() {
    final s = _floater?.styling;

    return BorderRadius.only(
      topLeft: Radius.circular(s?.topLeftRadius ?? 0),
      topRight: Radius.circular(s?.topRightRadius ?? 0),
      bottomLeft: Radius.circular(s?.bottomLeftRadius ?? 0),
      bottomRight: Radius.circular(s?.bottomRightRadius ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = _floater;

    if (!_visible || f == null) {
      return const SizedBox.shrink();
    }

    return _FloaterView(
      floater: f,
      borderRadius: _borderRadius(),
      bottomPadding: widget.bottomPadding,
      onTap: _onTap,
    );
  }
}

/// UI LAYER (clean separation)
class _FloaterView extends StatelessWidget {
  final FloaterCampaign floater;
  final BorderRadius borderRadius;
  final double bottomPadding;
  final VoidCallback onTap;

  const _FloaterView({
    required this.floater,
    required this.borderRadius,
    required this.bottomPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = floater.styling;

    final width = floater.width ?? 60.0;
    final height = floater.height ?? 60.0;
    final isLeft = (floater.position?.toLowerCase() ?? 'left') == 'left';

    return Align(
      alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: (s?.marginBottom ?? 0) + bottomPadding,
          left: isLeft ? (s?.marginLeft ?? 0) : 0,
          right: isLeft ? 0 : (s?.marginRight ?? 0),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(
              width: width,
              height: height,
              child: _MediaView(floater: floater),
            ),
          ),
        ),
      ),
    );
  }
}

/// MEDIA RENDERING (separate responsibility)
class _MediaView extends StatelessWidget {
  final FloaterCampaign floater;

  const _MediaView({required this.floater});

  @override
  Widget build(BuildContext context) {
    if (isLottieUrl(floater.lottieData)) {
      return Lottie.network(
        floater.lottieData!,
        fit: BoxFit.cover,
        repeat: true,
        errorBuilder: (_, _, _) => Container(color: Colors.grey[200]),
      );
    }

    if (floater.image?.isNotEmpty == true) {
      return Image.network(
        floater.image!,
        fit: isGifUrl(floater.image) ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: Colors.grey[200]),
      );
    }

    return Container(color: Colors.grey[200]);
  }
}