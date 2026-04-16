import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appstorys_flutter_platform_interface.dart';
import 'src/appstorys_api_models.dart';

// This is the actual bridge to native code — implements the platform interface using Flutter's MethodChannel.
// Extends the abstract platform interface — provides real implementations
/// An implementation of [AppstorysFlutterPlatform] that uses method channels.
class MethodChannelAppstorysFlutter extends AppstorysFlutterPlatform {
  /// The method channel used to interact with the native platform.
  // The channel name must match exactly what the native side registers.
  // Android: channel = MethodChannel(binding.binaryMessenger, "appstorys_flutter")
  @visibleForTesting
  final methodChannel = const MethodChannel('appstorys_flutter');

  // EventChannel — must match the name registered in AppstorysFlutterPlugin.kt.
  // receiveBroadcastStream() creates a new native listener each time it is called,
  // so AppstorysFlutter caches the resulting Dart stream to avoid duplicate listeners.
  static const EventChannel _campaignsEventChannel =
      EventChannel('appstorys_flutter/campaigns_stream');

  @override
  Stream<String> get campaignsStream {
    // Cast is safe — native always sends a String (getCampaignsJson() return type).
    return _campaignsEventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
  }

  @override
  Future<void> initialize({
    required String appId,
    required String accountId,
    String? userId,
  }) async {
    try {
      // Calls native Android/iOS "initialize" method, passes a Map of arguments.
      // On Android this hits AppstorysFlutterPlugin.kt → handleInitialize().
      await methodChannel.invokeMethod<void>('initialize', <String, Object?>{
        'appId': appId,
        'accountId': accountId,
        'userId': userId,
      });
    } on PlatformException catch (error) {
      // Converts native PlatformException to AppstorysException.
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> getScreenCampaigns({
    required String screenName,
    List<String> positionList = const <String>[],
  }) async {
    try {
      // Calls native "getScreenCampaigns" → triggers campaign fetch in AppStorysCore.
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
      // Calls native "getBannerJson" → returns JSON string of banner campaigns.
      // Falls back to '[]' if native returns null.
      final response = await methodChannel.invokeMethod<String>('getBannerJson');
      return response ?? '[]';
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> getCampaignsJson() async {
    try {
      // Calls native "getCampaignsJson" → returns ALL campaigns as JSON string.
      final response = await methodChannel.invokeMethod<String>('getCampaignsJson');
      return response ?? '[]';
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> getPersonalizationDataJson() async {
    try {
      // Calls native "getPersonalizationDataJson" → returns personalization map as JSON.
      final response = await methodChannel.invokeMethod<String>('getPersonalizationDataJson');
      return response ?? '{}'; // Falls back to empty map.
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> setUserId({required String userId}) async {
    try {
      // Calls native "setUserId" → triggers reconcileAnonymousUser in core if was anonymous.
      await methodChannel.invokeMethod<void>('setUserId', <String, Object?>{'userId': userId});
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> setUserProperties({required Map<String, Object?> attributes}) async {
    try {
      // Calls native "setUserProperties" → sends user attributes + device info to backend.
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
      // Calls native "trackEvent" → AppStorysCore.trackEvent() → captureEvent API.
      await methodChannel.invokeMethod<void>('trackEvent', <String, Object?>{
        'event': event,
        'campaignId': campaignId,
        'metadata': metadata,
      });
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> personalizeText(String text) async {
    try {
      // Calls native "personalizeText" → AppStorysCore.personalizeText() → shared-core utils.
      // Falls back to original text if native returns null.
      final response = await methodChannel.invokeMethod<String>(
        'personalizeText',
        <String, Object?>{'text': text},
      );
      return response ?? text;
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> dismissCampaign(String campaignId) async {
    try {
      // Calls native "dismissCampaign" → AppStorysCore.disableCampaign().
      // Adds campaignId to the disabled set — widget stops rendering it.
      await methodChannel.invokeMethod<void>(
        'dismissCampaign',
        <String, Object?>{'campaignId': campaignId},
      );
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> captureCsatResponse({
    required String csatId,
    required String userId,
    required double rating,
    String? feedbackOption,
    String? additionalComments,
  }) async {
    try {
      // Calls native "captureCsatResponse" → AppStorysCore.captureCsatResponse()
      // → POSTs rating + optional feedback to the users API.
      await methodChannel.invokeMethod<void>(
        'captureCsatResponse',
        <String, Object?>{
          'csatId': csatId,
          'userId': userId,
          'rating': rating,
          'feedbackOption': feedbackOption,
          'additionalComments': additionalComments,
        },
      );
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> captureSurveyResponse({
    required String surveyId,
    required String userId,
    required List<String> responseOptions,
    String? comment,
  }) async {
    try {
      // Calls native "captureSurveyResponse" → AppStorysCore.captureSurveyResponse()
      // → POSTs selected options + optional comment to the users API.
      await methodChannel.invokeMethod<void>(
        'captureSurveyResponse',
        <String, Object?>{
          'surveyId': surveyId,
          'userId': userId,
          'responseOptions': responseOptions,
          'comment': comment,
        },
      );
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<void> sendReelLikeStatus({
    required String campaignId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      // Calls native "sendReelLikeStatus" → AppStorysCore.sendReelLikeStatus()
      // → POSTs like/unlike status to the users API.
      await methodChannel.invokeMethod<void>(
        'sendReelLikeStatus',
        <String, Object?>{
          'campaignId': campaignId,
          'userId': userId,
          'isLiked': isLiked,
        },
      );
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      // Calls native "isReady" → returns true when sdkState == Initialized.
      final response = await methodChannel.invokeMethod<bool>('isReady');
      return response ?? false;
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String?> getUserId() async {
    try {
      // Calls native "getUserId" → returns core.userId from shared-core storage.
      // Returns null if no user has been set yet.
      return methodChannel.invokeMethod<String>('getUserId');
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

  @override
  Future<String> getCampaignsByTypeJson(String type) async {
    try {
      // Calls native "getCampaignsByTypeJson" → AppStorysCore.getCampaignsByTypeJson(type).
      // Returns JSON string of campaigns filtered by campaign_type code (e.g. "BAN", "CSAT").
      final response = await methodChannel.invokeMethod<String>(
        'getCampaignsByTypeJson',
        <String, Object?>{'type': type},
      );
      return response ?? '[]';
    } on PlatformException catch (error) {
      throw AppstorysException.fromPlatformException(error);
    }
  }

}
