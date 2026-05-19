# AppStorys Flutter SDK

Display engagement campaigns in your Flutter app — Banners, Stories, PiP videos,
Modals, Bottom Sheets, CSAT ratings, Surveys, Scratch Cards, and Spin The Wheel.

## Installation

```yaml
dependencies:
  appstorys_flutter: ^1.0.0-alpha07
```

## Quick start

```dart
final _appstorys = AppstorysFlutter();

await _appstorys.initialize(
  appId:     'YOUR_APP_ID',
  accountId: 'YOUR_ACCOUNT_ID',
  userId:    'user_123',
);
await _appstorys.getScreenCampaigns(screenName: 'Home');
```

Add AppStorysOverlay inside a Stack on every screen.

