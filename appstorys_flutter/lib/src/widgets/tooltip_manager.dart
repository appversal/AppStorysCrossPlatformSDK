import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef TrackEventCallback = Future<void> Function(
  String event, {
  String? campaignId,
  Map<String, Object?>? metadata,
});

typedef DismissCampaignCallback = Future<void> Function(String campaignId);

class TooltipManager {
  TooltipManager._();

  static OverlayEntry? _overlay;
  static BuildContext? _ctx;
  static final List<Map<String, dynamic>> _queue = [];
  static int _index = 0;
  static bool _busy = false;
  static String? _campaignId;
  static TrackEventCallback? _trackEvent;
  static DismissCampaignCallback? _dismissCampaign;

  static Future<void> processTooltips(
    List<dynamic> campaigns,
    BuildContext context,
    TrackEventCallback trackEvent,
    DismissCampaignCallback dismissCampaign,
  ) async {
    _ctx = context;
    _trackEvent = trackEvent;
    _dismissCampaign = dismissCampaign;

    final ttpList = campaigns
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((c) => c['campaign_type'] == 'TTP')
        .toList();

    if (ttpList.isEmpty) return;

    final campaign = ttpList.first;
    _campaignId = (campaign['id'] ?? campaign['campaign_id'] ?? '').toString();

    final tooltips = ((campaign['details']?['tooltips']) as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) =>
          ((a['order'] as num?)?.toInt() ?? 0)
              .compareTo((b['order'] as num?)?.toInt() ?? 0));

    reset();

    for (final t in tooltips) {
      final target = (t['target'] as String?) ?? '';
      final el = _findElement(target);
      if (el != null) {
        _queue.add({'data': t, 'element': el});
      } else {
        debugPrint('[TooltipManager] target "$target" not found in widget tree — skipped');
      }
    }

