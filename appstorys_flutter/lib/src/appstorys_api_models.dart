import 'package:flutter/services.dart';

class AppstorysException implements Exception {
  AppstorysException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

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

class AppstorysBannerCampaign {
  AppstorysBannerCampaign({required this.id, required this.raw});

  final String id;
  final Map<String, Object?> raw;

  factory AppstorysBannerCampaign.fromJson(Map<String, Object?> json) {
    return AppstorysBannerCampaign(id: (json['id'] as String?) ?? '', raw: json);
  }
}

