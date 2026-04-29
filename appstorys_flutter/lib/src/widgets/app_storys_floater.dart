import 'dart:convert';
import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../models/floater_models.dart';
import '../utils/campaigns_stream_mixin.dart';
import '../utils/common_widgets.dart' show isGifUrl, isLottieUrl;

class AppStorysFloater extends StatefulWidget {
  final AppstorysFlutter appStorys;
  /// Called with the campaign link when the floater is tapped.
  /// Navigation is the host app's responsibility.
  final void Function(String link)? onTap;

  const AppStorysFloater({super.key, required this.appStorys, this.onTap});

  @override
  State<AppStorysFloater> createState() => _AppStorysFloaterState();
}

class _AppStorysFloaterState extends State<AppStorysFloater>
    with CampaignsStreamMixin {
  FloaterCampaign? _floater;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(widget.appStorys.campaignsStream, _onCampaignsUpdate);
  }

  void _onCampaignsUpdate(String json) {
    final List<dynamic> all;
    try {
      all = jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return;
    }

    final fltCampaigns = all
        .whereType<Map>()
        .where((c) => c['campaign_type'] == 'FLT')
        .toList();

    if (fltCampaigns.isEmpty) {
      if (mounted) setState(() { _floater = null; _visible = false; });
      return;
    }

    final raw = Map<String, dynamic>.from(fltCampaigns.first as Map);
    final details = raw['details'] is Map
        ? Map<String, dynamic>.from(raw['details'] as Map)
        : <String, dynamic>{};

    final normalized = <String, dynamic>{
      ...details,
      'id': (raw['id'] ?? details['id'])?.toString() ?? '',
    };

    final floater = FloaterCampaign.fromJson(normalized);

    if (mounted) setState(() { _floater = floater; _visible = true; });

    if (floater.id.isNotEmpty) {
      widget.appStorys
          .trackEvent(event: 'viewed', campaignId: floater.id)
          .catchError((Object _) => null);
    }
  }

  BorderRadius _borderRadius() {
    final s = _floater!.styling;
    return BorderRadius.only(
      topLeft: Radius.circular(s?.topLeftRadius ?? 0),
      topRight: Radius.circular(s?.topRightRadius ?? 0),
      bottomLeft: Radius.circular(s?.bottomLeftRadius ?? 0),
      bottomRight: Radius.circular(s?.bottomRightRadius ?? 0),
    );
  }

  void _onTap() {
    widget.appStorys
        .trackEvent(event: 'clicked', campaignId: _floater!.id)
        .catchError((Object _) => null);
    final link = _floater!.link;
    if (link != null && link.isNotEmpty && widget.onTap != null) {
      widget.onTap!(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _floater == null) return const SizedBox.shrink();

    final f = _floater!;
    final s = f.styling;
    final w = f.width ?? 60.0;
    final h = f.height ?? 60.0;
    final isLeft = (f.position?.toLowerCase() ?? 'left') == 'left';
    final br = _borderRadius();

    return Align(
      alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: s?.marginBottom ?? 0,
          left: isLeft ? (s?.marginLeft ?? 0) : 0,
          right: isLeft ? 0 : (s?.marginRight ?? 0),
        ),
        child: GestureDetector(
          onTap: _onTap,
          child: ClipRRect(
            borderRadius: br,
            child: SizedBox(
              width: w,
              height: h,
              child: _buildMedia(f, br),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(FloaterCampaign f, BorderRadius br) {
    if (isLottieUrl(f.lottieData)) {
      // Lottie placeholder — add lottie package when ready.
      return Container(color: Colors.grey[200]);
    }
    if (f.image?.isNotEmpty == true) {
      return Image.network(
        f.image!,
        fit: isGifUrl(f.image) ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
      );
    }
    return Container(color: Colors.grey[200]);
  }
}
