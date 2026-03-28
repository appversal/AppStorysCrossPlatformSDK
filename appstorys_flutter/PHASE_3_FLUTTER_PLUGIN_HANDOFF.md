# PHASE 3 Flutter Plugin Handoff Guide

This handoff guide is for the next developer to continue Phase 3 from the current repository state.

## Current Status (Already Done)

- [x] **Step 3.1** Plugin project exists (`appstorys_flutter/` already present).
- [x] **Step 3.2** Android bridge dependency to shared core already configured.
- [x] **Step 3.3** Android bridge methods added in `appstorys_flutter/android/src/main/kotlin/com/appversal/appstorys_flutter/AppstorysFlutterPlugin.kt` and corresponding shared-core methods wired.
- [x] **Step 3.4** iOS stub bridge present in `appstorys_flutter/ios/Classes/AppstorysFlutterPlugin.swift`.
- [x] **Step 3.5.1** Folder structure created under `appstorys_flutter/lib/src/`.

> Continue from **Step 3.5.2 onward**.

## Code reference for completed bridge steps

This section contains the concrete code blocks requested in the migration guide so the next developer can copy/check quickly.

### Step 3.3 - Android `MethodChannel` additions

File: `appstorys_flutter/android/src/main/kotlin/com/appversal/appstorys_flutter/AppstorysFlutterPlugin.kt`

Add these cases to `onMethodCall` `when (call.method)`:

```kotlin
"getUserId" -> {
    runBridgeCall(result) { core.userId }
}

"isReady" -> {
    runBridgeCall(result) { core.sdkState == AppStorysCore.SdkState.Initialized }
}

"dismissCampaign" -> {
    val campaignId = call.argument<String>("campaignId")
    if (campaignId.isNullOrBlank()) return missingArgument(result, "campaignId")
    runBridgeCall(result) {
        core.disableCampaign(campaignId)
        null
    }
}

"captureCsatResponse" -> {
    val csatId = call.argument<String>("csatId") ?: ""
    val userId = call.argument<String>("userId") ?: ""
    val rating = call.argument<Double>("rating") ?: 0.0
    val feedbackOption = call.argument<String>("feedbackOption")
    val additionalComments = call.argument<String>("additionalComments")
    runBridgeCall(result) {
        core.captureCsatResponse(csatId, userId, rating, feedbackOption, additionalComments)
        null
    }
}

"captureSurveyResponse" -> {
    val surveyId = call.argument<String>("surveyId") ?: ""
    val userId = call.argument<String>("userId") ?: ""
    val responseOptions = call.argument<List<String>>("responseOptions") ?: emptyList()
    val comment = call.argument<String>("comment")
    runBridgeCall(result) {
        core.captureSurveyResponse(surveyId, userId, responseOptions, comment)
        null
    }
}

"sendReelLikeStatus" -> {
    val campaignId = call.argument<String>("campaignId") ?: ""
    val userId = call.argument<String>("userId") ?: ""
    val isLiked = call.argument<Boolean>("isLiked") ?: false
    runBridgeCall(result) {
        core.sendReelLikeStatus(campaignId, userId, isLiked)
        null
    }
}

"getCampaignsByTypeJson" -> {
    val type = call.argument<String>("type") ?: ""
    runBridgeCall(result) { core.getCampaignsByTypeJson(type) }
}
```

File: `shared-core/src/commonMain/kotlin/com/appversal/appstorys/core/AppStorysCore.kt`

```kotlin
fun captureCsatResponse(
    csatId: String,
    userId: String,
    rating: Double,
    feedbackOption: String?,
    additionalComments: String?
) {
    scope.launch {
        apiClient.sendCsatResponse(accessToken, csatId, userId, rating, feedbackOption, additionalComments)
    }
}

fun captureSurveyResponse(
    surveyId: String,
    userId: String,
    responseOptions: List<String>,
    comment: String?
) {
    scope.launch {
        apiClient.sendSurveyResponse(accessToken, surveyId, userId, responseOptions, comment)
    }
}

fun sendReelLikeStatus(campaignId: String, userId: String, isLiked: Boolean) {
    scope.launch {
        apiClient.sendReelLikeStatus(accessToken, campaignId, userId, isLiked)
    }
}
```

