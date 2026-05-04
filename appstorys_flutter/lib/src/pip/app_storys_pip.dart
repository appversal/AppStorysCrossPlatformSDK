import 'dart:convert';
import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../models/pip_models.dart';
import '../utils/campaigns_stream_mixin.dart';
import 'pip_full_screen.dart';
import 'pip_video_player.dart';

class AppStorysPip extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;
  /// Extra space to keep below the PiP window — pass the host BottomNavigationBar
  /// height here so the widget never overlaps it.
  /// Added on top of any `pipBottomPadding` configured in the campaign JSON.
  final double bottomPadding;
  /// Extra space to keep above the PiP window (e.g. an app bar height).
  /// Added on top of any `pipTopPadding` configured in the campaign JSON.
  final double topPadding;

  const AppStorysPip({
    super.key,
    required this.appStorys,
    this.onLinkTap,
    this.bottomPadding = 0,
    this.topPadding = 0,
  });

  @override
  State<AppStorysPip> createState() => _AppStorysPipState();
}

class _AppStorysPipState extends State<AppStorysPip>
    with CampaignsStreamMixin, SingleTickerProviderStateMixin {
  PipCampaign? _pip;

  bool _visible = true;
  bool _playing = true;
  bool _muted = false;

  Offset _position = Offset.zero;
  bool _dragging = false;

  late AnimationController _snapController;
  Animation<Offset>? _snapAnim;

  @override
  void initState() {
    super.initState();

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_onSnapTick);

    subscribeToCampaigns(
      widget.appStorys.campaignsStream,
      _handleCampaigns,
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _handleCampaigns(String json) {
    final pip = _parse(json);
    if (!mounted) return;

    final isNewCampaign = pip?.id != _pip?.id;

    setState(() {
      _pip = pip;
      // Only reset visibility for a new campaign — preserves user's close action
      // when stream re-emits same campaign (e.g. isTestUser resolves).
      if (isNewCampaign) _visible = pip != null;
      _playing = true;
      _muted = pip?.styling?.defaultSound == 'no';
    });

    _initPosition();
    if (isNewCampaign) _trackView(pip);
  }

  PipCampaign? _parse(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;

      final raw = list
          .whereType<Map>()
          .firstWhere(
            (c) => c['campaign_type'] == 'PIP',
        orElse: () => {},
      );

      if (raw.isEmpty) return null;

      final details = Map<String, dynamic>.from(raw['details'] ?? {});

      return PipCampaign.fromJson({
        ...details,
        'id': (raw['id'] ?? details['id'])?.toString() ?? '',
      });
    } catch (_) {
      return null;
    }
  }

  void _initPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pip == null) return;

      final screen = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      const gap = 12.0;

      // Combine host-provided padding with any backend-configured padding —
      // mirrors Kotlin: pipStyling?.pipBottomPadding?.dp?.plus(bottomPadding)
      final totalBottom = widget.bottomPadding + (_pip!.styling?.pipBottomPadding ?? 0);
      final totalTop = widget.topPadding + (_pip!.styling?.pipTopPadding ?? 0);

      final isLeft = _pip!.position.toLowerCase() == 'left';

      setState(() {
        _position = Offset(
          isLeft
              ? padding.left + gap
              : screen.width - _pip!.width - padding.right - gap,
          screen.height - _pip!.height - padding.bottom - totalBottom - gap,
        );
      });
    });
  }

  void _trackView(PipCampaign? pip) {
    if (pip?.id.isEmpty ?? true) return;

    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: pip!.id)
        .catchError((_) {});
  }

  void _onSnapTick() {
    if (_snapAnim == null || !mounted) return;
    setState(() => _position = _snapAnim!.value);
  }

  void _snapToEdge() {
    final screen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const gap = 12.0;

    final pip = _pip!;
    final centerX = _position.dx + pip.width / 2;

    final totalBottom = widget.bottomPadding + (pip.styling?.pipBottomPadding ?? 0);
    final totalTop = widget.topPadding + (pip.styling?.pipTopPadding ?? 0);

    final targetX = centerX < screen.width / 2
        ? padding.left + gap
        : screen.width - pip.width - padding.right - gap;

    final minY = padding.top + totalTop + gap;
    final maxY = screen.height - pip.height - padding.bottom - totalBottom - gap;

    final target = Offset(targetX, _position.dy.clamp(minY, maxY));

    _snapAnim = Tween<Offset>(
      begin: _position,
      end: target,
    ).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );

    _snapController.forward(from: 0);
  }

  void _onTap() {
    final pip = _pip!;
    final hasLarge = pip.largeVideoUrl?.isNotEmpty == true;

    if (!hasLarge) {
      if (pip.link?.isNotEmpty == true) {
        widget.appStorys
            .trackEvent(event: 'clicked', campaignId: pip.id)
            .catchError((_) {});
        widget.onLinkTap?.call(pip.link!);
      }
      return;
    }

    setState(() => _playing = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PipFullScreen(
          appStorys: widget.appStorys,
          videoUrl: pip.largeVideoUrl!,
          campaign: pip,
          onClose: (show) => setState(() => _visible = show),
          onMinimize: () => setState(() => _playing = true),
          onLinkTap: widget.onLinkTap,
        ),
      ),
    ).then((_) => setState(() => _playing = true));
  }

  @override
  Widget build(BuildContext context) {
    final pip = _pip;

    if (!_visible || pip == null || pip.smallVideoUrl?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: _PipView(
        pip: pip,
        isPlaying: _playing,
        muted: _muted,
        onTap: _onTap,
        onDrag: (delta) {
          setState(() {
            _dragging = true;
            _position += delta;
          });
        },
        onDragEnd: () {
          _dragging = false;
          _snapToEdge();
        },
        onMuteToggle: () => setState(() => _muted = !_muted),
        onClose: () => setState(() => _visible = false),
      ),
    );
  }
}

class _PipView extends StatelessWidget {
  final PipCampaign pip;
  final bool isPlaying;
  final bool muted;

  final VoidCallback onTap;
  final VoidCallback onDragEnd;
  final VoidCallback onMuteToggle;
  final VoidCallback onClose;
  final Function(Offset delta) onDrag;

  const _PipView({
    required this.pip,
    required this.isPlaying,
    required this.muted,
    required this.onTap,
    required this.onDrag,
    required this.onDragEnd,
    required this.onMuteToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => onDrag(d.delta),
      onPanEnd: (_) => onDragEnd(),
      onTap: onTap,
      child: Container(
        width: pip.width,
        height: pip.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PipVideoPlayer(
                videoUrl: pip.smallVideoUrl!,
                mute: muted,
                isPlaying: isPlaying,
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: _IconBtn(
                icon: muted ? Icons.volume_off : Icons.volume_up,
                onTap: onMuteToggle,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _IconBtn(
                icon: Icons.close,
                onTap: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }
}