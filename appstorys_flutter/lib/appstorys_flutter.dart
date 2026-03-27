import 'dart:convert';

import 'appstorys_flutter_platform_interface.dart';
import 'src/appstorys_api_models.dart';

export 'src/appstorys_api_models.dart';
export 'src/models/banner_models.dart';
export 'src/widgets/app_storys_banner.dart';
export 'src/utils/common_widgets.dart';

class AppstorysFlutter {
  Future<void> initialize({
    required String appId,
    required String accountId,
    String? userId,
  }) {
    _requireNonBlank(appId, 'appId');
    _requireNonBlank(accountId, 'accountId');
    if (userId != null && userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'userId cannot be blank.');
    }

    return AppstorysFlutterPlatform.instance.initialize(
      appId: appId.trim(),
      accountId: accountId.trim(),
      userId: userId?.trim(),
    );
  }

  Future<void> getScreenCampaigns({
    required String screenName,
    List<String> positionList = const <String>[],
  }) {
    _requireNonBlank(screenName, 'screenName');
    final sanitizedPositionList =
        positionList.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    return AppstorysFlutterPlatform.instance.getScreenCampaigns(
      screenName: screenName.trim(),
      positionList: sanitizedPositionList,
    );
  }

  Future<String> getBannerJson() {
    return AppstorysFlutterPlatform.instance.getBannerJson();
  }

  Future<List<AppstorysBannerCampaign>> getBannerCampaigns() async {
    final bannerJson = await getBannerJson();
    final decoded = jsonDecode(bannerJson);
    if (decoded is! List) {
      throw const FormatException('Expected banner payload to be a JSON list.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .map(AppstorysBannerCampaign.fromJson)
        .toList();
  }

  Future<void> trackEvent({
    required String event,
    String? campaignId,
    Map<String, Object?>? metadata,
  }) {
    _requireNonBlank(event, 'event');
    if (campaignId != null && campaignId.trim().isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'campaignId cannot be blank when provided.',
      );
    }
    _validateMetadata(metadata);

    return AppstorysFlutterPlatform.instance.trackEvent(
      event: event.trim(),
      campaignId: campaignId?.trim(),
      metadata: metadata,
    );
  }

  Future<String> getCampaignsJson() {
    return AppstorysFlutterPlatform.instance.getCampaignsJson();
  }

  Future<List<Map<String, Object?>>> getCampaigns() async {
    final campaignsJson = await getCampaignsJson();
    final decoded = jsonDecode(campaignsJson);
    if (decoded is! List) {
      throw const FormatException('Expected campaigns payload to be a JSON list.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  Future<String> getPersonalizationDataJson() {
    return AppstorysFlutterPlatform.instance.getPersonalizationDataJson();
  }

  Future<Map<String, Object?>> getPersonalizationData() async {
    final personalizationJson = await getPersonalizationDataJson();
    final decoded = jsonDecode(personalizationJson);
    if (decoded is! Map) {
      throw const FormatException('Expected personalization payload to be a JSON map.');
    }

    return decoded.map((key, value) => MapEntry('$key', value));
  }

  Future<void> setUserId({required String userId}) {
    _requireNonBlank(userId, 'userId');
    return AppstorysFlutterPlatform.instance.setUserId(userId: userId.trim());
  }

  Future<void> setUserProperties({required Map<String, Object?> attributes}) {
    if (attributes.isEmpty) {
      throw ArgumentError.value(attributes, 'attributes', 'attributes cannot be empty.');
    }

    _validateMetadata(attributes);
    return AppstorysFlutterPlatform.instance.setUserProperties(attributes: attributes);
  }

  void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, '$name cannot be blank.');
    }
  }

  void _validateMetadata(Map<String, Object?>? metadata) {
    if (metadata == null) {
      return;
    }

    for (final entry in metadata.entries) {
      if (entry.key.trim().isEmpty) {
        throw ArgumentError.value(entry.key, 'metadata', 'metadata key cannot be blank.');
      }
      if (!_isSupportedValue(entry.value)) {
        throw ArgumentError.value(
          entry.value,
          'metadata',
          'metadata supports only null, bool, num, String, List, and Map values.',
        );
      }
    }
  }

  bool _isSupportedValue(Object? value) {
    if (value == null || value is bool || value is num || value is String) {
      return true;
    }
    if (value is List) {
      return value.every(_isSupportedValue);
    }
    if (value is Map) {
      return value.keys.every((key) => key is String && key.trim().isNotEmpty) &&
          value.values.every(_isSupportedValue);
    }
    return false;
  }
}

