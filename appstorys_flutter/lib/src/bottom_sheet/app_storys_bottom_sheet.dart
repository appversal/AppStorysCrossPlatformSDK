import 'dart:convert';
import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/async_font_text.dart';

Color _parseHexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) return Color(int.parse(s, radix: 16) + 0xFF000000);
    if (s.length == 8) return Color(int.parse(s, radix: 16));
    return fallback;
  } catch (_) {
    return fallback;
  }
}

/// Listens to the campaigns stream and shows a BTS (BottomSheet) campaign
/// as a modal bottom sheet whenever one becomes available.
///
/// Place this inside [AppStorysOverlay] or add it directly in your widget tree.
/// The widget itself renders as [SizedBox.shrink]; the actual UI is shown via
/// [showModalBottomSheet] so it floats above all other content.
class AppStorysBottomSheet extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;
  final double bottomPadding;

  const AppStorysBottomSheet({
    super.key,
    required this.appStorys,
    this.bottomPadding = 0,
    this.onLinkTap,
  });

  @override
  State<AppStorysBottomSheet> createState() => _AppStorysBottomSheetState();
}

class _AppStorysBottomSheetState extends State<AppStorysBottomSheet>
    with CampaignsStreamMixin {
  BottomSheetCampaign? _current;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(widget.appStorys.campaignsStream, _handleCampaigns);
  }

  void _handleCampaigns(String json) {
    final campaign = _parse(json);
    if (!mounted) return;

    final isNew = campaign?.id != _current?.id;
    _current = campaign;

    if (isNew && campaign != null && !_showing) {
      _showing = true;
      _trackView(campaign);
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  BottomSheetCampaign? _parse(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      final raw = data.whereType<Map>().firstWhere(
        (c) => c['campaign_type'] == 'BTS',
        orElse: () => {},
      );
      if (raw.isEmpty) return null;
      return BottomSheetCampaign.fromJson(_normalize(raw));
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

  void _trackView(BottomSheetCampaign c) {
    if (c.id.isEmpty) return;
    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: c.id)
        .catchError((_) {});
  }

  void _show() {
    if (!mounted) {
      _showing = false;
      return;
    }
    final campaign = _current;
    if (campaign == null) {
      _showing = false;
      return;
    }

    final backdropColor = _parseHexColor(campaign.backdropColor, Colors.black);
    final opacity = ((campaign.backdropOpacity ?? 50.0) / 100.0).clamp(0.0, 1.0);

    try {
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: backdropColor.withValues(alpha: opacity),
        isDismissible: true,
        enableDrag: true,
        builder: (modalCtx) => Padding(
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          child: _BottomSheetContent(
            campaign: campaign,
            onDismiss: () => Navigator.of(modalCtx).pop(),
            onClicked: (link) {
              widget.appStorys
                  .trackEvent(event: 'clicked', campaignId: campaign.id)
                  .catchError((_) {});
              if (link?.isNotEmpty == true) widget.onLinkTap?.call(link!);
            },
          ),
        ),
       ).then((_) {
         if (mounted) _showing = false;
         // Dismiss the bottom sheet from core after it's closed, regardless of reason
         // (user close button, swipe, or background tap). This prevents re-appearing
         // when navigating back to the same screen, matching Kotlin's overlay approach.
         if (_current != null && _current!.id.isNotEmpty) {
           widget.appStorys.dismissCampaign(_current!.id).catchError((_) {});
         }
       });
    } catch (_) {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _BottomSheetContent extends StatelessWidget {
  final BottomSheetCampaign campaign;
  final VoidCallback onDismiss;
  final void Function(String? link) onClicked;

  const _BottomSheetContent({
    required this.campaign,
    required this.onDismiss,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    final topLeft = campaign.cornerRadius?.topLeft ?? 16.0;
    final topRight = campaign.cornerRadius?.topRight ?? 16.0;
    final topRadius = BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
    );

    final sorted = [...campaign.elements]
      ..sort((a, b) => a.order.compareTo(b.order));

    final imageEl = _firstWhere(sorted, (e) => e.type == 'image');
    final hasOverlay = imageEl?.overlayButton == true;

    final crossBtn = campaign.effectiveCrossButton;

    return SafeArea(
      child: Stack(
        children: [
          if (hasOverlay && imageEl != null)
            _ImageElement(element: imageEl, onTap: onClicked),

          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: topRadius,
              child: Stack(
                children: [
                  Container(
                    color: _parseHexColor(campaign.backgroundColor, Colors.white),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildElements(sorted, hasOverlay),
                      ),
                    ),
                  ),

                  if (campaign.isCrossEnabled)
                    Positioned(
                      top: crossBtn?.margin?.top ?? 8,
                      right: crossBtn?.margin?.right ?? 8,
                      child: CrossButton(
                        onTap: onDismiss,
                        iconSize: crossBtn?.size ?? 18,
                        styling: crossBtn?.color != null
                            ? {'color': crossBtn!.color}
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildElements(List<BottomSheetElement> sorted, bool skipImages) {
    final allCTAs = sorted.where((e) => e.type == 'cta').toList();
    final leftCTA = _firstWhere(allCTAs, (e) => e.position == 'left');
    final rightCTA = _firstWhere(allCTAs, (e) => e.position == 'right');
    final pairRendered = <BottomSheetElement>{};

    final widgets = <Widget>[];

    for (final element in sorted) {
      switch (element.type) {
        case 'image':
          if (!skipImages) {
            widgets.add(_ImageElement(element: element, onTap: onClicked));
          }
          break;

        case 'body':
          widgets.add(_BodyElement(element: element));
          break;

        case 'cta':
          if (leftCTA != null && rightCTA != null) {
            if (element == leftCTA && !pairRendered.contains(leftCTA)) {
              widgets.add(Row(
                children: [
                  Expanded(
                    child: _CTAElement(
                      element: leftCTA,
                      onTap: () => onClicked(leftCTA.ctaLink),
                    ),
                  ),
                  Expanded(
                    child: _CTAElement(
                      element: rightCTA,
                      onTap: () => onClicked(rightCTA.ctaLink),
                    ),
                  ),
                ],
              ));
              pairRendered.addAll([leftCTA, rightCTA]);
            }
          } else if (element.position != 'left' && element.position != 'right') {
            widgets.add(_CTAElement(
              element: element,
              onTap: () => onClicked(element.ctaLink),
            ));
          } else if ((element.position == 'left' && rightCTA == null) ||
              (element.position == 'right' && leftCTA == null)) {
            widgets.add(_CTAElement(
              element: element,
              onTap: () => onClicked(element.ctaLink),
            ));
          }
          break;
      }
    }

    return widgets;
  }

  static T? _firstWhere<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }
}

class _ImageElement extends StatelessWidget {
  final BottomSheetElement element;
  final void Function(String?) onTap;

  const _ImageElement({required this.element, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pL = element.paddingLeft ?? 0.0;
    final pR = element.paddingRight ?? 0.0;
    final pT = element.paddingTop ?? 0.0;
    final pB = element.paddingBottom ?? 0.0;

    final cr = element.cornerRadius;
    final borderRadius = cr != null
        ? BorderRadius.only(
            topLeft: Radius.circular(cr.topLeft),
            topRight: Radius.circular(cr.topRight),
            bottomLeft: Radius.circular(cr.bottomLeft),
            bottomRight: Radius.circular(cr.bottomRight),
          )
        : BorderRadius.zero;

    final url = element.url;
    final isLottie = isLottieUrl(url);

    return GestureDetector(
      onTap: () => onTap(element.imageLink),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(left: pL, right: pR, top: pT, bottom: pB),
        alignment: _alignment(element.alignment),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: isLottie
              ? Container(height: 200, color: Colors.grey[300])
              : url?.isNotEmpty == true
                  ? Image.network(
                      url!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, _, _) =>
                          Container(height: 100, color: Colors.grey[300]),
                    )
                  : Container(height: 100, color: Colors.grey[300]),
        ),
      ),
    );
  }

  Alignment _alignment(String? a) {
    switch (a?.toLowerCase()) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}

class _BodyElement extends StatelessWidget {
  final BottomSheetElement element;

  const _BodyElement({required this.element});

  @override
  Widget build(BuildContext context) {
    final mL = element.marginLeft ?? 0.0;
    final mR = element.marginRight ?? 0.0;
    final mT = element.marginTop ?? 0.0;
    final mB = element.marginBottom ?? 0.0;

    final hasZeroMargins = mL == 0 && mR == 0 && mT == 0 && mB == 0;
    final dp = hasZeroMargins ? 12.0 : 0.0;

    final bgColor = _parseHexColor(element.bodyBackgroundColor, Colors.transparent);

    final titleText = element.titleText;
    final descText = element.descriptionText;

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.only(
        left: mL + dp,
        right: mR + dp,
        top: mT + dp,
        bottom: mB + dp,
      ),
      child: Column(
        crossAxisAlignment: _crossAxis(element.alignment),
        children: [
          if (titleText != null && titleText.isNotEmpty)
            _buildText(
              text: titleText,
              fontStyle: element.titleFontStyle,
              fallbackFontSize: element.titleFontSize?.toDouble() ?? 16.0,
              lineHeight: element.titleLineHeight ?? 1.0,
              fallbackAlign: element.alignment,
            ),
          if ((element.spacingBetweenTitleDesc ?? 0) > 0 &&
              titleText != null &&
              titleText.isNotEmpty &&
              descText != null &&
              descText.isNotEmpty)
            SizedBox(height: element.spacingBetweenTitleDesc),
          if (descText != null && descText.isNotEmpty)
            _buildText(
              text: descText,
              fontStyle: element.descriptionFontStyle,
              fallbackFontSize: element.descriptionFontSize?.toDouble() ?? 14.0,
              lineHeight: element.descriptionLineHeight ?? 1.0,
              fallbackAlign: element.alignment,
            ),
        ],
      ),
    );
  }

  Widget _buildText({
    required String text,
    required BottomSheetFontStyle? fontStyle,
    required double fallbackFontSize,
    required double lineHeight,
    required String? fallbackAlign,
  }) {
    final fontSize = fontStyle?.fontSize ?? fallbackFontSize;
    final color = _parseHexColor(fontStyle?.colour, Colors.black);
    final textAlign = _textAlign(fontStyle?.alignment ?? fallbackAlign);
    final deco = _parseDecoration(fontStyle?.decoration);

    return AsyncFontText(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontStyle?.fontFamily,
        fontWeight: deco.$1,
        fontStyle: deco.$2,
        decoration: deco.$3,
        height: lineHeight,
      ),
    );
  }

  (FontWeight, FontStyle, TextDecoration) _parseDecoration(List<String>? list) {
    final s = (list ?? []).join(' ').toLowerCase();
    return (
      s.contains('bold') ? FontWeight.bold : FontWeight.normal,
      s.contains('italic') ? FontStyle.italic : FontStyle.normal,
      s.contains('underline') ? TextDecoration.underline : TextDecoration.none,
    );
  }

  CrossAxisAlignment _crossAxis(String? a) {
    switch (a?.toLowerCase()) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'right':
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }

  TextAlign _textAlign(String? a) {
    switch (a?.toLowerCase()) {
      case 'left':
        return TextAlign.start;
      case 'right':
        return TextAlign.end;
      default:
        return TextAlign.center;
    }
  }
}

class _CTAElement extends StatelessWidget {
  final BottomSheetElement element;
  final VoidCallback onTap;

  const _CTAElement({required this.element, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cta = element.cta;

    final pL = (cta?.margin?.left ?? element.marginLeft ?? 0.0);
    final pR = (cta?.margin?.right ?? element.marginRight ?? 0.0);
    final pT = (cta?.margin?.top ?? element.marginTop ?? 0.0);
    final pB = (cta?.margin?.bottom ?? element.marginBottom ?? 0.0);

    final buttonColor = _parseHexColor(
      cta?.container?.ctaBoxColor ?? element.ctaBoxColor ?? '#000000',
      Colors.black,
    );

    final textColor = _parseHexColor(
      cta?.text?.color ?? element.ctaTextColour ?? '#FFFFFF',
      Colors.white,
    );

    final bgColorStr = cta?.container?.backgroundColor?.isNotEmpty == true
        ? cta!.container!.backgroundColor
        : element.ctaBackgroundColor;
    final bgColor = _parseHexColor(bgColorStr, Colors.transparent);

    final buttonHeight = cta?.container?.height ?? element.ctaHeight ?? 50.0;
    final buttonWidth = cta?.container?.ctaWidth ?? element.ctaWidth ?? 100.0;
    final isFullWidth = cta?.container?.ctaFullWidth ?? element.ctaFullWidth ?? false;

    final alignStr = cta?.container?.alignment ?? element.alignment;
    final boxAlignment = _alignment(alignStr);

    final cr = cta?.cornerRadius ?? element.ctaBorderRadius;
    final borderRadius = cr != null
        ? BorderRadius.only(
            topLeft: Radius.circular(cr.topLeft),
            topRight: Radius.circular(cr.topRight),
            bottomLeft: Radius.circular(cr.bottomLeft),
            bottomRight: Radius.circular(cr.bottomRight),
          )
        : BorderRadius.zero;

    final deco = cta?.text?.fontDecoration ?? element.ctaFontDecoration ?? [];
    final decoStr = deco.join(' ').toLowerCase();
    final fontWeight = decoStr.contains('bold') ? FontWeight.bold : FontWeight.normal;
    final fontStyle = decoStr.contains('italic') ? FontStyle.italic : FontStyle.normal;
    final textDeco = decoStr.contains('underline')
        ? TextDecoration.underline
        : TextDecoration.none;

    final fontFamily = cta?.text?.fontFamily ?? element.ctaFontFamily;
    final fontSize = cta?.text?.fontSize?.toDouble() ??
        double.tryParse(element.ctaFontSize ?? '') ??
        14.0;

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.only(left: pL, right: pR, top: pT, bottom: pB),
      alignment: boxAlignment,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: buttonHeight,
          width: isFullWidth ? double.infinity : buttonWidth,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          child: AsyncFontText(
            element.ctaText ?? 'Click',
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontFamily: fontFamily,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              decoration: textDeco,
            ),
          ),
        ),
      ),
    );
  }

  Alignment _alignment(String? a) {
    switch (a?.toLowerCase()) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}
