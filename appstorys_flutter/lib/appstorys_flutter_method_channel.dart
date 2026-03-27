import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appstorys_flutter_platform_interface.dart';
import 'src/appstorys_api_models.dart';

/// An implementation of [AppstorysFlutterPlatform] that uses method channels.
class MethodChannelAppstorysFlutter extends AppstorysFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appstorys_flutter');

  @override
  Future<void> initialize({
    required String appId,
    required String accountId,
    String? userId,
  }) async {
    try {
      await methodChannel.invokeMethod<void>('initialize', <String, Object?>{
        'appId': appId,
        'accountId': accountId,
        'userId': userId,
      });
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> getScreenCampaigns({
    required String screenName,
    List<String> positionList = const <String>[],
  }) async {
    try {
      await methodChannel.invokeMethod<void>(
        'getScreenCampaigns',
        <String, Object?>{'screenName': screenName, 'positionList': positionList},
      );
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> getBannerJson() async {
    try {
      final response = await methodChannel.invokeMethod<String>('getBannerJson');
      return response ?? '[]';
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> getCampaignsJson() async {
    try {
      final response = await methodChannel.invokeMethod<String>('getCampaignsJson');
      return response ?? '[]';
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> getPersonalizationDataJson() async {
    try {
      final response = await methodChannel.invokeMethod<String>('getPersonalizationDataJson');
      return response ?? '{}';
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> setUserId({required String userId}) async {
    try {
      await methodChannel.invokeMethod<void>('setUserId', <String, Object?>{'userId': userId});
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> setUserProperties({required Map<String, Object?> attributes}) async {
    try {
      await methodChannel.invokeMethod<void>('setUserProperties', <String, Object?>{
        'attributes': attributes,
      });
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> trackEvent({
    required String event,
    String? campaignId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      await methodChannel.invokeMethod<void>('trackEvent', <String, Object?>{
        'event': event,
        'campaignId': campaignId,
        'metadata': metadata,
      });
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }
}
