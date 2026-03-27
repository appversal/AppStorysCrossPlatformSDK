import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appstorys_flutter_method_channel.dart';

abstract class AppstorysFlutterPlatform extends PlatformInterface {
  /// Constructs a AppstorysFlutterPlatform.
  AppstorysFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppstorysFlutterPlatform _instance = MethodChannelAppstorysFlutter();

  /// The default instance of [AppstorysFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppstorysFlutter].
  static AppstorysFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppstorysFlutterPlatform] when
  /// they register themselves.
  static set instance(AppstorysFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

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

  Future<String> getBannerJson() {
    throw UnimplementedError('getBannerJson() has not been implemented.');
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
}
