import 'package:flutter/material.dart';

class CrossButton extends StatelessWidget {
  final VoidCallback onTap;
  final double? iconSize;
  final Color? fillColor;
  final Color? strokeColor;
  final Color? iconColor;
  final double? borderWidth;
  final EdgeInsets? margin;
  final Map<dynamic, dynamic>? styling;

  const CrossButton({
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


  EdgeInsets _getMargin() {

    if (margin != null) return margin!;


    if (styling != null) {
      final marginMap = styling!['margin'];
      if (marginMap is Map) {
        final top = _getDoubleValue(marginMap['top'], 0).clamp(0.0, double.maxFinite);
        final bottom = _getDoubleValue(marginMap['bottom'], 0).clamp(0.0, double.maxFinite);
        final left = _getDoubleValue(marginMap['left'], 0).clamp(0.0, double.maxFinite);
        final right = _getDoubleValue(marginMap['right'], 0).clamp(0.0, double.maxFinite);

        return EdgeInsets.fromLTRB(left, top, right, bottom);
      }
    }


    return EdgeInsets.zero;
  }

  Map<String, Color> _getColors() {
    Map<String, Color> colors = {
      'fill': Colors.transparent,
      'stroke': Colors.transparent,
      'cross': Colors.transparent,
    };

    if (styling != null) {

      final colorDefinition = styling!['colors'] ?? styling!['color'];

      if (colorDefinition is Map) {
        colors['fill'] =
            _parseColor(colorDefinition['fill'], Colors.transparent);
        colors['stroke'] =
            _parseColor(colorDefinition['stroke'], Colors.transparent);
        colors['cross'] =
            _parseColor(colorDefinition['cross'], Colors.transparent);
      }


      if (styling!['fillColor'] != null) {
        colors['fill'] = _parseColor(styling!['fillColor'], Colors.transparent);
      }
      if (styling!['strokeColor'] != null) {
        colors['stroke'] =
            _parseColor(styling!['strokeColor'], Colors.transparent);
      }
      if (styling!['iconColor'] != null) {
        colors['cross'] =
            _parseColor(styling!['iconColor'], Colors.transparent);
      }
    }


    if (fillColor != null) colors['fill'] = fillColor!;
    if (strokeColor != null) colors['stroke'] = strokeColor!;
    if (iconColor != null) colors['cross'] = iconColor!;

    return colors;
  }

  String _resolveIconPath() {

    if (styling?['image'] != null &&
        styling!['image'].toString().trim().isNotEmpty) {
      final imageUrl = styling!['image'].toString().trim();

      if (imageUrl.startsWith('http')) {
        return imageUrl; // URL handled separately below
      }
    }


    if (styling?['selectedStyle'] != null &&
        styling!['selectedStyle'].toString().isNotEmpty) {
      switch (styling!['selectedStyle']) {
        case 'cross4':
          return 'lib/assets/icons/cross.png';
        default:
          return 'lib/assets/icons/cross.png';
      }
    }


    return 'lib/assets/icons/cross.png';
  }

  Widget _buildIcon(double size, Color color) {
    final path = _resolveIconPath();


    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.close,
              size: size,
              color: color == Colors.transparent ? Colors.black : color,
            ),
          );
        },
      );
    }


    return Image.asset(
      path,
      package: 'appstorys_flutter',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color == Colors.transparent ? null : color,
      colorBlendMode: color != Colors.transparent ? BlendMode.srcIn : null,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.close,
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

        final double containerWidth = constraints.maxWidth;
        final double defaultSize = containerWidth * 0.15;

        final double size = iconSize ??
            _getDoubleValue(
              styling?['size'],
              _getDoubleValue(styling?['crossButtonSize'], defaultSize),
            );

        final colors = _getColors();
        final Color fill = colors['fill']!;
        final Color stroke = colors['stroke']!;
        final Color icon = colors['cross']!;

        final double width =
            borderWidth ?? _getDoubleValue(styling?['borderWidth'], 1);

        final buttonMargin = _getMargin();

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
                  color: fill,
                  border: Border.all(
                    color: stroke,
                    width: width,
                  ),
                ),
                child: Center(
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