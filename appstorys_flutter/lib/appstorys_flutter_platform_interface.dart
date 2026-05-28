import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appstorys_flutter_method_channel.dart';

/// This is the abstract contract — defines what methods must exist without implementing them.
/// Extends PlatformInterface — Flutter's standard pattern for plugins that need to support multiple platforms (Android, iOS, web)
abstract class AppstorysFlutterPlatform extends PlatformInterface {
  /// Token prevents other packages from extending this class without permission
  static final Object _token = Object();

  /// Constructs a AppstorysFlutterPlatform.
  AppstorysFlutterPlatform() : super(token: _token);

  /// Default implementation points to MethodChannel (Android/iOS) Can be swapped for web or test implementations
  static AppstorysFlutterPlatform _instance = MethodChannelAppstorysFlutter();

  /// The default instance of [AppstorysFlutterPlatform] to use.
  /// Defaults to [MethodChannelAppstorysFlutter].
  /// Getter — returns current active platform implementation
  static AppstorysFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppstorysFlutterPlatform] when they register themselves.
  /// Setter — verifies token before allowing instance swap (security)
  static set instance(AppstorysFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ── Stream API ──────────────────────────────────────────────────────────────

  /// A stream that emits a campaigns JSON string whenever AppStorysCore's
  /// internal StateFlow updates. The first emission replays the current value
  /// immediately (StateFlow semantics), so subscribers always get data even
  /// if getScreenCampaigns() was called before subscribing.
  /// Emits '[]' when no campaigns are loaded. Never emits null.
  Stream<String> get campaignsStream {
    throw UnimplementedError('campaignsStream has not been implemented.');
  }

  // ── Method API ──────────────────────────────────────────────────────────────

  // Every method below just throws UnimplementedError
  // Concrete implementations (MethodChannel) must override these
  Future<void> initialize({
    required String appId,
    required String accountId,
    String? userId,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> getScreenCampaigns({
    required String screenName,
    List<String> positionList = const <String>[],
  }) {
    throw UnimplementedError('getScreenCampaigns() has not been implemented.');
  }

  Future<String> getCampaignsJson() {
    throw UnimplementedError('getCampaignsJson() has not been implemented.');
  }

  Future<String> getPersonalizationDataJson() {
    throw UnimplementedError('getPersonalizationDataJson() has not been implemented.');
  }

  Future<void> setUserId({required String userId}) {
    throw UnimplementedError('setUserId() has not been implemented.');
  }

  Future<void> setUserProperties({required Map<String, Object?> attributes}) {
    throw UnimplementedError('setUserProperties() has not been implemented.');
  }

  Future<void> trackEvent({
    required String event,
    String? campaignId,
    Map<String, Object?>? metadata,
  }) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  Future<String> personalizeText(String text) {
    throw UnimplementedError('personalizeText() has not been implemented.');
  }

  Future<void> dismissCampaign(String campaignId) {
    throw UnimplementedError('dismissCampaign() has not been implemented.');
  }

  Future<void> captureCsatResponse({
    required String csatId,
    required String userId,
    required double rating,
    String? feedbackOption,
    String? additionalComments,
  }) {
    throw UnimplementedError('captureCsatResponse() has not been implemented.');
  }

  Future<void> captureSurveyResponse({
    required String surveyId,
    required String userId,
    required List<String> responseOptions,
    String? comment,
  }) {
    throw UnimplementedError('captureSurveyResponse() has not been implemented.');
  }

  Future<void> sendReelLikeStatus({
    required String campaignId,
    required String userId,
    required bool isLiked,
  }) {
    throw UnimplementedError('sendReelLikeStatus() has not been implemented.');
  }

  Future<bool> isReady() {
    throw UnimplementedError('isReady() has not been implemented.');
  }

  Future<String?> getUserId() {
    throw UnimplementedError('getUserId() has not been implemented.');
  }

  Future<String> getCampaignsByTypeJson(String type) {
    throw UnimplementedError('getCampaignsByTypeJson() has not been implemented.');
  }

  Future<void> identifyElements({
    required String screenName,
    required Uint8List screenshot,
    required String childrenJson,
  }) {
    throw UnimplementedError('identifyElements() has not been implemented.');
  }

  Future<void> viaAppStorys(String link) {
    throw UnimplementedError('viaAppStorys() has not been implemented.');
  }
}