File: `shared-core/src/commonMain/kotlin/com/appversal/appstorys/core/api/ApiClient.kt`

```kotlin
suspend fun sendCsatResponse(
    accessToken: String,
    csatId: String,
    userId: String,
    rating: Double,
    feedbackOption: String?,
    additionalComments: String?
) {
    try {
        client.post("$USERS_BASE/api/v1/campaigns/capture-csat-response/") {
            contentType(ContentType.Application.Json)
            header("Authorization", "Bearer $accessToken")
            setBody(buildJsonObject {
                put("csat", csatId)
                put("user_id", userId)
                put("rating", rating)
                feedbackOption?.let { put("feedback_option", it) }
                additionalComments?.let { put("additional_comments", it) }
            }.toString())
        }
    } catch (e: Exception) {
        logError("ApiClient", "sendCsatResponse failed: ${e.message}")
    }
}

suspend fun sendSurveyResponse(
    accessToken: String,
    surveyId: String,
    userId: String,
    responseOptions: List<String>,
    comment: String?
) {
    try {
        client.post("$USERS_BASE/api/v1/campaigns/capture-survey-response/") {
            contentType(ContentType.Application.Json)
            header("Authorization", "Bearer $accessToken")
            setBody(buildJsonObject {
                put("survey", surveyId)
                put("user_id", userId)
                put("responseOptions", JsonArray(responseOptions.map { JsonPrimitive(it) }))
                comment?.let { put("comment", it) }
            }.toString())
        }
    } catch (e: Exception) {
        logError("ApiClient", "sendSurveyResponse failed: ${e.message}")
    }
}

suspend fun sendReelLikeStatus(
    accessToken: String,
    campaignId: String,
    userId: String,
    isLiked: Boolean
) {
    try {
        client.post("$USERS_BASE/api/v1/campaigns/reel-like/") {
            contentType(ContentType.Application.Json)
            header("Authorization", "Bearer $accessToken")
            setBody(buildJsonObject {
                put("campaign_id", campaignId)
                put("user_id", userId)
                put("is_liked", isLiked)
            }.toString())
        }
    } catch (e: Exception) {
        logError("ApiClient", "sendReelLikeStatus failed: ${e.message}")
    }
}
```

Build and republish shared core after Step 3.3 changes:

```powershell
cd E:\AndroidStudioProjects\Office\AppStorys - Deploy\Downgraded - AppStorys_KMP_SDK\AppStorys-Android-SDK-Downgraded
.\gradlew.bat :shared-core:publishToMavenLocal
```

### Step 3.4 - iOS stub code

File: `appstorys_flutter/ios/Classes/AppstorysFlutterPlugin.swift`

```swift
import Flutter
import UIKit

public class AppStorysFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "appstorys_flutter",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppStorysFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            result(nil)
        case "getScreenCampaigns":
            result(nil)
        case "getCampaignsJson":
            result("[]")
        case "getBannerJson":
            result("[]")
        case "getPersonalizationDataJson":
            result("{}")
        case "getUserId":
            result("")
        case "isReady":
            result(false)
        case "trackEvent":
            result(nil)
        case "setUserId":
            result(nil)
        case "setUserProperties":
            result(nil)
        case "dismissCampaign":
            result(nil)
        case "captureCsatResponse":
            result(nil)
        case "captureSurveyResponse":
            result(nil)
        case "sendReelLikeStatus":
            result(nil)
        case "getCampaignsByTypeJson":
            result("[]")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

### Step 3.5.4 - `app_storys.dart` source

Use this exact replacement for `appstorys_flutter/lib/src/app_storys.dart`:

```dart
// lib/src/app_storys.dart - KMP Bridge Version
//
// This replaces the native Flutter SDK's app_storys.dart.
// Business logic (API calls, caching, filtering) is handled by KMP shared core.
// This file only handles: MethodChannel bridge calls + UI widget orchestration.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Import all widget files (same as your existing SDK exports)
import 'banner/overlay_banner.dart';
import 'floater/overlay_floater.dart';
import 'pip/pip.dart';
import 'stories/stories.dart';
import 'csat/csat.dart';
import 'survey/survey.dart';
import 'reels/reels.dart';
import 'modal/modal.dart';
import 'bottom_sheet/bottom_sheet.dart';
import 'scratch_card/scratch_card.dart';
import 'spin_wheel/spin_the_wheel.dart';
import 'widgets/widgets.dart';

