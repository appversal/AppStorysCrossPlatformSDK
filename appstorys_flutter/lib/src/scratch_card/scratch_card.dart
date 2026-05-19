import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../utils/campaigns_stream_mixin.dart';
import '../common/cta_button.dart';
import '../utils/link_handler.dart';

// ── Type helpers ──────────────────────────────────────────────────────────────

class TypeHelper {
  static double toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  static FontWeight getFontWeight(List<dynamic>? decorations) {
    if (decorations == null) return FontWeight.normal;
    return decorations.contains('bold') ? FontWeight.bold : FontWeight.normal;
  }

  static FontStyle getFontStyle(List<dynamic>? decorations) {
    if (decorations == null) return FontStyle.normal;
    return decorations.contains('italic') ? FontStyle.italic : FontStyle.normal;
  }

  static TextDecoration getTextDecoration(List<dynamic>? decorations) {
    if (decorations == null) return TextDecoration.none;
    final result = <TextDecoration>[];
    if (decorations.contains('underline')) result.add(TextDecoration.underline);
    if (decorations.contains('lineThrough')) result.add(TextDecoration.lineThrough);
    if (result.isEmpty) return TextDecoration.none;
    return TextDecoration.combine(result);
  }
}

// ── KMP Entry Widget ──────────────────────────────────────────────────────────

class AppStorysScratchCard extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;

  const AppStorysScratchCard({
    super.key,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<AppStorysScratchCard> createState() => _AppStorysScratchCardState();
}

class _AppStorysScratchCardState extends State<AppStorysScratchCard>
    with CampaignsStreamMixin {
  bool _showing = false;
  String? _currentCampaignId;

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(widget.appStorys.campaignsStream, _handleCampaigns);
  }

  void _handleCampaigns(String json) {
    final campaign = _parseCampaign(json);
    if (campaign == null) return;
    if (campaign.id == _currentCampaignId || _showing) return;
    _currentCampaignId = campaign.id;

    final delay = campaign.details.appearance.displayDelay;
    final bdOpacity =
        (campaign.details.appearance.backdropOpacity / 100).clamp(0.0, 1.0);
    final bdColor =
        _hexToColor(campaign.details.appearance.backdropColor, Colors.black)
            .withValues(alpha: bdOpacity);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _showing) return;
      if (delay > 0) await Future.delayed(Duration(seconds: delay));
      if (!mounted || _showing) return;

      _showing = true;

      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: bdColor,
        builder: (_) => _ScratchCardDialog(
          campaign: campaign,
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

  ScratchCardCampaign? _parseCampaign(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return null;
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry('$k', v));
        if (map['campaign_type'] == 'SCRT') {
          return ScratchCardCampaign.fromJson(map);
        }
      }
    } catch (_) {}
    return null;
  }

  Color _hexToColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Dialog Widget ─────────────────────────────────────────────────────────────

class _ScratchCardDialog extends StatefulWidget {
  final ScratchCardCampaign campaign;
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;

