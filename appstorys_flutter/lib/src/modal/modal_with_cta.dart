import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/cta_button.dart';
import '../utils/font_cache.dart';
import '../utils/link_handler.dart';

class ModalWithCTA extends StatefulWidget {
  final Map<String, dynamic> modalData;
  final VoidCallback onClose;
  final String? campaignId;
  final AppstorysFlutter? appStorys;
  final void Function(String)? onLinkTap;

  const ModalWithCTA({
    super.key,
    required this.modalData,
    required this.onClose,
    this.campaignId,
    this.appStorys,
    this.onLinkTap,
  });

  @override
  State<ModalWithCTA> createState() => _ModalWithCTAState();
}

class _ModalWithCTAState extends State<ModalWithCTA> {
  String? _resolvedTitleFont;
  String? _resolvedSubtitleFont;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  @override
  void didUpdateWidget(ModalWithCTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    final styling = widget.modalData['styling'] ?? {};
    final oldStyling = oldWidget.modalData['styling'] ?? {};
    final oldTitle = oldStyling['title']?['fontFamily'];
    final oldSubtitle = oldStyling['subTitle']?['fontFamily'];
    final newTitle = styling['title']?['fontFamily'];
    final newSubtitle = styling['subTitle']?['fontFamily'];
    if (oldTitle != newTitle || oldSubtitle != newSubtitle) {
      _loadFonts();
    }
  }