enum SdkState { uninitialized, initializing, initialized, error }

class AppStorys {
  // -- Bridge to KMP shared core --
  static const _channel = MethodChannel('appstorys_flutter');

  // -- State (same ValueNotifiers as your existing SDK) --
  // UI widgets listen to these - the pattern is identical
  static final _campaigns = ValueNotifier<List<dynamic>>([]);
  static final _userId = ValueNotifier<String>('');
  static final _trackedEventNames = ValueNotifier<List<String>>([]);
  static final _disabledCampaigns = ValueNotifier<List<dynamic>>([]);
  static final _impressions = ValueNotifier<List<dynamic>>([]);
  static final _shownCampaigns = <String>{};

  static SharedPreferences? _prefs;
  static String _currentScreen = '';
  static var _state = SdkState.uninitialized;

  static Map<String, dynamic> _personalizationData = {};
  static void Function(String, Map<String, dynamic>?)? _onNavigate;

  // Public accessors (same as your existing SDK)
  static Map<String, dynamic> getPersonalizationData() => _personalizationData;
  static List<String> get trackedEventNames => _trackedEventNames.value;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize(
    String appId,
    String accountId,
    String userId, [
    void Function(String, Map<String, dynamic>?)? onNavigate,
  ]) async {
    if (_state == SdkState.initializing) return;
    _state = SdkState.initializing;

    _onNavigate = onNavigate;
    _prefs ??= await SharedPreferences.getInstance();

    try {
      await _channel.invokeMethod('initialize', {
        'appId': appId,
        'accountId': accountId,
        'userId': userId,
      });

      final resolvedUserId = await _channel.invokeMethod<String>('getUserId');
      _userId.value = resolvedUserId ?? userId;
      _state = SdkState.initialized;

      debugPrint('AppStorys KMP initialized. User: ${_userId.value}');
    } catch (e) {
      _state = SdkState.error;
      debugPrint('AppStorys initialization failed: $e');
    }
  }

  // ============================================================
  // GET SCREEN CAMPAIGNS
  // ============================================================

  static Future<void> getScreenCampaigns(
    String screenName, {
    BuildContext? context,
    List<Map<String, String>>? attributes,
  }) async {
    await ensureInitialized();

    _currentScreen = screenName;
    _shownCampaigns.clear();
    _trackedEventNames.value = [];

    try {
      // Tell KMP core to fetch campaigns
      await _channel.invokeMethod('getScreenCampaigns', {
        'screenName': screenName,
      });

      // Wait for async fetch to complete in Kotlin
      // The core does: validate -> eligible -> CDN -> filter - all async
      await Future.delayed(const Duration(milliseconds: 1500));

      // Pull campaign data from core as JSON
      final campaignsJson =
          await _channel.invokeMethod<String>('getCampaignsJson');

      if (campaignsJson != null &&
          campaignsJson.isNotEmpty &&
          campaignsJson != '[]') {
        final List<dynamic> campaigns = jsonDecode(campaignsJson);
        _campaigns.value = campaigns;
        debugPrint('Loaded ${campaigns.length} campaigns for $screenName');
      } else {
        _campaigns.value = [];
        debugPrint('No campaigns for $screenName');
      }

      // Pull personalization data
      final personalizationJson =
          await _channel.invokeMethod<String>('getPersonalizationDataJson');
      if (personalizationJson != null && personalizationJson.isNotEmpty) {
        _personalizationData =
            Map<String, dynamic>.from(jsonDecode(personalizationJson));
      }
    } catch (e) {
      debugPrint('Error getting campaigns for $screenName: $e');
      _campaigns.value = [];
    }
  }

