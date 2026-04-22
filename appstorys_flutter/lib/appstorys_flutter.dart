import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'appstorys_flutter_platform_interface.dart';
import 'src/appstorys_api_models.dart';
import 'src/widgets/capture_manager.dart';
import 'src/widgets/tooltip_manager.dart';

export 'src/appstorys_api_models.dart';
export 'src/models/banner_models.dart';
export 'src/models/floater_models.dart';
export 'src/widgets/app_storys_banner.dart';
export 'src/widgets/app_storys_floater.dart';
export 'src/utils/common_widgets.dart';
export 'src/utils/campaigns_stream_mixin.dart';
export 'src/widgets/tooltip_manager.dart' show TooltipManager;
export 'src/widgets/capture_manager.dart' show CaptureManager;

// This is the public API that Flutter developers actually use.
// It validates and sanitizes inputs before delegating to the platform interface.
class AppstorysFlutter {
  // Cached broadcast stream — ensures a single native EventChannel listener is
  // created regardless of how many widgets subscribe to campaignsStream.
  // Each AppstorysFlutter instance has its own cache; share one instance app-wide.
  Stream<String>? _campaignsStreamCache;

  /// A broadcast stream that emits the full campaigns JSON string whenever
  /// AppStorysCore's internal StateFlow updates (i.e. when getScreenCampaigns()
  /// completes a CDN fetch). Emits '[]' when no campaigns are loaded.
  ///
  /// StateFlow semantics: the current value is replayed immediately to every new
  /// subscriber, so widgets always receive data even if getScreenCampaigns() was
  /// called before they were built.
  ///
  /// Multiple widgets can subscribe without creating duplicate native listeners
  /// because the stream is cached and converted to a broadcast stream once.
  Stream<String> get campaignsStream {
    _campaignsStreamCache ??=
        AppstorysFlutterPlatform.instance.campaignsStream.asBroadcastStream();
    return _campaignsStreamCache!;
  }

  /// Parsed convenience stream. Emits a list of campaign maps on every update.
  /// Filter by `campaign_type` to get specific campaign types.
  Stream<List<Map<String, Object?>>> get campaignsUpdates {
    return campaignsStream.map((json) {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    });
  }

  Future<void> initialize({
    required String appId,
    required String accountId,
    String? userId,
  }) {
    // Throws if appId is empty/blank.
    _requireNonBlank(appId, 'appId');
    // Throws if accountId is empty/blank.
    _requireNonBlank(accountId, 'accountId');
    // Optional userId validation — only validates if provided.
    if (userId != null && userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'userId cannot be blank.');
    }