    if (_queue.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      await _showNext();
    }
  }

  static void reset() {
    _queue.clear();
    _index = 0;
    _busy = false;
    _overlay?.remove();
    _overlay = null;
  }

  static Future<void> _showNext() async {
    if (_busy || _index >= _queue.length) return;
    _busy = true;
    final item = _queue[_index];
    await _show(item['element'] as Element, item['data'] as Map<String, dynamic>);
  }

  static void _advance() {
    _overlay?.remove();
    _overlay = null;
    _index++;
    _busy = false;
    if (_index < _queue.length) {
      Future.delayed(const Duration(milliseconds: 300), _showNext);
    } else {
      // All tooltips navigated — disable the campaign in core so it is filtered
      // out of getCampaignsJson() for the rest of the session across all screens.
      if (_campaignId != null && _campaignId!.isNotEmpty) {
        _dismissCampaign?.call(_campaignId!);
      }
      reset();
    }
  }

  static Element? _findElement(String target) {
    if (target.isEmpty || _ctx?.mounted != true) return null;
    Element? found;
    void visit(Element el) {
      if (found != null) return;
      final key = el.widget.key;
      if (key is ValueKey<String> && key.value == target) {
        found = el;
        return;
      }
      el.visitChildren(visit);
    }
    try {
      visit(_ctx! as Element);
    } catch (e) {
      debugPrint('[TooltipManager] error walking tree: $e');
    }
    return found;
  }

  static Future<void> _show(Element el, Map<String, dynamic> data) async {
    if (_ctx?.mounted != true) {
      _busy = false;
      return;
    }
    try {
      final rb = el.renderObject as RenderBox?;
      if (rb == null || !rb.hasSize) {
        _busy = false;
        return;
      }
      final position = rb.localToGlobal(Offset.zero);
      final size = rb.size;
      final screen = MediaQuery.of(_ctx!).size;
      _insert(data: data, position: position, size: size, screen: screen);
    } catch (e) {
      debugPrint('[TooltipManager] show error: $e');
      _busy = false;
    }
  }

  static void _insert({
    required Map<String, dynamic> data,
    required Offset position,
    required Size size,
    required Size screen,
  }) {
    final styling = _map(data['styling']);
    final type = (data['type'] as String?)?.toLowerCase() ?? 'image';
    final appearance = _map(styling['appearance']);
    final highlight = _map(appearance['highlight']);
    final arrowStyle = _map(appearance['arrowStyle']);
    final colors = _map(appearance['colors']);
    final cornerRadius = _map(appearance['cornerRadius']);
    final imgDims = _map(appearance['imageDimensions']);

    final hRadius = _d(highlight['radius'], 12);
    final hPad = _d(highlight['padding'], 8);
    final arrowH = _d(arrowStyle['height'], 8);
    final arrowW = _d(arrowStyle['width'], 16);
    final cr = _d(cornerRadius['topLeft'] ?? cornerRadius['topRight'], 10);
    final bgColor = _color(colors['tooltip'] as String?, fallback: Colors.white);
    final bdOpacity = _d(appearance['backdropOpacity'], 50) / 100;
    final bdEnabled = data['enableBackdrop'] as bool? ?? true;
    final arrowColor = _color(colors['arrow'] as String?, fallback: bgColor);
    final bdColor = _color(colors['backdrop'] as String?, fallback: Colors.black)
        .withValues(alpha: bdOpacity);

    final isText = type == 'text';
    final tw = isText ? 260.0 : _d(imgDims['width'], 280);
    final double? th = imgDims['height'] != null
        ? _d(imgDims['height'], 200)
        : isText
            ? null
            : 200.0;

    final elementArrowGap = 5.0;
    final cx = position.dx + size.width / 2;
    final tx = (cx - tw / 2).clamp(12.0, screen.width - tw - 12);
    final estimatedTh = th ?? 120.0;

    final spaceBelow = screen.height - (position.dy + size.height);
    final spaceAbove = position.dy;
    final below = spaceBelow >= estimatedTh + arrowH + elementArrowGap || spaceBelow > spaceAbove;

    final tooltipY = below
        ? position.dy + size.height + elementArrowGap + arrowH
        : position.dy - elementArrowGap - arrowH - estimatedTh;
    final arrowY = below
        ? position.dy + size.height + elementArrowGap
        : position.dy - elementArrowGap - arrowH;

    _trackEvent?.call(
      'viewed',
      campaignId: _campaignId,
      metadata: {'tooltip_id': data['_id'] ?? data['id'] ?? ''},
    );

    void onTap() {
      _trackEvent?.call(
        'clicked',
        campaignId: _campaignId,
        metadata: {'tooltip_id': data['_id'] ?? data['id'] ?? ''},
      );
      _advance();
    }

    _overlay = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (bdEnabled)
              GestureDetector(
                onTap: _advance,
                child: CustomPaint(
                  size: screen,
                  painter: _BackdropPainter(
                    rect: Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
                    radius: hRadius,
                    padding: hPad,
                    color: bdColor,
                  ),
                ),
              ),
            // Arrow
            Positioned(
              left: tx + tw / 2 - arrowW / 2,
              top: arrowY,
              child: CustomPaint(
                size: Size(arrowW, arrowH),
                painter: _ArrowPainter(up: below, color: arrowColor),
              ),
            ),
            // Tooltip card
            Positioned(
              left: tx,
              top: tooltipY,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: tw,
                  height: th,
                  decoration: BoxDecoration(
                    color: isText ? bgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(cr),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cr),
                    child: isText
                        ? _TextContent(data: data, styling: styling, onTap: onTap)
                        : _ImageContent(url: data['url'] as String? ?? ''),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_ctx?.mounted == true) {
      Overlay.of(_ctx!).insert(_overlay!);
    }
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  static double _d(dynamic v, num fb) {
    if (v == null) return fb.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb.toDouble();
    return fb.toDouble();
  }

  static Color _color(String? hex, {Color fallback = Colors.white}) {
    if (hex == null || hex.isEmpty) return fallback;
    final c = hex.replaceAll('#', '').trim();
    const named = {
      'blue': Color(0xFF2196F3),
      'red': Color(0xFFF44336),
      'green': Color(0xFF4CAF50),
      'white': Color(0xFFFFFFFF),
      'black': Color(0xFF000000),
      'orange': Color(0xFFFF9800),
      'grey': Color(0xFF9E9E9E),
      'gray': Color(0xFF9E9E9E),
    };
    if (named.containsKey(c.toLowerCase())) return named[c.toLowerCase()]!;
    final v = int.tryParse(c.length == 6 ? 'FF$c' : c, radix: 16);
    return v != null ? Color(v) : fallback;
  }

  static TextAlign _textAlign(String? v) {
    switch (v?.toLowerCase()) {
      case 'left':
      case 'start': return TextAlign.start;
      case 'right':
      case 'end': return TextAlign.end;
      case 'justify': return TextAlign.justify;
      default: return TextAlign.center;
    }
  }

  static Alignment _ctaAlignment(String? v) {
    switch (v?.toLowerCase()) {
      case 'start':
      case 'left': return Alignment.centerLeft;
      case 'end':
      case 'right': return Alignment.centerRight;
      default: return Alignment.center;
    }
  }
}

// ─── Text tooltip content ─────────────────────────────────────────────────────

