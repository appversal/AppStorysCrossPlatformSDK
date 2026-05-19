import 'dart:convert';

import 'package:flutter/material.dart';

import 'appstorys_flutter_platform_interface.dart';
import 'src/banner/app_storys_banner.dart';
import 'src/bottom_sheet/app_storys_bottom_sheet.dart';
import 'src/csat/csat.dart';
import 'src/floater/app_storys_floater.dart';
import 'src/modal/modal.dart';
import 'src/overlay/app_storys_overlay.dart';
import 'src/pip/app_storys_pip.dart';
import 'src/scratch_card/scratch_card.dart';
import 'src/spin_wheel/spin_the_wheel.dart';
import 'src/stories/stories.dart';
import 'src/survey/survey.dart';
import 'src/tooltips/capture_manager.dart';
import 'src/widgets/app_storys_widget.dart';

// Model types — exported so developers can type-check campaign data if needed.
export 'src/appstorys_api_models.dart';
export 'src/models/banner_models.dart';
export 'src/models/bottom_sheet_models.dart';
export 'src/models/csat_models.dart';
export 'src/models/floater_models.dart';
export 'src/models/pip_models.dart';
export 'src/models/survey_models.dart';
export 'src/models/scratch_card_models.dart';
export 'src/models/spin_wheel_models.dart';
export 'src/models/widgets_models.dart';

/// This is the public API that Flutter developers actually use. It validates and sanitizes inputs before delegating to the platform interface.
class AppstorysFlutter {
  /// Cached broadcast stream — ensures a single native EventChannel listener is created regardless of how many widgets subscribe to campaignsStream.
  /// Each AppstorysFlutter instance has its own cache; share one instance app-wide.
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

    // Mirror Kotlin's core.currentScreen — track screen so capture button
    // can resolve it automatically without requiring screenName on overlayElements.
    CaptureManager.setCurrentScreen(screenName.trim());

    // Delegates to platform interface with sanitized input.
    return AppstorysFlutterPlatform.instance.getScreenCampaigns(
      screenName: screenName.trim(),
      positionList: sanitizedPositionList,
    );
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

  // ── Screen capture (test/dev tool) ──────────────────────────────────────────

  /// Enables or disables the on-screen capture button.
  /// Call with `true` in debug/test builds only.
  void enableScreenCapture(bool enabled) => CaptureManager.setEnabled(enabled);

  // ── Widget factory methods ───────────────────────────────────────────────────
  // Mirror Kotlin's AppStorys.overlayElements(), AppStorys.bannerCampaign(), etc.
  // Call as appStorys.overlayElements(...) — no need to pass the instance manually.

  Widget overlayElements({
    void Function(String link)? onLinkTap,
    double bottomPadding = 0,
    double topPadding = 0,
  }) => AppStorysOverlay(
    appStorys: this,
    onLinkTap: onLinkTap,
    bottomPadding: bottomPadding,
    topPadding: topPadding,
  );

  Widget bannerCampaign({
    void Function(String link)? onTap,
    double bottomPadding = 0,
    double height = 92,
    double width = double.infinity,
    double elevation = 0,
    EdgeInsets margin = const EdgeInsets.all(12),
    BorderRadius? borderRadius,
    VoidCallback? onDismissed,
  }) => AppStorysBanner(
    appStorys: this,
    onTap: onTap,
    bottomPadding: bottomPadding,
    height: height,
    width: width,
    elevation: elevation,
    margin: margin,
    borderRadius: borderRadius,
    onDismissed: onDismissed,
  );

  Widget floaterCampaign({
    void Function(String link)? onTap,
    double bottomPadding = 0,
  }) => AppStorysFloater(
    appStorys: this,
    onTap: onTap,
    bottomPadding: bottomPadding,
  );

  Widget pipCampaign({
    void Function(String link)? onLinkTap,
    double bottomPadding = 0,
    double topPadding = 0,
  }) => AppStorysPip(
    appStorys: this,
    onLinkTap: onLinkTap,
    bottomPadding: bottomPadding,
    topPadding: topPadding,
  );

  Widget bottomSheetCampaign({
    void Function(String link)? onLinkTap,
    double bottomPadding = 0,
  }) => AppStorysBottomSheet(
    appStorys: this,
    onLinkTap: onLinkTap,
    bottomPadding: bottomPadding,
  );

  Widget modalCampaign({
    void Function(String link)? onLinkTap,
  }) => AppStorysModal(
    appStorys: this,
    onLinkTap: onLinkTap,
  );

  Widget csatCampaign({
    void Function(String link)? onLinkTap,
  }) => AppStorysCsat(
    appStorys: this,
    onLinkTap: onLinkTap,
  );

  Widget scratchCardCampaign({
    void Function(String link)? onLinkTap,
  }) => AppStorysScratchCard(
    appStorys: this,
    onLinkTap: onLinkTap,
  );

  Widget spinWheelCampaign({
    void Function(String link)? onLinkTap,
  }) => AppStorysSpinWheel(
    appStorys: this,
    onLinkTap: onLinkTap,
  );

  Widget surveyWidget({
    void Function(String link)? onLinkTap,
  }) => AppStorysSurvey(
    appStorys: this,
    onLinkTap: onLinkTap,
  );

  Widget storiesCampaign({
    void Function(String link)? onLinkTap,
  }) => AppStorysStories(
    appStorys: this,
    onLinkTap: onLinkTap,
  );

  Widget widgetCampaign({
    String? position,
    void Function(String link)? onTap,
    Color dotSelectedColor = Colors.black,
    Color dotUnselectedColor = Colors.grey,
    Duration autoScrollInterval = const Duration(seconds: 5),
  }) => AppStorysWidget(
    appStorys: this,
    position: position,
    onTap: onTap,
    dotSelectedColor: dotSelectedColor,
    dotUnselectedColor: dotUnselectedColor,
    autoScrollInterval: autoScrollInterval,
  );

}

