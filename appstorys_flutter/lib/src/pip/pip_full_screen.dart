import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../models/pip_models.dart';
import 'pip_video_player.dart';

class PipFullScreen extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final String videoUrl;
  final PipCampaign campaign;
  final void Function(bool showPip) onClose;
  final VoidCallback onMinimize;
  final void Function(String link)? onLinkTap;

  const PipFullScreen({
    super.key,
    required this.appStorys,
    required this.videoUrl,
    required this.campaign,
    required this.onClose,
    required this.onMinimize,
    this.onLinkTap,
  });

  @override
  State<PipFullScreen> createState() => _PipFullScreenState();
}

class _PipFullScreenState extends State<PipFullScreen> {
  late bool _muted;

  @override
  void initState() {
    super.initState();

    // defaultSound: "no" = muted
    _muted = widget.campaign.styling?.defaultSound == 'no';

    _trackView();
  }

  void _trackView() {
    if (widget.campaign.id.isEmpty) return;

    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: widget.campaign.id)
        .catchError((_) {});
  }

  void _onCtaTap() {
    final link = widget.campaign.link;

    if (link?.isEmpty ?? true) return;

    widget.appStorys
        .trackEvent(event: 'clicked', campaignId: widget.campaign.id)
        .catchError((_) {});

    widget.onLinkTap?.call(link!);
  }

  void _onClose() {
    Navigator.pop(context);
    widget.onClose(false);
  }

  void _onMinimize() {
    widget.onMinimize();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// VIDEO
          Positioned.fill(
            child: PipVideoPlayer(
              videoUrl: widget.videoUrl,
              mute: _muted,
            ),
          ),

          /// TOP LEFT (minimize)
          Positioned(
            top: 12,
            left: 12,
            child: _IconButton(
              icon: Icons.picture_in_picture_alt,
              onTap: _onMinimize,
            ),
          ),

          /// TOP RIGHT (sound + close)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _IconButton(
                  icon: _muted ? Icons.volume_off : Icons.volume_up,
                  onTap: () => setState(() => _muted = !_muted),
                ),
                const SizedBox(width: 8),
                _IconButton(
                  icon: Icons.close,
                  onTap: _onClose,
                ),
              ],
            ),
          ),

          /// CTA BUTTON
          if (campaign.buttonText?.isNotEmpty == true)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _CtaButton(
                text: campaign.buttonText!,
                onTap: _onCtaTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// REUSABLE ICON BUTTON
/// ─────────────────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// CTA BUTTON
/// ─────────────────────────────────────────────────────────
class _CtaButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _CtaButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}