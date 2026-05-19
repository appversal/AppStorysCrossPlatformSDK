import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mirrors Kotlin's AppStorys.clickEvent() + isValidUrl() logic.
///
/// - URLs (http/https or any scheme containing "://", e.g. myapp://) are
///   opened automatically via url_launcher — no developer handling needed.
/// - Plain screen names (no "://") are delegated to [onScreenNav] so the
///   host app can route in-app. If [onScreenNav] is null a debug warning
///   is logged and nothing happens, matching Kotlin's navigateToScreen()
///   fallback behaviour.
class LinkHandler {
  LinkHandler._();

  static Future<void> handle(String? link, void Function(String)? onScreenNav) async {
    if (link == null || link.isEmpty) return;

    if (_isUrl(link)) {
      try {
        final uri = Uri.parse(link);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          debugPrint('[LinkHandler] launchUrl returned false for: $link');
        }
      } catch (e) {
        debugPrint('[LinkHandler] failed to open URL "$link": $e');
      }
    } else {
      if (onScreenNav != null) {
        onScreenNav(link);
      } else {
        debugPrint(
          '[LinkHandler] screen navigation not handled: "$link" — pass onLinkTap to handle in-app routing',
        );
      }
    }
  }

  /// Matches Kotlin's isValidUrl():
  /// http/https web URLs and any custom scheme (e.g. myapp://, appstorys://).
  static bool _isUrl(String link) {
    if (link.contains('://')) return true;
    final uri = Uri.tryParse(link);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