class _TextContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> styling;
  final VoidCallback onTap;

  const _TextContent({
    required this.data,
    required this.styling,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleMap = TooltipManager._map(styling['title']);
    final subMap = TooltipManager._map(styling['subTitle']);
    final ctaMap = TooltipManager._map(styling['cta']);
    final appearance = TooltipManager._map(styling['appearance']);
    final paddingMap = TooltipManager._map(appearance['padding']);
    final ctaContainer = TooltipManager._map(ctaMap['container']);
    final ctaCornerMap = TooltipManager._map(ctaMap['cornerRadius']);
    final ctaTextMap = TooltipManager._map(ctaMap['text']);

    final titleText = data['titleText'] as String? ?? '';
    final subText = data['subtitleText'] as String? ?? '';
    final ctaText = data['ctaText'] as String? ?? 'Got it';

    final outerPad = EdgeInsets.fromLTRB(
      TooltipManager._d(paddingMap['left'], 16),
      TooltipManager._d(paddingMap['top'], 12),
      TooltipManager._d(paddingMap['right'], 16),
      TooltipManager._d(paddingMap['bottom'], 12),
    );

    final ctaBg = TooltipManager._color(ctaContainer['backgroundColor'] as String?, fallback: const Color(0xFF1A73E8));
    final ctaFg = TooltipManager._color(ctaTextMap['color'] as String?, fallback: Colors.white);
    final ctaBorderColor = TooltipManager._color(ctaContainer['borderColor'] as String?, fallback: Colors.transparent);
    final ctaBorderWidth = TooltipManager._d(ctaContainer['borderWidth'], 0);
    final ctaRadius = BorderRadius.only(
      topLeft: Radius.circular(TooltipManager._d(ctaCornerMap['topLeft'], 8)),
      topRight: Radius.circular(TooltipManager._d(ctaCornerMap['topRight'], 8)),
      bottomLeft: Radius.circular(TooltipManager._d(ctaCornerMap['bottomLeft'], 8)),
      bottomRight: Radius.circular(TooltipManager._d(ctaCornerMap['bottomRight'], 8)),
    );
    final ctaFullWidth = ctaContainer['ctaFullWidth'] == true;
    final ctaHeight = ctaContainer['height'] != null ? TooltipManager._d(ctaContainer['height'], 36) : null;
    final ctaWidth = ctaContainer['ctaWidth'] != null ? TooltipManager._d(ctaContainer['ctaWidth'], 0) : null;
    final ctaAlign = TooltipManager._ctaAlignment(ctaContainer['alignment'] as String?);
    final ctaFontSize = TooltipManager._d(ctaTextMap['fontSize'], 13);

    final titleMarginMap = TooltipManager._map(titleMap['margin']);
    final subMarginMap = TooltipManager._map(subMap['margin']);
    final ctaMarginMap = TooltipManager._map(ctaMap['margin']);

    return Padding(
      padding: outerPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleText.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                TooltipManager._d(titleMarginMap['left'], 0),
                TooltipManager._d(titleMarginMap['top'], 0),
                TooltipManager._d(titleMarginMap['right'], 0),
                TooltipManager._d(titleMarginMap['bottom'], 0),
              ),
              child: Text(
                titleText,
                textAlign: TooltipManager._textAlign(titleMap['textAlign'] as String?),
                style: TextStyle(
                  color: TooltipManager._color(titleMap['color'] as String?),
                  fontSize: TooltipManager._d(titleMap['fontSize'], 14),
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          if (subText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.fromLTRB(
                TooltipManager._d(subMarginMap['left'], 0),
                TooltipManager._d(subMarginMap['top'], 0),
                TooltipManager._d(subMarginMap['right'], 0),
                TooltipManager._d(subMarginMap['bottom'], 0),
              ),
              child: Text(
                subText,
                textAlign: TooltipManager._textAlign(subMap['textAlign'] as String?),
                style: TextStyle(
                  color: TooltipManager._color(subMap['color'] as String?, fallback: Colors.black54),
                  fontSize: TooltipManager._d(subMap['fontSize'], 12),
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (ctaText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.fromLTRB(
                TooltipManager._d(ctaMarginMap['left'], 0),
                TooltipManager._d(ctaMarginMap['top'], 0),
                TooltipManager._d(ctaMarginMap['right'], 0),
                TooltipManager._d(ctaMarginMap['bottom'], 0),
              ),
              child: Align(
                alignment: ctaAlign,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: ctaFullWidth ? double.infinity : ctaWidth,
                    height: ctaHeight,
                    decoration: BoxDecoration(
                      color: ctaBg,
                      borderRadius: ctaRadius,
                      border: ctaBorderWidth > 0
                          ? Border.all(color: ctaBorderColor, width: ctaBorderWidth)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      ctaText,
                      style: TextStyle(
                        color: ctaFg,
                        fontSize: ctaFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Image tooltip content ────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final String url;
  const _ImageContent({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _BackdropPainter extends CustomPainter {
  final Rect rect;
  final double radius;
  final double padding;
  final Color color;

  const _BackdropPainter({
    required this.rect,
    required this.radius,
    required this.padding,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(
          rect.left - padding,
          rect.top - padding,
          rect.right + padding,
          rect.bottom + padding,
        ),
        Radius.circular(radius),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.color != color || old.rect != rect;
}

class _ArrowPainter extends CustomPainter {
  final bool up;
  final Color color;

  const _ArrowPainter({required this.up, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final path = Path();
    if (up) {
      path
        ..moveTo(cx - size.width / 2, size.height)
        ..lineTo(cx, 0)
        ..lineTo(cx + size.width / 2, size.height);
    } else {
      path
        ..moveTo(cx - size.width / 2, 0)
        ..lineTo(cx, size.height)
        ..lineTo(cx + size.width / 2, 0);
    }
    canvas.drawPath(
      path..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.up != up;
}
