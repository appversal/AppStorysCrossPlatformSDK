import 'package:flutter/material.dart';

class MaximiseButton extends StatelessWidget {
  final VoidCallback onTap;
  final double? iconSize;
  final Color? fillColor;
  final Color? strokeColor;
  final Color? iconColor;
  final double? borderWidth;
  final EdgeInsets? margin;
  final Map<dynamic, dynamic>? styling;

  const MaximiseButton({
    super.key,
    required this.onTap,
    this.iconSize,
    this.fillColor,
    this.strokeColor,
    this.iconColor,
    this.borderWidth,
    this.margin,
    this.styling,
  });

  /// Parse color from hex string or return default color
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

  static double _getDoubleValue(
      dynamic value,
      double defaultValue,
      ) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Extract margin from JSON styling or use provided margin parameter
  EdgeInsets _getMargin() {
    // Priority 1: Direct margin parameter
    if (margin != null) return margin!;

    // Priority 2: Extract from JSON styling
    if (styling != null) {
      final marginMap = styling!['margin'];
      if (marginMap is Map) {
        final top = _getDoubleValue(marginMap['top'], 0);
        final bottom = _getDoubleValue(marginMap['bottom'], 0);
        final left = _getDoubleValue(marginMap['left'], 0);
        final right = _getDoubleValue(marginMap['right'], 0);

        return EdgeInsets.fromLTRB(left, top, right, bottom);
      }
    }

    // Default: No margin
    return EdgeInsets.zero;
  }

  Map<String, Color> _getColors() {
    Map<String, Color> colors = {
      'fill': Colors.transparent,
      'stroke': Colors.transparent,
      'icon': Colors.transparent,
    };

    if (styling != null) {
      // Handle both 'colors' and 'color' keys
      final colorDefinition = styling!['colors'] ?? styling!['color'];

      if (colorDefinition is Map) {
        colors['fill'] =
            _parseColor(colorDefinition['fill'], Colors.transparent);
        colors['stroke'] =
            _parseColor(colorDefinition['stroke'], Colors.transparent);
        // Support both 'icon' and 'cross' keys for backward compatibility
        colors['icon'] = _parseColor(
            colorDefinition['icon'] ?? colorDefinition['cross'],
            Colors.transparent);
      }

      // Old format fallback
      if (styling!['fillColor'] != null) {
        colors['fill'] = _parseColor(styling!['fillColor'], Colors.transparent);
      }
      if (styling!['strokeColor'] != null) {
        colors['stroke'] =
            _parseColor(styling!['strokeColor'], Colors.transparent);
      }
      if (styling!['iconColor'] != null) {
        colors['icon'] =
            _parseColor(styling!['iconColor'], Colors.transparent);
      }
    }

    // Direct parameter override
    if (fillColor != null) colors['fill'] = fillColor!;
    if (strokeColor != null) colors['stroke'] = strokeColor!;
    if (iconColor != null) colors['icon'] = iconColor!;

    return colors;
  }

  Widget _buildIcon(double size, Color color) {
    // Always use maximize.png from local assets
    const String path = 'lib/assets/icons/maximize.png';

    return Image.asset(
      path,
      package: 'appstorys_flutter',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color != Colors.transparent ? color : null,
      colorBlendMode: color != Colors.transparent ? BlendMode.srcIn : null,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading maximize.png: $error');
        return SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.fullscreen,
            size: size,
            color: color == Colors.transparent ? Colors.black : color,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (styling != null && styling!['enabled'] == false) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate size based on container width
        // Default: 15% of container width
        final double containerWidth = constraints.maxWidth;
        final double defaultSize = containerWidth * 0.15;

        // Get size from backend styling or use default
        final double size = iconSize ??
            _getDoubleValue(
              styling?['size'],
              _getDoubleValue(styling?['maximiseButtonSize'], defaultSize),
            );

        final colors = _getColors();
        final Color fill = colors['fill']!;
        final Color stroke = colors['stroke']!;
        final Color icon = colors['icon']!;

        // Get border width from backend styling
        final double width =
            borderWidth ?? _getDoubleValue(styling?['borderWidth'], 1);

        final buttonMargin = _getMargin();

        // Circle size with padding relative to icon size
        final double circleSize = size + 4;

        return GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: buttonMargin,
            child: SizedBox(
              width: circleSize,
              height: circleSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Background color from backend
                  color: fill,
                  // Border styling from backend
                  border: Border.all(
                    color: stroke,
                    width: width,
                  ),
                ),
                child: Center(
                  // maximize.png with color applied from backend
                  child: _buildIcon(size, icon),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}