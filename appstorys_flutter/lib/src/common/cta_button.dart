import 'package:flutter/material.dart';

import '../utils/font_cache.dart';

class CtaButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;

  // Direct parameter overrides
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final Color? textColor;
  final double? fontSize;
  final String? fontFamily;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final bool? fullWidth;
  final String? alignment;

  // Styling from backend JSON
  final Map<dynamic, dynamic>? styling;

  const CtaButton({
    super.key,
    required this.onTap,
    required this.text,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.margin,
    this.borderRadius,
    this.fullWidth,
    this.alignment,
    this.styling,
  });

  @override
  State<CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<CtaButton> {
  /// Holds the resolved font family name (after FontCache loads it if URL)
  String? _resolvedFontFamily;

  @override
  void initState() {
    super.initState();
    _loadFontIfNeeded();
  }

  @override
  void didUpdateWidget(CtaButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload font if fontFamily or styling changed
    final oldFont = oldWidget.fontFamily ??
        (oldWidget.styling?['text'] is Map
            ? oldWidget.styling!['text']['fontFamily']
            : null);
    final newFont = widget.fontFamily ??
        (widget.styling?['text'] is Map
            ? widget.styling!['text']['fontFamily']
            : null);
    if (oldFont != newFont) {
      _loadFontIfNeeded();
    }
  }

  /// Resolves fontFamily:
  /// - If it's a URL → download & register via FontCache, then set state
  /// - If it's a plain name → use directly
  Future<void> _loadFontIfNeeded() async {
    final textMap = widget.styling?['text'];
    final rawFont = widget.fontFamily ??
        (textMap is Map ? textMap['fontFamily'] as String? : null);

    if (rawFont == null || rawFont.trim().isEmpty) {
      if (mounted) setState(() => _resolvedFontFamily = null);
      return;
    }

    final resolved = await FontCache.resolveFontFamily(rawFont);
    if (mounted) setState(() => _resolvedFontFamily = resolved);
  }

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  static Color _parseColor(dynamic colorValue, Color defaultColor) {
    if (colorValue == null) return defaultColor;
    if (colorValue is Color) return colorValue;
    if (colorValue is String) {
      try {
        String hexColor = colorValue.replaceAll('#', '');
        if (hexColor.length == 6) {
          return Color(int.parse('FF$hexColor', radix: 16));
        } else if (hexColor.length == 8) {
          return Color(int.parse(hexColor, radix: 16));
        }
      } catch (e) {
        debugPrint('Error parsing color: $colorValue');
      }
    }
    return defaultColor;
  }

  static double _getDoubleValue(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _getBoolValue(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  // ---------------------------------------------------------------------------
  // Style resolvers
  // ---------------------------------------------------------------------------

  BorderRadius _getBorderRadius() {
    if (widget.borderRadius != null) return widget.borderRadius!;

    if (widget.styling != null) {
      var radiusMap = widget.styling!['borderRadius'] ?? widget.styling!['cornerRadius'];
      if (radiusMap is Map) {
        return BorderRadius.only(
          topLeft: Radius.circular(_getDoubleValue(radiusMap['topLeft'], 8)),
          topRight: Radius.circular(_getDoubleValue(radiusMap['topRight'], 8)),
          bottomLeft: Radius.circular(_getDoubleValue(radiusMap['bottomLeft'], 8)),
          bottomRight: Radius.circular(_getDoubleValue(radiusMap['bottomRight'], 8)),
        );
      }
    }
    return BorderRadius.circular(8);
  }

  EdgeInsets _getMargin() {
    if (widget.margin != null) return widget.margin!;

    if (widget.styling != null) {
      final marginMap = widget.styling!['margin'];
      if (marginMap is Map) {
        return EdgeInsets.fromLTRB(
          _getDoubleValue(marginMap['left'], 12),
          _getDoubleValue(marginMap['top'], 12),
          _getDoubleValue(marginMap['right'], 12),
          _getDoubleValue(marginMap['bottom'], 12),
        );
      }
    }
    return const EdgeInsets.all(12);
  }

  Map<String, dynamic> _getContainerProps() {
    Map<String, dynamic> props = {
      'width': 180.0,
      'height': 32.0,
      'backgroundColor': const Color(0xFFF97316),
      'borderColor': Colors.white,
      'borderWidth': 2.0,
      'fullWidth': false,
      'alignment': 'center',
    };

    if (widget.styling != null) {
      final containerMap = widget.styling!['container'];
      if (containerMap is Map) {
        if (containerMap['ctaWidth'] != null) {
          props['width'] = _getDoubleValue(containerMap['ctaWidth'], 180);
        }
        if (containerMap['height'] != null) {
          props['height'] = _getDoubleValue(containerMap['height'], 32);
        }
        if (containerMap['backgroundColor'] != null) {
          props['backgroundColor'] = _parseColor(
            containerMap['backgroundColor'],
            const Color(0xFFF97316),
          );
        }
        if (containerMap['borderColor'] != null) {
          props['borderColor'] = _parseColor(
            containerMap['borderColor'],
            Colors.white,
          );
        }
        if (containerMap['borderWidth'] != null) {
          props['borderWidth'] = _getDoubleValue(containerMap['borderWidth'], 2);
        }
        if (containerMap['ctaFullWidth'] != null) {
          props['fullWidth'] = _getBoolValue(containerMap['ctaFullWidth'], false);
        }
        if (containerMap['alignment'] != null) {
          props['alignment'] = containerMap['alignment'];
        }
      }
    }


    if (widget.width != null) props['width'] = widget.width!;
    if (widget.height != null) props['height'] = widget.height!;
    if (widget.backgroundColor != null) props['backgroundColor'] = widget.backgroundColor!;
    if (widget.borderColor != null) props['borderColor'] = widget.borderColor!;
    if (widget.borderWidth != null) props['borderWidth'] = widget.borderWidth!;
    if (widget.fullWidth != null) props['fullWidth'] = widget.fullWidth!;
    if (widget.alignment != null) props['alignment'] = widget.alignment!;

    return props;
  }

  Map<String, dynamic> _getTextProps() {
    Map<String, dynamic> props = {
      'color': Colors.white,
      'fontSize': 12.0,
      'isBold': false,
      'isItalic': false,
      'isUnderline': false,
    };

    if (widget.styling != null) {
      final textMap = widget.styling!['text'];
      if (textMap is Map) {
        if (textMap['color'] != null) {
          props['color'] = _parseColor(textMap['color'], Colors.white);
        }
        if (textMap['fontSize'] != null) {
          props['fontSize'] = _getDoubleValue(textMap['fontSize'], 12);
        }
        if (textMap['fontDecoration'] != null && textMap['fontDecoration'] is List) {
          final decorations = List<String>.from(textMap['fontDecoration']);
          props['isBold'] = decorations.contains('bold');
          props['isItalic'] = decorations.contains('italic');
          props['isUnderline'] = decorations.contains('underline');
        }
      }
    }


    if (widget.textColor != null) props['color'] = widget.textColor!;
    if (widget.fontSize != null) props['fontSize'] = widget.fontSize!;



    return props;
  }

  Alignment _getAlignment(String alignmentStr) {
    switch (alignmentStr.toLowerCase()) {
      case 'left':
      case 'start':
        return Alignment.centerLeft;
      case 'right':
      case 'end':
        return Alignment.centerRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  TextDecoration _getTextDecoration(bool isUnderline) {
    return isUnderline ? TextDecoration.underline : TextDecoration.none;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // If CTA is disabled from backend, render nothing
    if (widget.styling != null && widget.styling!['enabled'] == false) {
      return const SizedBox.shrink();
    }

    final containerProps = _getContainerProps();
    final textProps = _getTextProps();
    final btnBorderRadius = _getBorderRadius();
    final btnMargin = _getMargin();

    final bool isFullWidth = containerProps['fullWidth'] as bool;
    final double btnWidth = containerProps['width'] as double;
    final double btnHeight = containerProps['height'] as double;
    final Color bgColor = containerProps['backgroundColor'] as Color;
    final Color bColor = containerProps['borderColor'] as Color;
    final double bWidth = containerProps['borderWidth'] as double;
    final String alignmentStr = containerProps['alignment'] as String;

    final Color txtColor = textProps['color'] as Color;
    final double txtFontSize = textProps['fontSize'] as double;
    final bool txtIsBold = textProps['isBold'] as bool;
    final bool txtIsItalic = textProps['isItalic'] as bool;
    final bool txtIsUnderline = textProps['isUnderline'] as bool;

    final Widget button = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: isFullWidth ? double.infinity : btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: btnBorderRadius,
          border: Border.all(
            color: bColor,
            width: bWidth,
          ),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              color: txtColor,
              fontSize: txtFontSize,
              // _resolvedFontFamily is null until font loads (Flutter uses default)
              // Once loaded it re-renders with the correct font
              fontFamily: _resolvedFontFamily,
              fontWeight: txtIsBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: txtIsItalic ? FontStyle.italic : FontStyle.normal,
              decoration: _getTextDecoration(txtIsUnderline),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: btnMargin,
      child: isFullWidth
          ? button
          : Align(
        alignment: _getAlignment(alignmentStr),
        child: button,
      ),
    );
  }
}