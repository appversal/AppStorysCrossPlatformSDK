import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../utils/campaigns_stream_mixin.dart';
import '../common/cta_button.dart';
import '../utils/link_handler.dart';

// ── KMP entry widget ──────────────────────────────────────────────────────────

class AppStorysSpinWheel extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;

  const AppStorysSpinWheel({
    super.key,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<AppStorysSpinWheel> createState() => _AppStorysSpinWheelState();
}

class _AppStorysSpinWheelState extends State<AppStorysSpinWheel>
    with CampaignsStreamMixin {
  bool _showing = false;
  String? _currentCampaignId;

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(widget.appStorys.campaignsStream, _onCampaigns);
  }

  void _onCampaigns(String json) {
    if (_showing) return;
    final campaigns = _parseCampaigns(json);
    final stw = campaigns.firstWhere(
      (c) => c['campaign_type'] == 'STW',
      orElse: () => {},
    );
    if (stw.isEmpty) return;

    final raw = stw['details'];
    final detailsMap =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final campaignId =
        (stw['campaign_id'] ?? stw['id'] ?? '').toString();

    // Same campaign was already shown and closed — don't re-show.
    // Matches Kotlin's remember(campaign?.id) { mutableStateOf(true) } scoping.
    if (campaignId == _currentCampaignId) return;

    final rawSlices = stw['slices'];
    if (rawSlices is List) {
      detailsMap['slices'] = rawSlices;
    }

    SpinWheelDetails details;
    try {
      details = SpinWheelDetails.fromJson(detailsMap, fallbackId: campaignId);
    } catch (_) {
      return;
    }

    if (details.slices.isEmpty) return;

    _currentCampaignId = campaignId;
    _showing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      widget.appStorys.trackEvent(event: 'viewed', campaignId: campaignId);
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (_) => _SpinWheelDialog(
          details: details,
          campaignId: campaignId,
          appStorys: widget.appStorys,
          onLinkTap: widget.onLinkTap,
        ),
      );
      if (mounted) {
        _showing = false;
        // Keep _currentCampaignId so the same campaign does not re-show
        // until a new campaign ID arrives — matches Kotlin's remember(campaign?.id).
      }
    });
  }

  List<Map<String, Object?>> _parseCampaigns(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry('$k', v)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Full-screen dialog ────────────────────────────────────────────────────────

class _SpinWheelDialog extends StatefulWidget {
  final SpinWheelDetails details;
  final String campaignId;
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;

  const _SpinWheelDialog({
    required this.details,
    required this.campaignId,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<_SpinWheelDialog> createState() => _SpinWheelDialogState();
}

class _SpinWheelDialogState extends State<_SpinWheelDialog>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _appearController;
  late AnimationController _confettiController;

  late Animation<double> _spinAnimation;
  late Animation<double> _appearAnimation;

  bool _isSpinning = false;
  bool _showReward = false;
  bool _showCopied = false;
  bool _isPlayingConfetti = false;

  double _currentRotation = 0;
  SpinWheelSlice? _selectedSlice;
  int _spinsRemaining = 0;

  final Map<String, ui.Image?> _sliceImages = {};
  final List<_ConfettiParticle> _particles = [];
  DateTime? _lastConfettiTick;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _spinsRemaining = widget.details.availableSpins;

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..addListener(_onConfettiTick);

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    );
    _appearAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOut,
    );

    _appearController.forward();
    _preloadSliceImages();
  }

  void _preloadSliceImages() {
    for (final slice in widget.details.slices) {
      if (slice.sliceMedia.isNotEmpty) {
        _loadImage(slice.id, slice.sliceMedia);
      }
    }
  }

  void _loadImage(String sliceId, String url) {
    final imageProvider = NetworkImage(url);
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() => _sliceImages[sliceId] = info.image);
      }
    }, onError: (_, _) {}));
  }

  @override
  void dispose() {
    _spinController.dispose();
    _appearController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ── Dismiss ──────────────────────────────────────────────────────────────────

  void _handleDismiss() {
    if (_showReward && _spinsRemaining > 0) {
      setState(() {
        _showReward = false;
        _isPlayingConfetti = false;
        _particles.clear();
        _confettiController.stop();
        _confettiController.reset();
      });
      return;
    }
    _appearController.reverse().then((_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  // ── Spin logic ───────────────────────────────────────────────────────────────

  SpinWheelSlice _pickSlice() {
    final slices = widget.details.slices;
    final totalWeight = slices.fold<int>(0, (s, sl) => s + sl.weight);
    int roll = _rng.nextInt(totalWeight == 0 ? 1 : totalWeight);
    for (final sl in slices) {
      roll -= sl.weight;
      if (roll < 0) return sl;
    }
    return slices.last;
  }

  Future<void> _onSpin() async {
    if (_isSpinning || _spinsRemaining <= 0) return;
    final selected = _pickSlice();
    final sliceCount = widget.details.slices.length;
    final sliceIndex = widget.details.slices.indexOf(selected);
    final sliceAngle = (2 * pi) / sliceCount;
    // angle to land pointer (top = 0, pointer is at top)
    final targetAngle = sliceAngle * sliceIndex + sliceAngle / 2;
    final extraRotations = 5 * 2 * pi;
    final totalRotation = extraRotations + (2 * pi - targetAngle);

    _spinController.reset();
    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + totalRotation,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.decelerate,
    ));

    setState(() {
      _isSpinning = true;
      _selectedSlice = selected;
    });

    if (widget.details.hapticFeedback) HapticFeedback.mediumImpact();

    await _spinController.forward();

    _currentRotation = _spinAnimation.value % (2 * pi);
    _spinsRemaining--;

    widget.appStorys.trackEvent(
      event: 'spun',
      campaignId: widget.campaignId,
      metadata: {'sliceId': selected.id, 'noPrize': selected.noPrize},
    );

    if (widget.details.hapticFeedback) HapticFeedback.heavyImpact();

    setState(() {
      _isSpinning = false;
      _showReward = true;
    });

    if (!selected.noPrize) {
      _startConfetti();
    }
  }

  // ── Confetti ─────────────────────────────────────────────────────────────────

  void _startConfetti() {
    _particles.clear();
    _isPlayingConfetti = true;
    _lastConfettiTick = DateTime.now();
    _confettiController.reset();
    _confettiController.forward();
  }

  void _onConfettiTick() {
    if (!_isPlayingConfetti || !mounted) return;
    final now = DateTime.now();
    final dt = _lastConfettiTick != null
        ? now.difference(_lastConfettiTick!).inMilliseconds / 1000.0
        : 0.016;
    _lastConfettiTick = now;

    final size = MediaQuery.of(context).size;
    const colors = [
      Colors.red, Colors.orange, Colors.yellow,
      Colors.green, Colors.blue, Colors.purple, Colors.pink,
    ];

    // spawn particles in first 2 seconds
    if (_confettiController.value < 0.5) {
      for (int i = 0; i < 3; i++) {
        _particles.add(_ConfettiParticle(
          position: Offset(
            _rng.nextDouble() * size.width,
            -20,
          ),
          velocity: Offset(
            (_rng.nextDouble() - 0.5) * 200,
            _rng.nextDouble() * 300 + 100,
          ),
          color: colors[_rng.nextInt(colors.length)],
          size: _rng.nextDouble() * 8 + 4,
          rotation: _rng.nextDouble() * 2 * pi,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 10,
          lifespan: _rng.nextDouble() * 2 + 1,
        ));
      }
    }

    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);

    if (_confettiController.isCompleted) {
      _isPlayingConfetti = false;
    }

    if (mounted) setState(() {});
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _hex(String? hex, [Color fallback = Colors.white]) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      String h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return fallback;
  }

  double _d(Map<String, dynamic> map, String key, [double def = 0.0]) {
    final v = map[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  String _s(Map<String, dynamic> map, String key, [String def = '']) {
    final v = map[key];
    return v?.toString() ?? def;
  }

  Map<String, dynamic> _m(Map<String, dynamic> map, String key) {
    final v = map[key];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  FontWeight _fw(Map<String, dynamic> ts) {
    final dec = ts['fontDecoration'];
    if (dec is List && dec.contains('bold')) return FontWeight.bold;
    return FontWeight.normal;
  }

  FontStyle _fi(Map<String, dynamic> ts) {
    final dec = ts['fontDecoration'];
    if (dec is List && dec.contains('italic')) return FontStyle.italic;
    return FontStyle.normal;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final backdrop = _hex(
      _showReward
          ? widget.details.rewardBackdropColor
          : widget.details.backdropColor,
      Colors.black,
    );
    final opacity = _showReward
        ? 1.0
        : (widget.details.backdropOpacity / 100.0).clamp(0.0, 1.0);

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _showReward ? null : _handleDismiss,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: backdrop.withValues(alpha: opacity),
              ),
            ),
          ),

          // confetti layer
          if (_isPlayingConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(_particles),
                ),
              ),
            ),

          // content
          FadeTransition(
            opacity: _appearAnimation,
            child: ScaleTransition(
              scale: _appearAnimation,
              child: _showReward ? _buildRewardScreen() : _buildWheelScreen(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wheel screen ──────────────────────────────────────────────────────────────

  Widget _buildWheelScreen() {
    final d = widget.details;
    final vtc = d.titleTextStyle;
    final sub = d.subtitleTextStyle;
    final spinsTs = d.spinsTextStyle;
    final spinBtn = d.spinButton;

    final titleColor = _hex(_s(vtc, 'color'), Colors.white);
    final titleSize = _d(vtc, 'fontSize', 22);
    final titleFamily = _s(vtc, 'fontFamily');

    final subColor = _hex(_s(sub, 'color'), Colors.white70);
    final subSize = _d(sub, 'fontSize', 14);
    final subFamily = _s(sub, 'fontFamily');

    final spinsColor = _hex(_s(spinsTs, 'color'), Colors.white);
    final spinsSize = _d(spinsTs, 'fontSize', 13);

    // spin button
    final btnContainer = _m(spinBtn, 'container');
    final btnTextMap = _m(spinBtn, 'text');
    final btnText = _s(spinBtn, 'text', d.spinButtonText);
    final btnBg = _s(btnContainer, 'backgroundColor', '#2563EB');
    final btnBorder = _s(btnContainer, 'borderColor', '#2563EB');
    final btnBorderW = _d(btnContainer, 'borderWidth', 0);
    final btnTextColor = _s(btnTextMap, 'color', '#FFFFFF');
    final btnFontSize = _d(btnTextMap, 'fontSize', 16);
    final btnCr = _m(btnContainer, 'cornerRadius');
    final btnMargin = _m(spinBtn, 'margin');

    // cross button
    final crossMap = d.stwCrossButton;

    final canSpin = !_isSpinning && _spinsRemaining > 0;

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  d.popupTitle,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: titleSize,
                    fontFamily: titleFamily.isEmpty ? null : titleFamily,
                    fontWeight: _fw(vtc),
                    fontStyle: _fi(vtc),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (d.popupDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    d.popupDescription,
                    style: TextStyle(
                      color: subColor,
                      fontSize: subSize,
                      fontFamily: subFamily.isEmpty ? null : subFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '$_spinsRemaining ${d.availableSpinsText}',
                  style: TextStyle(
                    color: spinsColor,
                    fontSize: spinsSize,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // wheel + pointer
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: AnimatedBuilder(
                  animation: _spinAnimation,
                  builder: (_, _) => Transform.rotate(
                    angle: _spinAnimation.value,
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: _WheelPainter(
                        slices: widget.details.slices,
                        sliceImages: _sliceImages,
                        spinDirection: d.spinDirection,
                        wheelConfig: d.wheelConfig,
                      ),
                    ),
                  ),
                ),
              ),
              // pointer
              CustomPaint(
                size: const Size(40, 30),
                painter: _PointerPainter(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // spin button
          Padding(
            padding: EdgeInsets.fromLTRB(
              _d(btnMargin, 'left', 32),
              _d(btnMargin, 'top'),
              _d(btnMargin, 'right', 32),
              _d(btnMargin, 'bottom'),
            ),
            child: CtaButton(
              onTap: canSpin ? () { _onSpin(); } : () {},
              text: canSpin ? btnText : (_isSpinning ? 'Spinning…' : 'No spins left'),
              backgroundColor: _hex(btnBg, const Color(0xFF2563EB)),
              borderColor: _hex(btnBorder, const Color(0xFF2563EB)),
              borderWidth: btnBorderW,
              textColor: _hex(btnTextColor, Colors.white),
              fontSize: btnFontSize,
              fullWidth: true,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_d(btnCr, 'topLeft', 12)),
                topRight: Radius.circular(_d(btnCr, 'topRight', 12)),
                bottomLeft: Radius.circular(_d(btnCr, 'bottomLeft', 12)),
                bottomRight: Radius.circular(_d(btnCr, 'bottomRight', 12)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // cross / close
          CrossButton(
            onTap: _isSpinning ? () {} : _handleDismiss,
            styling: crossMap.isNotEmpty ? crossMap : null,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Reward screen ─────────────────────────────────────────────────────────────

  Widget _buildRewardScreen() {
    final slice = _selectedSlice;
    if (slice == null) return const SizedBox.shrink();
    return slice.noPrize || slice.reward == null
        ? _buildNoPrizeCard(slice)
        : _buildPrizeCard(slice, slice.reward!);
  }

  Widget _buildNoPrizeCard(SpinWheelSlice slice) {
    final d = widget.details;
    final rwCross = d.rewardCrossButton;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              slice.prizeLabel.isNotEmpty ? slice.prizeLabel : 'Better luck next time!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_spinsRemaining > 0) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleDismiss,
                child: Text('Spin again ($_spinsRemaining left)'),
              ),
            ] else ...[
              const SizedBox(height: 24),
              CrossButton(
                onTap: _handleDismiss,
                styling: rwCross.isNotEmpty ? rwCross : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeCard(SpinWheelSlice slice, SpinWheelReward reward) {
    final d = widget.details;
    final rwCross = d.rewardCrossButton;

    final titleTs = reward.priceLabelTextStyle;
    final subTs = reward.subtitleTextStyle;
    final ctaStyling = reward.ctaStyling;
    final couponStyling = reward.couponStyling;

    final titleColor = _hex(_s(titleTs, 'color'), Colors.black);
    final titleSize = _d(titleTs, 'fontSize', 20);
    final titleFamily = _s(titleTs, 'fontFamily');
    final titleMargin = _m(titleTs, 'margin');

    final subColor = _hex(_s(subTs, 'color'), Colors.grey);
    final subSize = _d(subTs, 'fontSize', 14);
    final subFamily = _s(subTs, 'fontFamily');
    final subMargin = _m(subTs, 'margin');

    // CTA styling
    final ctaContainer = _m(ctaStyling, 'container');
    final ctaTextMap = _m(ctaStyling, 'text');
    final ctaCr = _m(ctaContainer, 'cornerRadius');
    final ctaMargin = _m(ctaStyling, 'margin');

    // Coupon styling
    final couponContainer = _m(couponStyling, 'container');
    final couponTextMap = _m(couponStyling, 'text');
    final couponCr = _m(couponContainer, 'cornerRadius');
    final couponMargin = _m(couponStyling, 'margin');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // close
              Align(
                alignment: Alignment.topRight,
                child: CrossButton(
                  onTap: _handleDismiss,
                  styling: rwCross.isNotEmpty ? rwCross : null,
                ),
              ),

              // reward image
              if (reward.sliceRewardMedia.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    reward.sliceRewardMedia,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // prize name
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _d(titleMargin, 'left'),
                  _d(titleMargin, 'top', 8),
                  _d(titleMargin, 'right'),
                  _d(titleMargin, 'bottom', 4),
                ),
                child: Text(
                  reward.prizeName,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: titleSize,
                    fontFamily: titleFamily.isEmpty ? null : titleFamily,
                    fontWeight: _fw(titleTs),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // sub text
              if (reward.subText.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _d(subMargin, 'left'),
                    _d(subMargin, 'top', 4),
                    _d(subMargin, 'right'),
                    _d(subMargin, 'bottom', 12),
                  ),
                  child: Text(
                    reward.subText,
                    style: TextStyle(
                      color: subColor,
                      fontSize: subSize,
                      fontFamily: subFamily.isEmpty ? null : subFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // coupon code
              if (reward.couponCode.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _d(couponMargin, 'left', 0),
                    _d(couponMargin, 'top', 8),
                    _d(couponMargin, 'right', 0),
                    _d(couponMargin, 'bottom', 8),
                  ),
                  child: GestureDetector(
                    onTap: _onCopyCoupon,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _hex(
                            _s(couponContainer, 'backgroundColor', '#FFF7ED'),
                            const Color(0xFFFFF7ED)),
                        border: Border.all(
                          color: _hex(
                              _s(couponContainer, 'borderColor', '#fd5f03'),
                              Colors.orange),
                          width: _d(couponContainer, 'borderWidth', 2),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              _d(couponCr, 'topLeft', 8)),
                          topRight: Radius.circular(
                              _d(couponCr, 'topRight', 8)),
                          bottomLeft: Radius.circular(
                              _d(couponCr, 'bottomLeft', 8)),
                          bottomRight: Radius.circular(
                              _d(couponCr, 'bottomRight', 8)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reward.couponCode,
                            style: TextStyle(
                              color: _hex(_s(couponTextMap, 'color'),
                                  Colors.black),
                              fontSize: _d(couponTextMap, 'fontSize', 14),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _showCopied
                                ? const Icon(Icons.check,
                                    color: Colors.green, size: 18)
                                : const Icon(Icons.copy,
                                    color: Colors.grey, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // CTA
              CtaButton(
                onTap: reward.link.isNotEmpty
                    ? () => LinkHandler.handle(reward.link, widget.onLinkTap)
                    : _handleDismiss,
                text: reward.buttonCta,
                backgroundColor: _hex(
                    _s(ctaContainer, 'backgroundColor', '#2563EB'),
                    const Color(0xFF2563EB)),
                borderColor: _hex(
                    _s(ctaContainer, 'borderColor', '#2563EB'),
                    const Color(0xFF2563EB)),
                borderWidth: _d(ctaContainer, 'borderWidth', 0),
                textColor: _hex(_s(ctaTextMap, 'color', '#FFFFFF'), Colors.white),
                fontSize: _d(ctaTextMap, 'fontSize', 16),
                fullWidth: ctaContainer['ctaFullWidth'] == true,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_d(ctaCr, 'topLeft', 12)),
                  topRight: Radius.circular(_d(ctaCr, 'topRight', 12)),
                  bottomLeft: Radius.circular(_d(ctaCr, 'bottomLeft', 12)),
                  bottomRight: Radius.circular(_d(ctaCr, 'bottomRight', 12)),
                ),
                margin: EdgeInsets.fromLTRB(
                  _d(ctaMargin, 'left', 0),
                  _d(ctaMargin, 'top', 0),
                  _d(ctaMargin, 'right', 0),
                  _d(ctaMargin, 'bottom', 0),
                ),
              ),

              // T&C
              if (reward.termsNConditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => LinkHandler.handle(reward.termsNConditions, widget.onLinkTap),
                  child: Text(
                    reward.tNcCta,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onCopyCoupon() {
    final code = _selectedSlice?.reward?.couponCode ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    setState(() => _showCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }
}

// ── Confetti particle ─────────────────────────────────────────────────────────

class _ConfettiParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  double lifespan;
  double age = 0;

  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifespan,
  });

  void update(double dt) {
    age += dt;
    position += velocity * dt;
    rotation += rotationSpeed * dt;
    velocity = Offset(velocity.dx, velocity.dy + 200 * dt);
  }

  double get opacity => (1.0 - age / lifespan).clamp(0.0, 1.0);
  bool get isDead => age >= lifespan;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Wheel painter ─────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<SpinWheelSlice> slices;
  final Map<String, ui.Image?> sliceImages;
  final String spinDirection;
  final Map<String, dynamic> wheelConfig;

  _WheelPainter({
    required this.slices,
    required this.sliceImages,
    required this.spinDirection,
    required this.wheelConfig,
  });

  Color _hex(String? h, [Color def = Colors.white]) {
    if (h == null || h.isEmpty) return def;
    try {
      String s = h.replaceAll('#', '');
      if (s.length == 6) s = 'FF$s';
      if (s.length == 8) return Color(int.parse(s, radix: 16));
    } catch (_) {}
    return def;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * pi / slices.length;

    // border from wheelConfig
    final borderColor = wheelConfig['borderColor'];
    final borderWidth =
        (wheelConfig['borderWidth'] is num)
            ? (wheelConfig['borderWidth'] as num).toDouble()
            : 2.0;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final startAngle = sliceAngle * i - pi / 2;
      final endAngle = startAngle + sliceAngle;

      // fill
      final paint = Paint()
        ..color = _hex(slice.bgColor, Colors.blue)
        ..style = PaintingStyle.fill;

      final path = _buildSlicePath(center, radius, startAngle, endAngle,
          slice.cornerRadiusTopLeft, slice.cornerRadiusTopRight,
          slice.cornerRadiusBottomLeft, slice.cornerRadiusBottomRight);

      canvas.drawPath(path, paint);

      // stroke
      if (slice.strokeWidth > 0) {
        final strokePaint = Paint()
          ..color = _hex(slice.strokeColor, Colors.white)
          ..style = PaintingStyle.stroke
          ..strokeWidth = slice.strokeWidth;
        canvas.drawPath(path, strokePaint);
      }

      // label text
      _drawLabel(canvas, center, radius, startAngle, sliceAngle, slice);

      // image
      final img = sliceImages[slice.id];
      if (img != null) {
        _drawSliceImage(
            canvas, center, radius, startAngle, sliceAngle, img, slice);
      }
    }

    // outer border
    if (borderColor != null) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _hex(borderColor.toString(), Colors.white)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }

  Path _buildSlicePath(
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    double crTopLeft,
    double crTopRight,
    double crBotLeft,
    double crBotRight,
  ) {
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(
      center.dx + radius * cos(startAngle),
      center.dy + radius * sin(startAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      endAngle - startAngle,
      false,
    );
    path.close();
    return path;
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sliceAngle,
    SpinWheelSlice slice,
  ) {
    if (slice.prizeLabel.isEmpty) return;

    final midAngle = startAngle + sliceAngle / 2;
    final labelRadius = radius * 0.6;
    final labelCenter = Offset(
      center.dx + labelRadius * cos(midAngle),
      center.dy + labelRadius * sin(midAngle),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: slice.prizeLabel,
        style: TextStyle(
          color: _hex(slice.labelColor, Colors.white),
          fontSize: slice.labelFontSize.clamp(8, 18),
          fontFamily:
              slice.labelFontFamily.isEmpty ? null : slice.labelFontFamily,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: radius * 0.5);

    canvas.save();
    canvas.translate(labelCenter.dx, labelCenter.dy);
    canvas.rotate(midAngle + pi / 2);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawSliceImage(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sliceAngle,
    ui.Image img,
    SpinWheelSlice slice,
  ) {
    final midAngle = startAngle + sliceAngle / 2;
    final imgRadius = radius * 0.35;
    final imgCenter = Offset(
      center.dx + imgRadius * cos(midAngle),
      center.dy + imgRadius * sin(midAngle),
    );
    const imgSize = 28.0;

    canvas.save();
    canvas.translate(imgCenter.dx, imgCenter.dy);
    canvas.rotate(midAngle + slice.imageRotation * pi / 180 + pi / 2);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: imgSize, height: imgSize),
      Paint(),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.slices != slices || old.sliceImages != sliceImages;
}

// ── Pointer painter ───────────────────────────────────────────────────────────

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF4081)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