    // Delegates to platform interface after validation.
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
    // Validates screen name before delegating.
    _requireNonBlank(screenName, 'screenName');
    // Sanitizes position list — removes blank entries.
    final sanitizedPositionList =
        positionList.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    // Delegates to platform interface with sanitized input.
    return AppstorysFlutterPlatform.instance.getScreenCampaigns(
      screenName: screenName.trim(),
      positionList: sanitizedPositionList,
    );
  }

  // Raw JSON string — lower level, rarely used directly.
  Future<String> getBannerJson() {
    return AppstorysFlutterPlatform.instance.getBannerJson();
  }

  // Parsed version — decodes JSON and returns typed banner campaign objects.
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
    // Validates event name before sending it to native code.
    _requireNonBlank(event, 'event');
    // campaignId optional — validates only if provided.
    if (campaignId != null && campaignId.trim().isEmpty) {
      throw ArgumentError.value(
        campaignId,
        'campaignId',
        'campaignId cannot be blank when provided.',
      );
    }
    // Validates metadata types.
    _validateMetadata(metadata);

    // Delegates to platform interface after validation.
    return AppstorysFlutterPlatform.instance.trackEvent(
      event: event.trim(),
      campaignId: campaignId?.trim(),
      metadata: metadata,
    );
  }

  // Raw JSON — for custom parsing.
  Future<String> getCampaignsJson() {
    return AppstorysFlutterPlatform.instance.getCampaignsJson();
  }

  // Parsed — returns a list of campaign maps ready to use.
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

  // Parsed personalization map — used to personalize app UI.
  Future<Map<String, Object?>> getPersonalizationData() async {
    final personalizationJson = await getPersonalizationDataJson();
    final decoded = jsonDecode(personalizationJson);
    if (decoded is! Map) {
      throw const FormatException('Expected personalization payload to be a JSON map.');
    }

    return decoded.map((key, value) => MapEntry('$key', value));
  }

  Future<void> setUserId({required String userId}) {
    // Validates userId before delegating.
    _requireNonBlank(userId, 'userId');
    return AppstorysFlutterPlatform.instance.setUserId(userId: userId.trim());
  }

  Future<void> setUserProperties({required Map<String, Object?> attributes}) {
    // attributes must not be empty.
    if (attributes.isEmpty) {
      throw ArgumentError.value(attributes, 'attributes', 'attributes cannot be empty.');
    }

    // Validates metadata-like values before delegating.
    _validateMetadata(attributes);
    return AppstorysFlutterPlatform.instance.setUserProperties(attributes: attributes);
  }

  // Validates string is not blank — throws ArgumentError if it is.
  void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, '$name cannot be blank.');
    }
  }

  // Validates metadata values are only supported types.
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

  // Recursively checks if a value is a supported metadata type.
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

  Future<String> personalizeText(String text) {
    // Personalizes text using the shared platform implementation.
    return AppstorysFlutterPlatform.instance.personalizeText(text);
  }

  /// Dismisses a campaign client-side. Adds [campaignId] to the disabled set in
  /// shared-core — the campaign will no longer be returned by filtered campaign calls
  /// for the remainder of the session.
  Future<void> dismissCampaign(String campaignId) {
    _requireNonBlank(campaignId, 'campaignId');
    return AppstorysFlutterPlatform.instance.dismissCampaign(campaignId.trim());
  }

  /// Submits a CSAT rating response to the backend.
  ///
  /// [csatId] — the campaign ID of the CSAT campaign.
  /// [userId] — the current user's ID (pass the value from [getUserId] if not stored locally).
  /// [rating] — numeric rating value (range defined by the campaign's min/max).
  /// [feedbackOption] — optional selected feedback label.
  /// [additionalComments] — optional free-text comment from the user.
  Future<void> captureCsatResponse({
    required String csatId,
    required String userId,
    required double rating,
    String? feedbackOption,
    String? additionalComments,
  }) {
    _requireNonBlank(csatId, 'csatId');
    _requireNonBlank(userId, 'userId');
    return AppstorysFlutterPlatform.instance.captureCsatResponse(
      csatId: csatId.trim(),
      userId: userId.trim(),
      rating: rating,
      feedbackOption: feedbackOption,
      additionalComments: additionalComments,
    );
  }

  /// Submits a survey response to the backend.
  ///
  /// [surveyId] — the campaign ID of the Survey campaign.
  /// [userId] — the current user's ID.
  /// [responseOptions] — list of selected option IDs/labels (supports multi-select surveys).
  /// [comment] — optional free-text comment.
  Future<void> captureSurveyResponse({
    required String surveyId,
    required String userId,
    required List<String> responseOptions,
    String? comment,
  }) {
    _requireNonBlank(surveyId, 'surveyId');
    _requireNonBlank(userId, 'userId');
    if (responseOptions.isEmpty) {
      throw ArgumentError.value(responseOptions, 'responseOptions', 'responseOptions cannot be empty.');
    }
    return AppstorysFlutterPlatform.instance.captureSurveyResponse(
      surveyId: surveyId.trim(),
      userId: userId.trim(),
      responseOptions: responseOptions,
      comment: comment,
    );
  }

  /// Sends a like or unlike action for a Reels campaign to the backend.
  ///
  /// [campaignId] — the campaign ID of the Reels campaign.
  /// [userId] — the current user's ID.
  /// [isLiked] — true for like, false for unlike.
  Future<void> sendReelLikeStatus({
    required String campaignId,
    required String userId,
    required bool isLiked,
  }) {
    _requireNonBlank(campaignId, 'campaignId');
    _requireNonBlank(userId, 'userId');
    return AppstorysFlutterPlatform.instance.sendReelLikeStatus(
      campaignId: campaignId.trim(),
      userId: userId.trim(),
      isLiked: isLiked,
    );
  }

  /// Returns true when the SDK has finished initializing and campaigns are ready to fetch.
  /// Use this to gate calls to [getScreenCampaigns] if needed.
  Future<bool> isReady() {
    return AppstorysFlutterPlatform.instance.isReady();
  }

  /// Returns the current user ID stored by shared-core, or null if no user has been set.
  /// Useful for passing to [captureCsatResponse], [captureSurveyResponse], [sendReelLikeStatus].
  Future<String?> getUserId() {
    return AppstorysFlutterPlatform.instance.getUserId();
  }

  /// Returns a JSON string of campaigns filtered by [type] (e.g. "BAN", "CSAT", "SUR").
  /// Use campaign type codes defined in AppStorys docs.
  /// Returns '[]' if no campaigns of that type are available.
  Future<String> getCampaignsByTypeJson(String type) {
    _requireNonBlank(type, 'type');
    return AppstorysFlutterPlatform.instance.getCampaignsByTypeJson(type.trim());
  }

  // ── Tooltips ────────────────────────────────────────────────────────────────

  /// Processes a list of raw campaign maps (as returned by [getCampaigns] or
  /// the campaigns stream) and shows tooltip overlays for any TTP campaigns.
  ///
  /// Call this after [getScreenCampaigns] completes, passing the [BuildContext]
  /// of the screen that contains the tooltip target widgets. Target widgets
  /// must have a [ValueKey<String>] matching the `target` field configured in
  /// the AppStorys dashboard.
  ///
  /// Example:
  /// ```dart
  /// appstorys.campaignsStream.listen((json) {
  ///   final campaigns = (jsonDecode(json) as List)
  ///       .whereType<Map<String, Object?>>().toList();
  ///   appstorys.processTooltips(context, campaigns);
  /// });
  /// ```
  Future<void> processTooltips(
    BuildContext context,
    List<Map<String, Object?>> campaigns,
  ) {
    return TooltipManager.processTooltips(
      campaigns,
      context,
      (event, {campaignId, metadata}) => trackEvent(
        event: event,
        campaignId: campaignId,
        metadata: metadata,
      ),
    );
  }

  // ── Screen capture (test/dev tool) ──────────────────────────────────────────

  /// Enables or disables the on-screen capture button.
  /// Call with `true` in debug/test builds only.
  void enableScreenCapture(bool enabled) => CaptureManager.setEnabled(enabled);

  /// Returns a [Widget] that renders a small capture button when screen capture
  /// is enabled via [enableScreenCapture]. Place it in a [Stack] above your
  /// screen content.
  ///
  /// When tapped, it takes a screenshot of [screenContext], walks the widget
  /// tree for [ValueKey<String>] elements, and posts the layout data to
  /// AppStorys so the dashboard can map element positions to tooltip targets.
  Widget captureScreenWidget({
    required String screenName,
    required BuildContext screenContext,
  }) {
    return CaptureManager.captureButton(
      screenName: screenName,
      screenContext: screenContext,
      identifyElements: (sn, Uint8List screenshot, String childrenJson) =>
          AppstorysFlutterPlatform.instance.identifyElements(
        screenName: sn,
        screenshot: screenshot,
        childrenJson: childrenJson,
      ),
    );
  }

}

