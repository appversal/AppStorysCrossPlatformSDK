import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/cta_button.dart';
import '../utils/font_cache.dart';
import '../utils/link_handler.dart';

class ModalFullPageCarousel extends StatefulWidget {
  final Map<String, dynamic> modalData;
  final VoidCallback onClose;
  final String? campaignId;
  final AppstorysFlutter? appStorys;
  final void Function(String)? onLinkTap;

  const ModalFullPageCarousel({
    super.key,
    required this.modalData,
    required this.onClose,
    this.campaignId,
    this.appStorys,
    this.onLinkTap,
  });

  @override
  State<ModalFullPageCarousel> createState() => _ModalFullPageCarouselState();
}

class _ModalFullPageCarouselState extends State<ModalFullPageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  List<Map<String, dynamic>> _slides = [];

  final Map<int, String?> _resolvedTitleFonts = {};
  final Map<int, String?> _resolvedSubtitleFonts = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSlides();
    _loadAllFonts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appStorys
          ?.trackEvent(event: 'viewed', campaignId: widget.campaignId ?? '')
          .catchError((_) {});
    });
  }

  void _loadSlides() {
    try {
      final content = widget.modalData['content'] ?? {};
      final set = (content as Map)['set'] as List?;
      if (set != null && set.isNotEmpty) {
        _slides = set.map((s) => s as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error loading slides: $e');
    }
  }

  Future<void> _loadFont(String? raw, void Function(String?) onResolved) async {
    final resolved = await FontCache.resolveFontFamily(raw);
    if (mounted) setState(() => onResolved(resolved));
  }

  Future<void> _loadAllFonts() async {
    for (int i = 0; i < _slides.length; i++) {
      final styling = _slides[i]['styling'] ?? {};
      await _loadFont(styling['title']?['fontFamily']?.toString(),
          (v) => _resolvedTitleFonts[i] = v);
      await _loadFont(styling['subTitle']?['fontFamily']?.toString(),
          (v) => _resolvedSubtitleFonts[i] = v);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return _buildErrorDialog();

    final firstSlide = _slides.first;
    final styling = firstSlide['styling'] ?? {};
    final enableCrossButton = styling['crossButton']?['enabled'] ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) =>
                _buildSlideWithBackground(_slides[index], index),
          ),
          if (_slides.length > 1)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: _buildPageIndicators(),
            ),
          if (enableCrossButton)
            Positioned(
              top: _getCloseButtonTop(styling),
              right: 12.0,
              child: CrossButton(
                onTap: () {
                  widget.appStorys
                      ?.trackEvent(
                          event: 'closed',
                          campaignId: widget.campaignId ?? '')
                      .catchError((_) {});
                  widget.onClose();
                },
                styling: styling['crossButton'],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlideWithBackground(Map<String, dynamic> slide, int index) {
    final styling = slide['styling'] ?? {};
    final cornerRadius = styling['appearance']?['cornerRadius'] ?? {};

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_parseToDouble(cornerRadius['topLeft'], 0)),
          topRight:
              Radius.circular(_parseToDouble(cornerRadius['topRight'], 0)),
          bottomLeft:
              Radius.circular(_parseToDouble(cornerRadius['bottomLeft'], 0)),
          bottomRight:
              Radius.circular(_parseToDouble(cornerRadius['bottomRight'], 0)),
        ),
        color: _getBackdropColor(styling),
      ),
      child: _buildSlide(slide, index),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, int index) {
    final mediaType = slide['chooseMediaType']?['type'];
    final mediaUrl = slide['chooseMediaType']?['url'];
    final titleText = slide['titleText'] ?? '';
    final subtitleText = slide['subtitleText'] ?? '';
    final styling = slide['styling'] ?? {};

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            child: _buildMediaWidget(mediaType: mediaType, mediaUrl: mediaUrl),
          ),
        ),
        Container(
          padding: _getContentPadding(styling),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasText(titleText))
                Text(
                  titleText.toString(),
                  style: _getTitleStyle(styling, index),
                  textAlign: _getAlignment(styling['title']),
                  maxLines: null,
                ),
              const SizedBox(height: 8),
              if (_hasText(subtitleText))
                Text(
                  subtitleText.toString(),
                  style: _getSubtitleStyle(styling, index),
                  textAlign: _getAlignment(styling['subTitle']),
                  maxLines: null,
                ),
              const SizedBox(height: 16),
              _buildCTAButtons(slide, styling),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _getTitleStyle(Map<String, dynamic> styling, int index) {
    try {
      final title = styling['title'] ?? {};
      return TextStyle(
        color: _parseColor(title['color'], Colors.black),
        fontSize: _parseToDouble(title['fontSize'], 16),
        fontWeight: _getFontWeight(title['fontDecoration']),
        fontStyle: _getFontStyle(title['fontDecoration']),
        decoration: _getTextDecoration(title['fontDecoration']),
        fontFamily: _resolvedTitleFonts[index],
      );
    } catch (e) {
      return const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);
    }
  }

  TextStyle _getSubtitleStyle(Map<String, dynamic> styling, int index) {
    try {
      final subTitle = styling['subTitle'] ?? {};
      return TextStyle(
        color: _parseColor(subTitle['color'], Colors.grey),
        fontSize: _parseToDouble(subTitle['fontSize'], 12),
        fontWeight: _getFontWeight(subTitle['fontDecoration']),
        fontStyle: _getFontStyle(subTitle['fontDecoration']),
        decoration: _getTextDecoration(subTitle['fontDecoration']),
        fontFamily: _resolvedSubtitleFonts[index],
      );
    } catch (e) {
      return const TextStyle(fontSize: 12, color: Colors.grey);
    }
  }

  Widget _buildMediaWidget(
      {required dynamic mediaType, required dynamic mediaUrl}) {
    final String type = mediaType?.toString() ?? '';
    final String url = mediaUrl?.toString() ?? '';

    if (url.isEmpty) {
      return Container(
        color: Colors.transparent,
        child: const Center(
            child:
                Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
      );
    }

    try {
      if (type == 'video') return _VideoPlayer(url: url);

      return Image.network(
        url,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, _, _) => Container(
            color: Colors.transparent,
            child: const Icon(Icons.image, size: 50, color: Colors.grey)),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
              color: Colors.transparent,
              child: const Center(child: CircularProgressIndicator()));
        },
      );
    } catch (e) {
      debugPrint('Media render error: $e');
      return Container(
          color: Colors.transparent,
          child: const Icon(Icons.error, size: 50, color: Colors.grey));
    }
  }

  Widget _buildCTAButtons(
      Map<String, dynamic> slide, Map<String, dynamic> styling) {
    final primaryText = (slide['primaryCta'] ?? '').toString();
    final secondaryText = (slide['secondayCta'] ?? '').toString();

    if (!_hasText(primaryText) && !_hasText(secondaryText)) {
      return const SizedBox.shrink();
    }

    final ctaHeight =
        _parseToDouble(styling['primaryCta']?['container']?['height'], 40);

    if (_hasText(primaryText) && _hasText(secondaryText)) {
      final primaryStyling = _convertCtaStyling(styling['primaryCta']);
      final secondaryStyling = _convertCtaStyling(styling['secondaryCta']);

      final primaryFullWidth =
          primaryStyling?['container']?['ctaFullWidth'] as bool? ?? false;
      final secondaryFullWidth =
          secondaryStyling?['container']?['ctaFullWidth'] as bool? ?? false;
      final primaryWidth = primaryStyling?['container']?['ctaWidth'] != null
          ? _parseToDouble(primaryStyling!['container']['ctaWidth'], 0)
          : null;
      final secondaryWidth = secondaryStyling?['container']?['ctaWidth'] != null
          ? _parseToDouble(secondaryStyling!['container']['ctaWidth'], 0)
          : null;

      final primaryButton = CtaButton(
          text: primaryText,
          onTap: () => _handlePrimaryCTA(slide),
          styling: primaryStyling);
      final secondaryButton = CtaButton(
          text: secondaryText,
          onTap: () => _handleSecondaryCTA(slide),
          styling: secondaryStyling);

      List<Widget> rowChildren = [];

      if (primaryFullWidth || primaryWidth == null) {
        rowChildren.add(Flexible(flex: 1, child: primaryButton));
      } else {
        rowChildren.add(SizedBox(width: primaryWidth, child: primaryButton));
        if (secondaryWidth != null && !secondaryFullWidth) {
          rowChildren.add(const SizedBox(width: 8));
        }
      }

      if (secondaryFullWidth ||
          (secondaryWidth == null && primaryWidth != null)) {
        rowChildren.add(Flexible(flex: 1, child: secondaryButton));
      } else if (secondaryWidth != null) {
        rowChildren
            .add(SizedBox(width: secondaryWidth, child: secondaryButton));
      } else {
        rowChildren.add(Flexible(flex: 1, child: secondaryButton));
      }

      return SizedBox(
        height: ctaHeight,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center, children: rowChildren),
      );
    }

    final primaryCtaStyling = _convertCtaStyling(styling['primaryCta']);
    final secondaryCtaStyling = _convertCtaStyling(styling['secondaryCta']);

    if (_hasText(primaryText)) {
      final ctaFullWidth =
          primaryCtaStyling?['container']?['ctaFullWidth'] as bool? ?? false;
      final ctaWidth = primaryCtaStyling?['container']?['ctaWidth'] != null
          ? _parseToDouble(primaryCtaStyling!['container']['ctaWidth'], 0)
          : null;
      final btn = CtaButton(
          text: primaryText,
          onTap: () => _handlePrimaryCTA(slide),
          styling: primaryCtaStyling);
      if (ctaFullWidth) { return Flexible(child: btn); }
      if (ctaWidth != null && ctaWidth > 0) {
        return SizedBox(width: ctaWidth, child: btn);
      }
      return btn;
    } else {
      final ctaFullWidth =
          secondaryCtaStyling?['container']?['ctaFullWidth'] as bool? ?? false;
      final ctaWidth = secondaryCtaStyling?['container']?['ctaWidth'] != null
          ? _parseToDouble(secondaryCtaStyling!['container']['ctaWidth'], 0)
          : null;
      final btn = CtaButton(
          text: secondaryText,
          onTap: () => _handleSecondaryCTA(slide),
          styling: secondaryCtaStyling);
      if (ctaFullWidth) { return Flexible(child: btn); }
      if (ctaWidth != null && ctaWidth > 0) {
        return SizedBox(width: ctaWidth, child: btn);
      }
      return btn;
    }
  }

  Map<String, dynamic>? _convertCtaStyling(dynamic ctaStyling) {
    if (ctaStyling == null) return null;
    try {
      final Map<String, dynamic> styling =
          ctaStyling is Map<String, dynamic> ? ctaStyling : {};
      return {
        'borderRadius': styling['cornerRadius'],
        'container': styling['container'],
        'margin': styling['margin'],
        'text': styling['text'],
      };
    } catch (e) {
      debugPrint('Error converting CTA styling: $e');
      return null;
    }
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildErrorDialog() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading carousel'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: widget.onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Color _getBackdropColor(Map<String, dynamic> styling) {
    try {
      final backdropColor = styling['appearance']?['backdropColor'];
      final backdropOpacity =
          _parseToDouble(styling['appearance']?['backdropOpacity'], 40) / 100;
      return _parseColor(backdropColor, Colors.black).withValues(alpha: backdropOpacity);
    } catch (e) {
      return Colors.black.withValues(alpha: 0.4);
    }
  }

  EdgeInsets _getContentPadding(Map<String, dynamic> styling) {
    try {
      final padding = styling['appearance']?['padding'] ?? {};
      return EdgeInsets.fromLTRB(
        _parseToDouble(padding['left'], 16),
        _parseToDouble(padding['top'], 16),
        _parseToDouble(padding['right'], 16),
        _parseToDouble(padding['bottom'], 16),
      );
    } catch (e) {
      return const EdgeInsets.all(16);
    }
  }

  double? _getCloseButtonTop(Map<String, dynamic> styling) {
    try {
      final margin = styling['crossButton']?['margin'];
      if (margin == null) return 12.0;
      final top = _parseToDouble(margin['top'], 12.0);
      return top >= 0 ? top : 12.0;
    } catch (e) {
      return 12.0;
    }
  }

  TextAlign _getAlignment(Map<String, dynamic>? style) {
    try {
      switch (style?['textAlign']?.toString().toLowerCase() ?? '') {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        default:
          return TextAlign.center;
      }
    } catch (e) {
      return TextAlign.center;
    }
  }

  FontWeight _getFontWeight(dynamic fontDecoration) {
    if (fontDecoration is List) {
      return fontDecoration.contains('bold') ? FontWeight.bold : FontWeight.normal;
    }
    if (fontDecoration is String) {
      return fontDecoration.toLowerCase() == 'bold' ? FontWeight.bold : FontWeight.normal;
    }
    return FontWeight.normal;
  }

  FontStyle _getFontStyle(dynamic fontDecoration) {
    if (fontDecoration is List) {
      return fontDecoration.contains('italic') ? FontStyle.italic : FontStyle.normal;
    }
    if (fontDecoration is String) {
      return fontDecoration.toLowerCase() == 'italic' ? FontStyle.italic : FontStyle.normal;
    }
    return FontStyle.normal;
  }

  TextDecoration _getTextDecoration(dynamic fontDecoration) {
    if (fontDecoration is List) {
      return fontDecoration.contains('underline') ? TextDecoration.underline : TextDecoration.none;
    }
    if (fontDecoration is String) {
      return fontDecoration.toLowerCase() == 'underline' ? TextDecoration.underline : TextDecoration.none;
    }
    return TextDecoration.none;
  }

  bool _hasText(dynamic text) =>
      text != null && text.toString().trim().isNotEmpty;

  Color _parseColor(dynamic colorValue, Color defaultColor) {
    try {
      if (colorValue == null) return defaultColor;
      final hex =
          colorValue.toString().trim().replaceAll('#', '').toUpperCase();
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return defaultColor;
    } catch (e) {
      return defaultColor;
    }
  }

  double _parseToDouble(dynamic value, double defaultValue) {
    try {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  Future<void> _handlePrimaryCTA(Map<String, dynamic> slide) async {
    try {
      final redirection = slide['primaryCtaRedirection'] ?? {};
      final url = redirection['url']?.toString();
      if (url != null && url.isNotEmpty) {
        widget.appStorys
            ?.trackEvent(
                event: 'clicked', campaignId: widget.campaignId ?? '')
            .catchError((_) {});
        widget.appStorys?.viaAppStorys(url).catchError((_) {});
        LinkHandler.handle(url, widget.onLinkTap);
      }
    } catch (e) {
      debugPrint('Primary CTA error: $e');
    }
  }

  Future<void> _handleSecondaryCTA(Map<String, dynamic> slide) async {
    try {
      final redirection = slide['secondaryCtaRedirection'] ?? {};
      final url = redirection['url']?.toString();
      if (url != null && url.isNotEmpty) {
        widget.appStorys
            ?.trackEvent(
                event: 'clicked', campaignId: widget.campaignId ?? '')
            .catchError((_) {});
        widget.appStorys?.viaAppStorys(url).catchError((_) {});
        LinkHandler.handle(url, widget.onLinkTap);
      }
    } catch (e) {
      debugPrint('Secondary CTA error: $e');
    }
  }
}

// =============================================================================
// Private video player
// =============================================================================
class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        : const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}

