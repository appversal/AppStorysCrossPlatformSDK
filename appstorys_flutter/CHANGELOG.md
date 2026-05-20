## 1.0.0-alpha10

- Fix: campaign now re-displays on every getScreenCampaigns call (same screen revisit)
- Bump Android shared-core to v4.0.0-alpha27

## 1.0.0-alpha09

- Fix: bump Android shared-core to v4.0.0-alpha26 to resolve PlatformStorage.initialize() compile error

## 1.0.0-alpha08

- Bump shared-core to v4.0.0-alpha26

## 1.0.0-alpha07

- iOS bridge implementation with full campaign support via Swift plugin
- Standardized link/URL handling across Android and iOS
- Refined platform initialization flow
- Capture button is now shown reactively for test users via AppStorysOverlay

## 1.0.0-alpha04

- Bump Android shared-core to v4.0.0-alpha25 (fixes spurious HTTP 400 on cold start caused by getScreenCampaigns being called with an empty screen name during initialize)

## 1.0.0-alpha03

- Bump Android shared-core to v4.0.0-alpha24 (includes coroutine cancellation fix, tooltip support, PiP and Widget campaign improvements)

## 1.0.0-alpha02

- Widen `share_plus` constraint to `>=10.0.3 <14.0.0` for compatibility with apps using share_plus 11.x/12.x/13.x

## 1.0.0-alpha01

- Spin The Wheel (STW) campaign support
- Scratch Card (SCR) campaign support
- CSAT and Survey bottom sheet campaigns
- PiP with MuteButton, UnmuteButton, MinimiseButton from shared common components
- AppStorysOverlay — single widget renders all floating campaigns