  Future<void> _loadFonts() async {
    final styling = widget.modalData['styling'] ?? {};

    final rawTitleFont = styling['title']?['fontFamily']?.toString();
    final rawSubtitleFont = styling['subTitle']?['fontFamily']?.toString();
    final resolvedTitle = await FontCache.resolveFontFamily(rawTitleFont);
    final resolvedSubtitle = await FontCache.resolveFontFamily(rawSubtitleFont);

    if (mounted) {
      setState(() {
        _resolvedTitleFont = resolvedTitle;
        _resolvedSubtitleFont = resolvedSubtitle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final content = widget.modalData['content'] ?? {};
      final styling = widget.modalData['styling'] ?? {};

      return Stack(
        children: [
          // FULL-SCREEN BACKDROP
          if (_getBackdropColor(styling) != Colors.transparent)
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: _getBackdropColor(styling),
              ),
            ),

          // MODAL DIALOG
          Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _getModalWidth(styling),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(styling),
                      borderRadius: _getBorderRadius(styling),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: _getBorderWidth(styling),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Media Section
                        if (_hasMediaContent(content))
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(_getTopRadius(styling)),
                            ),
                            child: _buildMediaWidget(
                              mediaType: content['chooseMediaType']['type'],
                              mediaUrl: content['chooseMediaType']['url'],
                            ),
                          ),

                        // Content Section
                        Padding(
                          padding: _getContentPadding(styling),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (_hasText(content['titleText']))
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    content['titleText'].toString(),
                                    style: _getTitleStyle(styling),
                                    textAlign: _getAlignment(styling['title']),
                                  ),
                                ),

                              const SizedBox(height: 8),

                              if (_hasText(content['subtitleText']))
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    content['subtitleText'].toString(),
                                    style: _getSubtitleStyle(styling),
                                    textAlign:
                                        _getAlignment(styling['subTitle']),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.zero,
                          child: _buildCTAButtons(content, styling),
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  if (_shouldShowCloseButton(styling))
                    Positioned(
                      top: _getCloseButtonTop(styling),
                      right: _getCloseButtonRight(styling),
                      left: _getCloseButtonLeft(styling),
                      child: CrossButton(
                        onTap: widget.onClose,
                        styling: {
                          'size': _parseToDouble(
                              styling['crossButton']?['size'], 40),
                          'borderWidth': 1,
                          'color': styling['crossButton']?['color'],
                          'margin': styling['crossButton']?['margin'],
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error rendering modal: $e');
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading modal'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }
  }

  TextStyle _getTitleStyle(Map<String, dynamic> styling) {
    try {
      final title = styling['title'] ?? {};
      return TextStyle(
        color: _parseColor(title['color'], Colors.black),
        fontSize: _parseToDouble(title['fontSize'], 16),
        fontWeight: _getFontWeight(title['fontStyle']),
        fontFamily: _resolvedTitleFont,
      );
    } catch (e) {
      return const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);
    }
  }

  TextStyle _getSubtitleStyle(Map<String, dynamic> styling) {
    try {
      final subTitle = styling['subTitle'] ?? {};
      return TextStyle(
        color: _parseColor(subTitle['color'], Colors.grey),
        fontSize: _parseToDouble(subTitle['fontSize'], 12),
        fontWeight: _getFontWeight(subTitle['fontStyle']),
        fontFamily: _resolvedSubtitleFont,
      );
    } catch (e) {
      return const TextStyle(fontSize: 12, color: Colors.grey);
    }
  }

  Widget _buildMediaWidget({
    required dynamic mediaType,
    required dynamic mediaUrl,
  }) {
    final String type = mediaType?.toString() ?? '';
    final String url = mediaUrl?.toString() ?? '';

    if (url.isEmpty) return const SizedBox.shrink();

    try {
      if (type == 'video') return _VideoPlayer(url: url);

      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } catch (e) {
      debugPrint('Media render error: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildCTAButtons(
    Map<String, dynamic> content,
    Map<String, dynamic> styling,
  ) {
    final primaryText = (content['primaryCtaText'] ?? '').toString();
    final secondaryText = (content['secondaryCtaText'] ?? '').toString();

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
      final primaryWidthValue = primaryStyling?['container']?['ctaWidth'];
      final secondaryWidthValue = secondaryStyling?['container']?['ctaWidth'];
      final primaryWidth = primaryWidthValue != null
          ? _parseToDouble(primaryWidthValue, 0)
          : null;
      final secondaryWidth = secondaryWidthValue != null
          ? _parseToDouble(secondaryWidthValue, 0)
          : null;

      final primaryButton = CtaButton(
        text: primaryText,
        onTap: () => _handlePrimaryCTA(content),
        styling: primaryStyling,
      );
      final secondaryButton = CtaButton(
        text: secondaryText,
        onTap: () => _handleSecondaryCTA(content),
        styling: secondaryStyling,
      );

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

    return _hasText(primaryText)
        ? CtaButton(
            text: primaryText,
            onTap: () => _handlePrimaryCTA(content),
            styling: _convertCtaStyling(styling['primaryCta']),
          )
        : CtaButton(
            text: secondaryText,
            onTap: () => _handleSecondaryCTA(content),
            styling: _convertCtaStyling(styling['secondaryCta']),
          );
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

  bool _hasText(dynamic text) =>
      text != null && text.toString().trim().isNotEmpty;

  bool _hasMediaContent(Map<String, dynamic> content) {
    try {
      final mediaType = content['chooseMediaType']?['type'];
      return (mediaType == 'image' ||
              mediaType == 'video' ||
              mediaType == 'lottie') &&
          _hasText(content['chooseMediaType']?['url']);
    } catch (e) {
      return false;
    }
  }

  double _getModalWidth(Map<String, dynamic> styling) {
    try {
      return _parseToDouble(
          styling['appearance']?['dimension']?['height'], 300);
    } catch (e) {
      return 300;
    }
  }

  double _getBorderWidth(Map<String, dynamic> styling) {
    try {
      return _parseToDouble(
          styling['appearance']?['dimension']?['borderWidth'], 2);
    } catch (e) {
      return 2;
    }
  }

  BorderRadius _getBorderRadius(Map<String, dynamic> styling) {
    try {
      final cr = styling['appearance']?['cornerRadius'] ?? {};
      return BorderRadius.only(
        topLeft: Radius.circular(_parseToDouble(cr['topLeft'], 20)),
        topRight: Radius.circular(_parseToDouble(cr['topRight'], 20)),
        bottomLeft: Radius.circular(_parseToDouble(cr['bottomLeft'], 20)),
        bottomRight: Radius.circular(_parseToDouble(cr['bottomRight'], 20)),
      );
    } catch (e) {
      return BorderRadius.circular(20);
    }
  }

  double _getTopRadius(Map<String, dynamic> styling) {
    try {
      return _parseToDouble(
          styling['appearance']?['cornerRadius']?['topLeft'], 20);
    } catch (e) {
      return 20;
    }
  }

  bool _shouldShowCloseButton(Map<String, dynamic> styling) {
    try {
      return styling['crossButton']?['enabled'] == true;
    } catch (e) {
      return true;
    }
  }

  Color _getBackdropColor(Map<String, dynamic> styling) {
    try {
      final backdrop = styling['appearance']?['backdrop'];
      final enableBackdrop = styling['appearance']?['enableBackdrop'] ?? true;
      if (!enableBackdrop) return Colors.transparent;
      final color = _parseColor(backdrop?['color'], Colors.black);
      final opacity = _parseToDouble(backdrop?['opacity'], 40) / 100;
      return color.withValues(alpha: opacity);
    } catch (e) {
      return Colors.black.withValues(alpha: 0.4);
    }
  }

  Color _getBackgroundColor(Map<String, dynamic> styling) {
    try {
      return _parseColor(
          styling['appearance']?['backgroundColor'], Colors.white);
    } catch (e) {
      return Colors.white;
    }
  }

  EdgeInsets _getContentPadding(Map<String, dynamic> styling) {
    try {
      final padding = styling['appearance']?['padding'] ?? {};
      return EdgeInsets.fromLTRB(
        _parseToDouble(padding['left'], 16),
        _parseToDouble(padding['top'], 16),
        _parseToDouble(padding['right'], 16),
        0,
      );
    } catch (e) {
      return const EdgeInsets.fromLTRB(16, 16, 16, 0);
    }
  }

  double? _getCloseButtonTop(Map<String, dynamic> styling) {
    try {
      final margin = styling['crossButton']?['margin'];
      if (margin == null) return 8.0;
      final top = _parseToDouble(margin['top'], 8.0);
      return top >= 0 ? top : 8.0;
    } catch (e) {
      return 8.0;
    }
  }

  double? _getCloseButtonRight(Map<String, dynamic> styling) {
    try {
      final margin = styling['crossButton']?['margin'];
      if (margin == null) return 8.0;
      final right = _parseToDouble(margin['right'], 8.0);
      return right >= 0 ? right : 8.0;
    } catch (e) {
      return 8.0;
    }
  }

  double? _getCloseButtonLeft(Map<String, dynamic> styling) => null;

  TextAlign _getAlignment(Map<String, dynamic>? style) {
    try {
      switch (style?['textAlign']?.toString().toLowerCase() ?? '') {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        case 'center':
          return TextAlign.center;
        default:
          return TextAlign.center;
      }
    } catch (e) {
      return TextAlign.center;
    }
  }

  FontWeight _getFontWeight(dynamic fontStyle) {
    switch (fontStyle?.toString().toLowerCase() ?? '') {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
        return FontWeight.w600;
      default:
        return FontWeight.bold;
    }
  }

  Color _parseColor(dynamic colorValue, Color defaultColor) {
    try {
      if (colorValue == null) return defaultColor;
      final colorString = colorValue.toString().trim();
      if (colorString.isEmpty) return defaultColor;
      final hexColor = colorString.replaceAll('#', '').toUpperCase();
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      if (hexColor.length == 8) return Color(int.parse(hexColor, radix: 16));
      return defaultColor;
    } catch (e) {
      debugPrint('Error parsing color "$colorValue": $e');
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
      debugPrint('Error parsing number "$value": $e');
      return defaultValue;
    }
  }

  Future<void> _handlePrimaryCTA(Map<String, dynamic> content) async {
    try {
      widget.appStorys
          ?.trackEvent(event: 'clicked', campaignId: widget.campaignId ?? '')
          .catchError((_) {});
      final redirection = content['primaryCtaRedirection'] ?? {};
      final url = redirection['url']?.toString();
      if (url != null && url.isNotEmpty) {
        widget.appStorys?.viaAppStorys(url).catchError((_) {});
        LinkHandler.handle(url, widget.onLinkTap);
      }
    } catch (e) {
      debugPrint('Primary CTA error: $e');
    }
  }

  Future<void> _handleSecondaryCTA(Map<String, dynamic> content) async {
    try {
      widget.appStorys
          ?.trackEvent(event: 'clicked', campaignId: widget.campaignId ?? '')
          .catchError((_) {});
      final redirection = content['secondaryCtaRedirection'] ?? {};
      final url = redirection['url']?.toString();
      if (url != null && url.isNotEmpty) {
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
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator(color: Colors.grey));
  }
}

