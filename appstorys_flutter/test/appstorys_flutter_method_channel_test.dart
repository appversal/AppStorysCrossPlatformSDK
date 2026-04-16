import 'package:appstorys_flutter/appstorys_flutter_method_channel.dart';
import 'package:appstorys_flutter/appstorys_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelAppstorysFlutter();
  const channel = MethodChannel('appstorys_flutter');

  MethodCall? latestCall;

  setUp(() {
    latestCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          latestCall = methodCall;
          if (methodCall.method == 'getBannerJson') {
            return '[{"id":"banner-1"}]';
          }
          if (methodCall.method == 'getCampaignsJson') {
            return '[{"id":"campaign-1"}]';
          }
          if (methodCall.method == 'getPersonalizationDataJson') {
            return '{"first_name":"Ava"}';
          }
          if (methodCall.method == 'personalizeText') {
            return 'Welcome, Ava!';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize forwards app/account/user args', () async {
    await platform.initialize(
      appId: 'app-1',
      accountId: 'acc-1',
      userId: 'user-1',
    );

    expect(latestCall?.method, 'initialize');
    expect(latestCall?.arguments, <String, Object?>{
      'appId': 'app-1',
      'accountId': 'acc-1',
      'userId': 'user-1',
    });
  });

  test('getScreenCampaigns forwards screen and positions', () async {
    await platform.getScreenCampaigns(
      screenName: 'Home Screen',
      positionList: const <String>['top', 'mid'],
    );

    expect(latestCall?.method, 'getScreenCampaigns');
    expect(latestCall?.arguments, <String, Object?>{
      'screenName': 'Home Screen',
      'positionList': const <String>['top', 'mid'],
    });
  });

  test('getBannerJson returns native payload', () async {
    final response = await platform.getBannerJson();

    expect(latestCall?.method, 'getBannerJson');
    expect(response, '[{"id":"banner-1"}]');
  });

  test('trackEvent forwards event payload', () async {
    await platform.trackEvent(
      event: 'clicked',
      campaignId: 'cmp-1',
      metadata: <String, Object?>{'source': 'flutter', 'count': 1},
    );

    expect(latestCall?.method, 'trackEvent');
    expect(latestCall?.arguments, <String, Object?>{
      'event': 'clicked',
      'campaignId': 'cmp-1',
      'metadata': <String, Object?>{'source': 'flutter', 'count': 1},
    });
  });

  test('getCampaignsJson returns native payload', () async {
    final response = await platform.getCampaignsJson();

    expect(latestCall?.method, 'getCampaignsJson');
    expect(response, '[{"id":"campaign-1"}]');
  });

  test('getPersonalizationDataJson returns native payload', () async {
    final response = await platform.getPersonalizationDataJson();

    expect(latestCall?.method, 'getPersonalizationDataJson');
    expect(response, '{"first_name":"Ava"}');
  });

  test('setUserId forwards payload', () async {
    await platform.setUserId(userId: 'user-2');

    expect(latestCall?.method, 'setUserId');
    expect(latestCall?.arguments, <String, Object?>{'userId': 'user-2'});
  });

  test('setUserProperties forwards payload', () async {
    await platform.setUserProperties(
      attributes: <String, Object?>{'tier': 'gold', 'age': 2},
    );

    expect(latestCall?.method, 'setUserProperties');
    expect(latestCall?.arguments, <String, Object?>{
      'attributes': <String, Object?>{'tier': 'gold', 'age': 2},
    });
  });

  test('personalizeText forwards payload and returns native value', () async {
    final response = await platform.personalizeText('Welcome, {first_name}!');

    expect(latestCall?.method, 'personalizeText');
    expect(latestCall?.arguments, <String, Object?>{'text': 'Welcome, {first_name}!'});
    expect(response, 'Welcome, Ava!');
  });

  test('maps native platform error to AppstorysException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'INVALID_ARGS',
            message: 'Missing required argument: appId',
          );
        });

    expect(
      () => platform.initialize(appId: 'app-1', accountId: 'acc-1'),
      throwsA(
        isA<AppstorysException>()
            .having((e) => e.code, 'code', 'INVALID_ARGS')
            .having(
              (e) => e.message,
              'message',
              'Missing required argument: appId',
            ),
      ),
    );
  });
}
