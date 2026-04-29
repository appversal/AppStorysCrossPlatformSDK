import 'dart:typed_data';

import 'package:appstorys_flutter/appstorys_flutter.dart';
import 'package:appstorys_flutter/appstorys_flutter_method_channel.dart';
import 'package:appstorys_flutter/appstorys_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppstorysFlutterPlatform
    with MockPlatformInterfaceMixin
    implements AppstorysFlutterPlatform {
  bool initializeCalled = false;
  bool getScreenCampaignsCalled = false;
  bool trackEventCalled = false;
  bool setUserIdCalled = false;
  bool setUserPropertiesCalled = false;
  bool personalizeTextCalled = false;

  @override
  Future<void> initialize({
    required String appId,
    required String accountId,
    String? userId,
  }) async {
    initializeCalled = appId == 'app-1' && accountId == 'acc-1' && userId == 'user-1';
  }

  @override
  Future<void> getScreenCampaigns({
    required String screenName,
    List<String> positionList = const <String>[],
  }) async {
    getScreenCampaignsCalled =
        screenName == 'Home Screen' && positionList.length == 2;
  }

  @override
  Future<String> getCampaignsJson() async => '[{"id":"campaign-1"}]';

  @override
  Future<String> getPersonalizationDataJson() async => '{"first_name":"Ava"}';

  @override
  Future<void> setUserId({required String userId}) async {
    setUserIdCalled = userId == 'user-2';
  }

  @override
  Future<void> setUserProperties({required Map<String, Object?> attributes}) async {
    setUserPropertiesCalled = attributes['tier'] == 'gold' && attributes['age'] == 2;
  }

  @override
  Future<void> trackEvent({
    required String event,
    String? campaignId,
    Map<String, Object?>? metadata,
  }) async {
    trackEventCalled =
        event == 'clicked' && campaignId == 'cmp-1' && metadata?['source'] == 'flutter';
  }

  @override
  Future<String> personalizeText(String text) async {
    personalizeTextCalled = text == 'Welcome, {first_name}!';
    return 'Welcome, Ava!';
  }

  @override
  Future<void> captureCsatResponse({required String csatId, required String userId, required double rating, String? feedbackOption, String? additionalComments}) {
    // TODO: implement captureCsatResponse
    throw UnimplementedError();
  }

  @override
  Future<void> captureSurveyResponse({required String surveyId, required String userId, required List<String> responseOptions, String? comment}) {
    // TODO: implement captureSurveyResponse
    throw UnimplementedError();
  }

  @override
  Future<void> dismissCampaign(String campaignId) {
    // TODO: implement dismissCampaign
    throw UnimplementedError();
  }

  @override
  Future<String> getCampaignsByTypeJson(String type) async {
    if (type == 'BAN') {
      return '[{"id":"banner-1"}]';
    }
    return '[]';
  }

  @override
  Future<String?> getUserId() {
    // TODO: implement getUserId
    throw UnimplementedError();
  }

  @override
  Future<bool> isReady() {
    // TODO: implement isReady
    throw UnimplementedError();
  }

  @override
  Future<void> sendReelLikeStatus({required String campaignId, required String userId, required bool isLiked}) {
    // TODO: implement sendReelLikeStatus
    throw UnimplementedError();
  }

  @override
  // TODO: implement campaignsStream
  Stream<String> get campaignsStream => throw UnimplementedError();

  @override
  Future<void> identifyElements({required String screenName, required Uint8List screenshot, required String childrenJson}) {
    // TODO: implement identifyElements
    throw UnimplementedError();
  }
}

void main() {
  final initialPlatform = AppstorysFlutterPlatform.instance;

  test('$MethodChannelAppstorysFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppstorysFlutter>());
  });

  test('public API forwards to platform instance', () async {
    final plugin = AppstorysFlutter();
    final fakePlatform = MockAppstorysFlutterPlatform();
    AppstorysFlutterPlatform.instance = fakePlatform;

    await plugin.initialize(appId: 'app-1', accountId: 'acc-1', userId: 'user-1');
    await plugin.getScreenCampaigns(
      screenName: 'Home Screen',
      positionList: const <String>['top', 'mid'],
    );
    final bannerJson = await plugin.getCampaignsByTypeJson('BAN');
    await plugin.trackEvent(
      event: 'clicked',
      campaignId: 'cmp-1',
      metadata: <String, Object?>{'source': 'flutter'},
    );
    final personalizedText = await plugin.personalizeText('Welcome, {first_name}!');
    await plugin.setUserId(userId: 'user-2');
    await plugin.setUserProperties(attributes: <String, Object?>{'tier': 'gold', 'age': 2});

    expect(fakePlatform.initializeCalled, isTrue);
    expect(fakePlatform.getScreenCampaignsCalled, isTrue);
    expect(fakePlatform.trackEventCalled, isTrue);
    expect(fakePlatform.personalizeTextCalled, isTrue);
    expect(fakePlatform.setUserIdCalled, isTrue);
    expect(fakePlatform.setUserPropertiesCalled, isTrue);
    expect(bannerJson, '[{"id":"banner-1"}]');
    expect(personalizedText, 'Welcome, Ava!');
  });

  test('getCampaignsByTypeJson returns filtered payload', () async {
    final plugin = AppstorysFlutter();
    final fakePlatform = MockAppstorysFlutterPlatform();
    AppstorysFlutterPlatform.instance = fakePlatform;

    final campaignsJson = await plugin.getCampaignsByTypeJson('BAN');

    expect(campaignsJson, '[{"id":"banner-1"}]');
  });

  test('initialize throws on blank appId', () {
    final plugin = AppstorysFlutter();

    expect(
      () => plugin.initialize(appId: '   ', accountId: 'acc-1'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('trackEvent throws on unsupported metadata value', () {
    final plugin = AppstorysFlutter();

    expect(
      () => plugin.trackEvent(
        event: 'clicked',
        metadata: <String, Object?>{'bad': DateTime.now()},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('getCampaigns parses campaigns payload', () async {
    final plugin = AppstorysFlutter();
    final fakePlatform = MockAppstorysFlutterPlatform();
    AppstorysFlutterPlatform.instance = fakePlatform;

    final campaigns = await plugin.getCampaigns();

    expect(campaigns.length, 1);
    expect(campaigns.first['id'], 'campaign-1');
  });

  test('getPersonalizationData parses map payload', () async {
    final plugin = AppstorysFlutter();
    final fakePlatform = MockAppstorysFlutterPlatform();
    AppstorysFlutterPlatform.instance = fakePlatform;

    final personalizationData = await plugin.getPersonalizationData();

    expect(personalizationData['first_name'], 'Ava');
  });

  test('setUserId throws on blank userId', () {
    final plugin = AppstorysFlutter();

    expect(
      () => plugin.setUserId(userId: '  '),
      throwsA(isA<ArgumentError>()),
    );
  });
}