  const _ScratchCardDialog({
    required this.campaign,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<_ScratchCardDialog> createState() => _ScratchCardDialogState();
}

class _ScratchCardDialogState extends State<_ScratchCardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  bool _isDismissing = false;
  bool _isRevealed = false;
  bool _showCopiedMessage = false;

  // static const String _prefKeyPrefix = 'appstorys_scratch_revealed_';

  ScratchCardDetails get _d => widget.campaign.details;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    // _restoreRevealedState();
    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: widget.campaign.id)
        .catchError((_) {});
  }

  // Future<void> _restoreRevealedState() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final key = '$_prefKeyPrefix${widget.campaign.id}';
  //   if (prefs.getBool(key) == true && mounted) {
  //     setState(() => _isRevealed = true);
  //   }
  // }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    await _animController.reverse();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  void _onReveal() {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);
    if (_d.haptics) HapticFeedback.mediumImpact();
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setBool('$_prefKeyPrefix${widget.campaign.id}', true);
    // });
    widget.appStorys
        .trackEvent(event: 'scratched', campaignId: widget.campaign.id)
        .catchError((_) {});
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (_d.haptics) HapticFeedback.selectionClick();
    setState(() => _showCopiedMessage = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopiedMessage = false);
    });
  }

  Color _hexToColor(String? hex, [Color fallback = Colors.white]) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  TextAlign _parseTextAlign(String? align) {
    switch (align?.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.center;
    }
  }

  bool _isLottieUrl(String? url) =>
      url != null && url.toLowerCase().endsWith('.json');

  void _showTermsSheet(String terms) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 20, bottom: 32),
            child: SingleChildScrollView(child: Text(terms)),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = _d.cardSize.width;
    final cardHeight = _d.cardSize.height;
    final cornerRadius = _d.cardSize.cornerRadius;
    final isOnlyImage = _d.rewardContent.onlyImage;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: FadeTransition(
          opacity: _opacityAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CrossButton(
                  onTap: _handleDismiss,
                  styling: _d.crossButton,
                ),
              ),

              if (_isRevealed)
                isOnlyImage
                    ? Stack(
                        children: [
                          SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(cornerRadius),
                              child: _isLottieUrl(_d.bannerImage)
                                  ? Lottie.network(
                                      _d.bannerImage!,
                                      width: cardWidth,
                                      height: cardHeight,
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: _d.bannerImage ?? '',
                                      width: cardWidth,
                                      height: cardHeight,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          if (_showCopiedMessage) _buildCopiedOverlay(),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Stack(
                          children: [
                            Container(
                              width: cardWidth,
                              decoration: BoxDecoration(
                                color: _hexToColor(
                                  _d.rewardContent.backgroundColor,
                                  const Color(0xFF141414),
                                ),
                                borderRadius:
                                    BorderRadius.circular(cornerRadius),
                              ),
                              child: _buildRewardContent(),
                            ),
                            if (_showCopiedMessage) _buildCopiedOverlay(),
                          ],
                        ),
                      )
              else
                _ScratchWidget(
                  width: cardWidth,
                  height: cardHeight,
                  cornerRadius: cornerRadius,
                  coverImageUrl: _d.overlayImage,
                  onReveal: _onReveal,
                ),

              if (_isRevealed) ...[
                const SizedBox(height: 12),
                _buildCTA(),
              ],

              if (_isRevealed &&
                  _d.termsAndConditions != null &&
                  _d.termsAndConditions!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () => _showTermsSheet(_d.termsAndConditions!),
                    child: const Text(
                      'Terms & Conditions*',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopiedOverlay() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Copied!',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardContent() {
    final rc = _d.rewardContent;
    final ic = rc.imageCircle;
    final imageSize = (ic?.width ?? 80.0).clamp(60.0, 150.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_d.bannerImage != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                ic?.marginLeft ?? 20,
                ic?.marginTop ?? 40,
                ic?.marginRight ?? 20,
                ic?.marginBottom ?? 20,
              ),
              child: SizedBox(
                height: imageSize,
                width: imageSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft:
                        Radius.circular(ic?.cornerRadiusTopLeft ?? 40),
                    topRight:
                        Radius.circular(ic?.cornerRadiusTopRight ?? 40),
                    bottomLeft:
                        Radius.circular(ic?.cornerRadiusBottomLeft ?? 40),
                    bottomRight:
                        Radius.circular(ic?.cornerRadiusBottomRight ?? 40),
                  ),
                  child: _isLottieUrl(_d.bannerImage)
                      ? Lottie.network(
                          _d.bannerImage!,
                          height: imageSize,
                          width: imageSize,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: _d.bannerImage!,
                          height: imageSize,
                          width: imageSize,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ],

          if (rc.offerTitle != null && rc.offerTitle!.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                rc.offerTitle!.marginLeft,
                rc.offerTitle!.marginTop,
                rc.offerTitle!.marginRight,
                rc.offerTitle!.marginBottom,
              ),
              child: Text(
                rc.offerTitle!.text,
                textAlign: _parseTextAlign(rc.offerTitle!.textAlign),
                style: TextStyle(
                  color: _hexToColor(rc.offerTitle!.color, Colors.white),
                  fontSize: rc.offerTitle!.fontSize,
                  fontFamily: rc.offerTitle!.fontFamily,
                  fontWeight:
                      TypeHelper.getFontWeight(rc.offerTitle!.fontDecoration),
                  fontStyle:
                      TypeHelper.getFontStyle(rc.offerTitle!.fontDecoration),
                  decoration: TypeHelper.getTextDecoration(
                      rc.offerTitle!.fontDecoration),
                ),
              ),
            ),

          if (rc.offerSubtitle != null && rc.offerSubtitle!.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                rc.offerSubtitle!.marginLeft,
                rc.offerSubtitle!.marginTop,
                rc.offerSubtitle!.marginRight,
                rc.offerSubtitle!.marginBottom,
              ),
              child: Text(
                rc.offerSubtitle!.text,
                textAlign: _parseTextAlign(rc.offerSubtitle!.textAlign),
                style: TextStyle(
                  color: _hexToColor(
                      rc.offerSubtitle!.color, Colors.white70),
                  fontSize: rc.offerSubtitle!.fontSize,
                  fontFamily: rc.offerSubtitle!.fontFamily,
                  fontWeight: TypeHelper.getFontWeight(
                      rc.offerSubtitle!.fontDecoration),
                  fontStyle: TypeHelper.getFontStyle(
                      rc.offerSubtitle!.fontDecoration),
                  decoration: TypeHelper.getTextDecoration(
                      rc.offerSubtitle!.fontDecoration),
                ),
              ),
            ),

          if (_d.couponCode != null && _d.couponCode!.isNotEmpty)
            _buildCouponBox(),
        ],
      ),
    );
  }

  Widget _buildCouponBox() {
    final coupon = _d.rewardContent.couponCta;

    return Container(
      margin: EdgeInsets.fromLTRB(
        coupon?.marginLeft ?? 0,
        coupon?.marginTop ?? 0,
        coupon?.marginRight ?? 0,
        coupon?.marginBottom ?? 0,
      ),
      child: Center(
        child: GestureDetector(
          onTap: () => _copyToClipboard(_d.couponCode!),
          child: Container(
            height: coupon?.ctaHeight ?? 50.0,
            width: coupon?.ctaWidth,
            decoration: BoxDecoration(
              color: _hexToColor(
                  coupon?.backgroundColor, const Color(0xFF30D158)),
              borderRadius: BorderRadius.only(
                topLeft:
                    Radius.circular(coupon?.cornerRadiusTopLeft ?? 12),
                topRight:
                    Radius.circular(coupon?.cornerRadiusTopRight ?? 12),
                bottomLeft:
                    Radius.circular(coupon?.cornerRadiusBottomLeft ?? 12),
                bottomRight:
                    Radius.circular(coupon?.cornerRadiusBottomRight ?? 12),
              ),
              border: Border.all(
                color: _hexToColor(
                    coupon?.borderColor, Colors.transparent),
                width: coupon?.borderWidth ?? 0,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _d.couponCode!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily:
                          coupon?.textFontFamily ?? 'monospace',
                      fontSize: coupon?.textFontSize ?? 12.0,
                      color: _hexToColor(
                          coupon?.textColor, Colors.white),
                      fontWeight: TypeHelper.getFontWeight(
                          coupon?.textFontDecoration),
                      fontStyle: TypeHelper.getFontStyle(
                          coupon?.textFontDecoration),
                      decoration: TypeHelper.getTextDecoration(
                          coupon?.textFontDecoration),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: _hexToColor(coupon?.textColor, Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final cta = _d.cta;
    return CtaButton(
      onTap: () {
        if (cta.url != null && cta.url!.isNotEmpty) {
          widget.appStorys
              .trackEvent(
                event: 'clicked',
                campaignId: widget.campaign.id,
                metadata: {'url': cta.url},
              )
              .catchError((_) {});
          LinkHandler.handle(cta.url, widget.onLinkTap);
        }
        _handleDismiss();
      },
      text: cta.buttonText,
      styling: cta.raw,
    );
  }
}

// ── Scratch Widget ────────────────────────────────────────────────────────────

class _ScratchWidget extends StatefulWidget {
  final double width;
  final double height;
  final double cornerRadius;
  final String? coverImageUrl;
  final VoidCallback onReveal;

  const _ScratchWidget({
    required this.width,
    required this.height,
    required this.cornerRadius,
    this.coverImageUrl,
    required this.onReveal,
  });

  @override
  State<_ScratchWidget> createState() => _ScratchWidgetState();
}

class _ScratchWidgetState extends State<_ScratchWidget> {
  static const double _brushRadius = 30.0;
  static const double _threshold = 0.10;
  // static const int _soundIntervalMs = 80;

  ui.Image? _coverImage;
  final List<Offset> _scratchPoints = [];
  final Set<int> _scratchedCells = {};
  bool _revealed = false;
  bool _imageLoaded = false;
  // int _lastSoundMs = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    if (widget.coverImageUrl == null || widget.coverImageUrl!.isEmpty) {
      if (mounted) setState(() => _imageLoaded = true);
      return;
    }
    final provider = NetworkImage(widget.coverImageUrl!);
    final stream = provider.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (mounted) {
            setState(() {
              _coverImage = info.image;
              _imageLoaded = true;
            });
          }
        },
        onError: (_, _) {
          if (mounted) setState(() => _imageLoaded = true);
        },
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_revealed) return;
    final local = details.localPosition;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > widget.width ||
        local.dy > widget.height) { return; }

    final totalCols = (widget.width / _brushRadius).ceil();
    final totalRows = (widget.height / _brushRadius).ceil();
    final col = (local.dx / _brushRadius).floor().clamp(0, totalCols - 1);
    final row = (local.dy / _brushRadius).floor().clamp(0, totalRows - 1);
    _scratchedCells.add(row * totalCols + col);

    setState(() => _scratchPoints.add(local));

    // final now = DateTime.now().millisecondsSinceEpoch;
    // if (now - _lastSoundMs >= _soundIntervalMs) {
    //   _lastSoundMs = now;
    //   SystemSound.play(SystemSoundType.click);
    // }

    final totalCells = totalCols * totalRows;
    if (!_revealed && _scratchedCells.length / totalCells >= _threshold) {
      _revealed = true;
      widget.onReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_imageLoaded) return _buildShimmer();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.cornerRadius),
          child: CustomPaint(
            isComplex: true,
            painter: _ScratchPainter(
              coverImage: _coverImage,
              scratchPoints: List.unmodifiable(_scratchPoints),
              brushRadius: _brushRadius,
            ),
            size: Size(widget.width, widget.height),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      onEnd: () {
        if (mounted) setState(() {});
      },
      builder: (context, value, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFF2C2C2E),
                Color(0xFF3C3C3E),
                Color(0xFF2C2C2E),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Scratch Painter ───────────────────────────────────────────────────────────

class _ScratchPainter extends CustomPainter {
  final ui.Image? coverImage;
  final List<Offset> scratchPoints;
  final double brushRadius;

  const _ScratchPainter({
    required this.coverImage,
    required this.scratchPoints,
    required this.brushRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grey base visible beneath scratched-away areas.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF9E9E9E),
    );

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    // Cover image (or solid grey when no image is provided).
    if (coverImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        coverImage!.width.toDouble(),
        coverImage!.height.toDouble(),
      );
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(coverImage!, src, dst, Paint());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF9E9E9E),
      );
    }

    // Erase scratched areas.
    final erasePaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    for (final point in scratchPoints) {
      canvas.drawCircle(point, brushRadius, erasePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter old) =>
      old.scratchPoints.length != scratchPoints.length ||
      old.coverImage != coverImage;
}
