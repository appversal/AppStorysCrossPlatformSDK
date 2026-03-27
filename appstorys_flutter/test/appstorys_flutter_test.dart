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
  Future<String> getBannerJson() async => '[{"id":"banner-1"}]';

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
    final bannerJson = await plugin.getBannerJson();
    await plugin.trackEvent(
      event: 'clicked',
      campaignId: 'cmp-1',
      metadata: <String, Object?>{'source': 'flutter'},
    );
    await plugin.setUserId(userId: 'user-2');
    await plugin.setUserProperties(attributes: <String, Object?>{'tier': 'gold', 'age': 2});

    expect(fakePlatform.initializeCalled, isTrue);
    expect(fakePlatform.getScreenCampaignsCalled, isTrue);
    expect(fakePlatform.trackEventCalled, isTrue);
    expect(fakePlatform.setUserIdCalled, isTrue);
    expect(fakePlatform.setUserPropertiesCalled, isTrue);
    expect(bannerJson, '[{"id":"banner-1"}]');
  });

  test('getBannerCampaigns parses typed list', () async {
    final plugin = AppstorysFlutter();
    final fakePlatform = MockAppstorysFlutterPlatform();
    AppstorysFlutterPlatform.instance = fakePlatform;

    final campaigns = await plugin.getBannerCampaigns();

    expect(campaigns.length, 1);
    expect(campaigns.first.id, 'banner-1');
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