  // ============================================================
  // REFRESH CAMPAIGNS (same pattern as your existing SDK)
  // ============================================================

  static Future<void> refreshCampaigns() async {
    if (_currentScreen.isNotEmpty) {
      await getScreenCampaigns(_currentScreen);
    }
  }

  // ============================================================
  // TRACK EVENTS
  // ============================================================

  static Future<void> trackEvents({
    required String event,
    String? campaignId,
    Map<String, dynamic>? metadata,
  }) async {
    // Add to local tracked events for trigger matching
    if (!_isSystemEvent(event)) {
      final current = List<String>.from(_trackedEventNames.value);
      current.add(event);
      _trackedEventNames.value = current;
    }

    // Send to KMP core
    try {
      await _channel.invokeMethod('trackEvent', {
        'campaignId': campaignId,
        'event': event,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Track event error: $e');
    }
  }

  static bool _isSystemEvent(String event) {
    return const {
      'viewed',
      'clicked',
      'csat captured',
      'survey captured',
      'shared',
      'SurveySubmitted',
      'SurveyDismissed',
      'ThankYouCTAClicked'
    }.contains(event);
  }

  // ============================================================
  // USER MANAGEMENT
  // ============================================================

  static Future<void> setUserId(String newUserId) async {
    await _channel.invokeMethod('setUserId', {'userId': newUserId});
    _userId.value = newUserId;
  }

  static Future<void> setUserProperties(
      Map<String, dynamic>? attributes) async {
    await _channel.invokeMethod('setUserProperties', {
      'attributes': attributes ?? {},
    });
  }

  // ============================================================
  // CAMPAIGN DISPLAY CHECK
  // Same logic as your existing SDK - kept in Dart for responsiveness
  // ============================================================

  static bool shouldShowCampaign(Map<String, dynamic> campaign) {
    final triggerEvent = campaign['trigger_event'] as String?;
    if (triggerEvent == null || triggerEvent.isEmpty) {
      return true;
    }
    return isEventTracked(triggerEvent);
  }

  static bool isEventTracked(String eventName) {
    return _trackedEventNames.value.contains(eventName);
  }

  static void clearTrackedEvents() {
    _trackedEventNames.value = [];
  }

  // ============================================================
  // NAVIGATION (identical to your existing SDK)
  // ============================================================

  static Future<void> handleNavigation(String link) async {
    if (link.isEmpty) return;

    final isUrl = link.startsWith('http://') || link.startsWith('https://');
    if (isUrl) {
      try {
        if (!await launchUrl(Uri.parse(link),
            mode: LaunchMode.externalApplication)) {
          debugPrint('Could not launch URL: $link');
        }
      } catch (e) {
        debugPrint('Error launching URL: $link - $e');
      }
      return;
    }

    // Try "Key :{...}" deep-link format
    final colonIndex = link.indexOf(':');
    if (colonIndex > 0) {
      final key = link.substring(0, colonIndex).trim();
      final jsonPart = link.substring(colonIndex + 1).trim();
      try {
        final decoded = jsonDecode(jsonPart);
        if (decoded is Map<String, dynamic>) {
          _onNavigate?.call(key, decoded);
          return;
        }
      } catch (_) {}
    }

    // Plain screen / route name
    _onNavigate?.call(link, null);
  }

  // ============================================================
  // CSAT / SURVEY RESPONSES
  // ============================================================

  static Future<void> captureCsatResponse(
    String csatId,
    num rating, {
    String? feedbackOption,
    String? additionalComments,
  }) async {
    await _channel.invokeMethod('captureCsatResponse', {
      'csatId': csatId,
      'userId': _userId.value,
      'rating': rating.toDouble(),
      'feedbackOption': feedbackOption,
      'additionalComments': additionalComments,
    });
  }

  static Future<void> captureSurveyResponse(
    String surveyId,
    List<String> responseOptions, {
    String? comment,
  }) async {
    await _channel.invokeMethod('captureSurveyResponse', {
      'surveyId': surveyId,
      'userId': _userId.value,
      'responseOptions': responseOptions,
      'comment': comment,
    });
  }

  static Future<void> sendReelLikeStatus({
    required String campaignId,
    required bool isLiked,
  }) async {
    await _channel.invokeMethod('sendReelLikeStatus', {
      'campaignId': campaignId,
      'userId': _userId.value,
      'isLiked': isLiked,
    });
  }

  // ============================================================
  // UI BUILDER - _campaignBuilder pattern (identical to your SDK)
  // ============================================================

  static Widget _campaignBuilder(Widget Function(List<dynamic>) builder) {
    return AnimatedBuilder(
      animation: Listenable.merge([_userId, _campaigns, _trackedEventNames]),
      builder: (_, __) {
        final userId = _userId.value;
        final campaigns = _campaigns.value;
        if (campaigns.isEmpty || userId.isEmpty) {
          return const SizedBox.shrink();
        }
        return builder(campaigns);
      },
    );
  }

  // ============================================================
  // CAMPAIGN WIDGET BUILDERS
  // These are IDENTICAL to your existing Flutter SDK.
  // The widgets don't know data came from KMP instead of Dart HTTP.
  // ============================================================

  static List<Widget> overlayElements() {
    return [
      banner(),
      floater(),
      pip(),
      csat(),
      survey(),
      bottomSheets(),
      modal(),
      scratchCard(),
      spinTheWheel(),
    ];
  }

  static Widget banner() {
    return _campaignBuilder(
      (campaigns) => OverlayBanner(
        bannerDetails: campaigns
            .where((e) => e['campaign_type'] == 'BAN' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget floater() {
    return _campaignBuilder(
      (campaigns) => OverlayFloater(
        floaterDetails: campaigns
            .where((e) => e['campaign_type'] == 'FLT' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget pip() {
    return _campaignBuilder(
      (campaigns) => Pip(
        pipDetails: campaigns
            .where((e) => e['campaign_type'] == 'PIP' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget reels() {
    return _campaignBuilder(
      (campaigns) => Reels(
        campaigns: campaigns
            .where((e) => e['campaign_type'] == 'REL' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget csat() {
    return _campaignBuilder(
      (campaigns) => Csat(
        csatDetails: campaigns
            .where((e) => e['campaign_type'] == 'CSAT' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget survey() {
    return _campaignBuilder(
      (campaigns) => Survey(
        surveyDetails: campaigns
            .where((e) => e['campaign_type'] == 'SUR' && shouldShowCampaign(e))
            .toList(),
        campaignData: {},
        accessToken: '', // Not needed - KMP core handles auth
        userId: _userId.value,
      ),
    );
  }

  static Widget stories() {
    return _campaignBuilder(
      (campaigns) => Stories(
        campaigns: campaigns
            .where((e) => e['campaign_type'] == 'STR' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget widgets(
      {String? position, double leftPadding = 0, double rightPadding = 0}) {
    return _campaignBuilder(
      (campaigns) => Widgets(
        position: position,
        leftPadding: leftPadding,
        rightPadding: rightPadding,
        campaigns: campaigns
            .where((e) => e['campaign_type'] == 'WID' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget modal() {
    return ValueListenableBuilder(
      valueListenable: _campaigns,
      builder: (context, campaigns, child) {
        final modals = campaigns
            .where((item) =>
                item['campaign_type'] == 'MOD' && shouldShowCampaign(item))
            .toList();
        if (modals.isNotEmpty && _userId.value.isNotEmpty) {
          final modalId = modals.first['id']?.toString() ??
              modals.first['campaign_id']?.toString() ??
              'MOD_${modals.first.hashCode}';

          if (!_shownCampaigns.contains(modalId)) {
            _shownCampaigns.add(modalId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Modal.show(context, modals, _userId.value);
            });
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  static Widget bottomSheets() {
    return _campaignBuilder(
      (campaigns) {
        return Builder(
          builder: (context) {
            final bottomSheetCampaigns = campaigns
                .where(
                    (e) => e['campaign_type'] == 'BTS' && shouldShowCampaign(e))
                .toList();

            if (bottomSheetCampaigns.isNotEmpty) {
              final campaignId = bottomSheetCampaigns.first['id']?.toString() ??
                  bottomSheetCampaigns.first['campaign_id']?.toString() ??
                  'BTS_${bottomSheetCampaigns.first.hashCode}';

              if (!_shownCampaigns.contains(campaignId)) {
                _shownCampaigns.add(campaignId);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final campaign = bottomSheetCampaigns.first;
                  final details =
                      (campaign['details'] as Map<String, dynamic>?) ?? {};
                  details['campaign_id'] = campaign['campaign_id']?.toString() ??
                      campaign['id']?.toString() ??
                      '';
                  draggableBottomSheet(context, bottomSheetDetails: details);
                });
              }
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  static Widget scratchCard() {
    return _campaignBuilder(
      (campaigns) => ScratchCard(
        campaigns: campaigns
            .where((e) => e['campaign_type'] == 'SCRT' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  static Widget spinTheWheel() {
    return _campaignBuilder(
      (campaigns) => SpinTheWheel(
        campaigns: campaigns
            .where((e) => e['campaign_type'] == 'SPW' && shouldShowCampaign(e))
            .toList(),
      ),
    );
  }

  // ============================================================
  // UTILITY
  // ============================================================

  static Future<void> ensureInitialized() async {
    if (_state == SdkState.initialized) return;
    if (_state == SdkState.error) {
      throw Exception('AppStorys initialization failed.');
    }

    final startTime = DateTime.now();
    while (_state != SdkState.initialized) {
      if (DateTime.now().difference(startTime).inMilliseconds > 10000) {
        throw Exception('AppStorys not initialized within timeout.');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static void dispose() {
    _campaigns.dispose();
    _userId.dispose();
    _trackedEventNames.dispose();
    _disabledCampaigns.dispose();
    _impressions.dispose();
  }
}
```

---

## Step 3.5.2 - Copy UI files from existing Flutter SDK

Copy all widget files from the old Flutter SDK into this plugin.

### Required file mapping

```text
FROM (old SDK)                          -> TO (this plugin)
lib/src/banner/overlay_banner.dart      -> lib/src/banner/overlay_banner.dart
lib/src/floater/overlay_floater.dart    -> lib/src/floater/overlay_floater.dart
lib/src/pip/pip.dart                    -> lib/src/pip/pip.dart
lib/src/pip/pip_page.dart               -> lib/src/pip/pip_page.dart
lib/src/pip/video_file.dart             -> lib/src/pip/video_file.dart
lib/src/stories/stories.dart            -> lib/src/stories/stories.dart
lib/src/stories/stories_bar.dart        -> lib/src/stories/stories_bar.dart
lib/src/stories/story_screen.dart       -> lib/src/stories/story_screen.dart
lib/src/stories/progress_bar.dart       -> lib/src/stories/progress_bar.dart
lib/src/csat/csat.dart                  -> lib/src/csat/csat.dart
lib/src/survey/survey.dart              -> lib/src/survey/survey.dart
lib/src/reels/reels.dart                -> lib/src/reels/reels.dart
lib/src/reels/reels_home.dart           -> lib/src/reels/reels_home.dart
lib/src/reels/content_screen.dart       -> lib/src/reels/content_screen.dart
lib/src/modal/modal.dart                -> lib/src/modal/modal.dart
lib/src/modal/modal_fullpage.dart       -> lib/src/modal/modal_fullpage.dart
lib/src/modal/modal_with_cta.dart       -> lib/src/modal/modal_with_cta.dart
lib/src/bottom_sheet/bottom_sheet.dart  -> lib/src/bottom_sheet/bottom_sheet.dart
lib/src/scratch_card/scratch_card.dart  -> lib/src/scratch_card/scratch_card.dart
lib/src/spin_wheel/spin_the_wheel.dart  -> lib/src/spin_wheel/spin_the_wheel.dart
lib/src/widgets/widgets.dart            -> lib/src/widgets/widgets.dart
lib/src/common/cross_button.dart        -> lib/src/common/cross_button.dart
lib/src/common/cta_button.dart          -> lib/src/common/cta_button.dart
lib/src/common/share_button.dart        -> lib/src/common/share_button.dart
lib/src/common/mute_button.dart         -> lib/src/common/mute_button.dart
lib/src/common/unmute_button.dart       -> lib/src/common/unmute_button.dart
lib/src/common/maximize_button.dart     -> lib/src/common/maximize_button.dart
lib/src/common/minimize_button.dart     -> lib/src/common/minimize_button.dart
lib/src/utils/campaign_data_parser.dart -> lib/src/utils/campaign_data_parser.dart
lib/src/utils/extensions.dart           -> lib/src/utils/extensions.dart
```

### Windows PowerShell copy template

Set the old SDK path first, then copy each folder.

```powershell
$OldSdk = "E:\PATH\TO\OLD_FLUTTER_SDK"
$NewSdk = "E:\AndroidStudioProjects\Office\AppStorys - Deploy\Downgraded - AppStorys_KMP_SDK\AppStorys-Android-SDK-Downgraded\appstorys_flutter"

Copy-Item "$OldSdk\lib\src\banner\*.dart" "$NewSdk\lib\src\banner\" -Force
Copy-Item "$OldSdk\lib\src\floater\*.dart" "$NewSdk\lib\src\floater\" -Force
Copy-Item "$OldSdk\lib\src\pip\*.dart" "$NewSdk\lib\src\pip\" -Force
Copy-Item "$OldSdk\lib\src\stories\*.dart" "$NewSdk\lib\src\stories\" -Force
Copy-Item "$OldSdk\lib\src\csat\*.dart" "$NewSdk\lib\src\csat\" -Force
Copy-Item "$OldSdk\lib\src\survey\*.dart" "$NewSdk\lib\src\survey\" -Force
Copy-Item "$OldSdk\lib\src\reels\*.dart" "$NewSdk\lib\src\reels\" -Force
Copy-Item "$OldSdk\lib\src\modal\*.dart" "$NewSdk\lib\src\modal\" -Force
Copy-Item "$OldSdk\lib\src\bottom_sheet\*.dart" "$NewSdk\lib\src\bottom_sheet\" -Force
Copy-Item "$OldSdk\lib\src\scratch_card\*.dart" "$NewSdk\lib\src\scratch_card\" -Force
Copy-Item "$OldSdk\lib\src\spin_wheel\*.dart" "$NewSdk\lib\src\spin_wheel\" -Force
Copy-Item "$OldSdk\lib\src\widgets\*.dart" "$NewSdk\lib\src\widgets\" -Force
Copy-Item "$OldSdk\lib\src\common\*.dart" "$NewSdk\lib\src\common\" -Force
Copy-Item "$OldSdk\lib\src\utils\*.dart" "$NewSdk\lib\src\utils\" -Force
```

---

## Step 3.5.3 - Files you must NOT copy

Do not copy these because KMP shared core replaces this logic:

- `lib/services/api_service.dart`
- `lib/repositories/campaign_repository.dart`
- `lib/Models/api_models.dart`
- `lib/src/utils/capture_manager.dart`
- `lib/src/utils/tooltip_manager.dart`
- `lib/src/utils/pending_event_manager.dart`
- `lib/src/app_storys.dart` (this will be rewritten in Step 3.5.4)

---

## Step 3.5.4 - Rewrite `lib/src/app_storys.dart`

Replace `appstorys_flutter/lib/src/app_storys.dart` entirely with the KMP bridge version from the migration guide.

### Why this rewrite is required

- Old SDK `app_storys.dart` includes direct API/repository usage.
- In KMP architecture, business logic comes from Android/iOS bridge -> shared core.
- Dart side should orchestrate widgets and call MethodChannel methods only.

### Quick check after rewrite

Ensure these MethodChannel calls exist in `appstorys_flutter/lib/src/app_storys.dart`:

- `initialize`
- `getUserId`
- `getScreenCampaigns`
- `getCampaignsJson`
- `getPersonalizationDataJson`
- `trackEvent`
- `setUserId`
- `setUserProperties`
- `captureCsatResponse`
- `captureSurveyResponse`
- `sendReelLikeStatus`

---

## Step 3.5.5 - Update main barrel export file

Create/update the main library export file as specified by your guide.

If your project uses `appstorys_flutter/lib/appstorys_flutter.dart` as the public entrypoint, either:

1. Export all widgets from that file directly, or
2. Create `appstorys_flutter/lib/appstorys.dart` and export it from `appstorys_flutter/lib/appstorys_flutter.dart`.

Required exports list:

```dart
library appstorys;

export 'src/banner/overlay_banner.dart';
export 'src/floater/overlay_floater.dart';
export 'src/pip/pip.dart';
export 'src/stories/stories.dart';
export 'src/stories/story_screen.dart';
export 'src/csat/csat.dart';
export 'src/survey/survey.dart';
export 'src/widgets/widgets.dart';
export 'src/reels/reels.dart';
export 'src/modal/modal.dart';
export 'src/bottom_sheet/bottom_sheet.dart';
export 'src/scratch_card/scratch_card.dart';
export 'src/spin_wheel/spin_the_wheel.dart';
export 'src/app_storys.dart';
```

---

## Step 3.5.6 - Update dependencies in `pubspec.yaml`

Ensure `appstorys_flutter/pubspec.yaml` has all widget dependencies used by copied files:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.0
  url_launcher: ^6.1.0
  cached_network_image: ^3.3.0
  lottie: ^2.6.0
  video_player: ^2.7.0
  share_plus: ^7.0.0
  carousel_slider: ^4.2.1
  scratcher: ^2.5.0
```

Then fetch packages:

```powershell
cd appstorys_flutter
flutter pub get
```

---

## Step 3.5.7 - Fix imports after copying

Do a global replacement in copied files:

- Replace `package:appstorys_sdk_3_0/` -> `package:appstorys_flutter/`
- Remove imports of `api_service.dart` and `campaign_repository.dart`
- Replace old direct API calls with AppStorys bridge calls where needed:
  - `AppStorys.captureCsatResponse(...)`
  - `AppStorys.captureSurveyResponse(...)`
  - `AppStorys.sendReelLikeStatus(...)`

### PowerShell search helpers

```powershell
cd appstorys_flutter
Select-String -Path "lib\**\*.dart" -Pattern "appstorys_sdk_3_0|api_service|campaign_repository" -CaseSensitive:$false
```

---

## Step 3.6 - Run and validate on Android emulator

Use the example app to verify each campaign type end-to-end.

```powershell
cd appstorys_flutter\example
flutter pub get
flutter run
```

### Validation checklist for QA

- [ ] SDK initializes without crash
- [ ] Campaign fetch works for target screen
- [ ] Banner renders
- [ ] Floater renders
- [ ] PIP renders/plays
- [ ] Stories flow works
- [ ] CSAT submit works
- [ ] Survey submit works
- [ ] Reels shows and like status sends
- [ ] Modal and bottom sheet open once and behave correctly
- [ ] Scratch card renders/interacts
- [ ] Spin wheel renders/interacts
- [ ] `trackEvent` sends for click/view interactions

---

## Suggested completion order (for next developer)

1. Finish file copy (3.5.2)
2. Rewrite `app_storys.dart` (3.5.4)
3. Fix imports (3.5.7)
4. Update exports (3.5.5)
5. Update dependencies + `flutter pub get` (3.5.6)
6. Run tests and `flutter run` on example (3.6)

---

## Quick sanity commands

```powershell
cd appstorys_flutter
flutter analyze
flutter test
```

If analyze/test fails, fix import and missing dependency issues first; those are the most common after Step 3.5.2.



