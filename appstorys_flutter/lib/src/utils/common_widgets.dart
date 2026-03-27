// Common utilities and widgets for AppStorys campaign rendering.

import 'package:flutter/material.dart';

/// A simple cross button typically used to dismiss overlays.
class CrossButton extends StatelessWidget {
  final VoidCallback onTap;
  final double iconSize;
  final Map<String, dynamic>? styling;

  const CrossButton({
    super.key,
    required this.onTap,
    this.iconSize = 18,
    this.styling,
  });

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return Colors.white;
    }
    try {
      final hex = colorStr.startsWith('#') ? colorStr : '#$colorStr';
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle both string colors and color object from styling
    Color bgColor = Colors.white;
    Color iconColor = Colors.black;

    if (styling != null) {
      if (styling!['backgroundColor'] != null) {
        bgColor = _parseColor(styling!['backgroundColor'] as String?);
      } else if (styling!['color'] is Map) {
        // Handle color object {cross, fill, stroke}
        final colorMap = styling!['color'] as Map<String, dynamic>;
        bgColor = _parseColor(colorMap['fill'] as String?);
        iconColor = _parseColor(colorMap['cross'] as String?);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: _parseColor(
                styling != null && styling!['color'] is Map
                    ? (styling!['color'] as Map<String, dynamic>)['stroke'] as String?
                    : null,
              ),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.close,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// Utility to check if a URL points to a Lottie animation.
bool isLottieUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return lower.endsWith('.json') || lower.endsWith('.lottie');
}

/// Utility to check if a URL points to a GIF image.
bool isGifUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.toLowerCase().endsWith('.gif');
}






