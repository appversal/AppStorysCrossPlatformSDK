import 'package:flutter/services.dart';

// Custom exception wrapping Flutter's PlatformException.
// So brand devs catch AppstorysException instead of raw PlatformException.
class AppstorysException implements Exception {
  // Error code from the native side, for example: "ERROR".
  AppstorysException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  // Human-readable message returned by the native layer.
  final String message;
  // Optional extra detail from native code.
  final Object? details;

  // Factory constructor — converts PlatformException to AppstorysException.
  factory AppstorysException.fromPlatformException(PlatformException error) {
    return AppstorysException(
      code: error.code,
      message: error.message ?? 'AppStorys native call failed',
      details: error.details,
    );
  }

  @override
  String toString() => 'AppstorysException(code: $code, message: $message)';
}

// Typed model for banner campaigns.
// Wraps raw JSON map with a typed id field for convenience.
class AppstorysBannerCampaign {
  // Creates a banner campaign from decoded JSON.
  AppstorysBannerCampaign({required this.id, required this.raw});

  // The campaign ID extracted from JSON.
  final String id;
  // Full raw JSON map for any other fields.
  final Map<String, Object?> raw;

  // Parses a JSON map into a typed banner campaign model.
  factory AppstorysBannerCampaign.fromJson(Map<String, Object?> json) {
    return AppstorysBannerCampaign(id: (json['id'] as String?) ?? '', raw: json);
  }
}

