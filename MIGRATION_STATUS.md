# Step 2.6 Migration Status: Complete Ktor ApiClient Implementation

## Summary
✅ **ApiClient (shared-core)**: All 11 endpoints fully implemented with Ktor
❌ **AppStorys.kt Integration**: NOT YET DONE - still using old Retrofit
❌ **Old Files Cleanup**: RetrofitClient, ApiService, old ApiRepository still present

## All 11 Endpoints in ApiClient ✅

### Authentication & Configuration (3)
1. ✅ `validateAccount` — gets access token + device info
2. ✅ `captureEvent` — fire-and-forget event tracking
3. ✅ `identifyPositions` — widget position tracking

### Campaign Management (3)
4. ✅ `getEligibleCampaigns` — get eligible campaigns for screen
5. ✅ `fetchCampaignsJson` — CDN fetch with ETag caching
6. ✅ `loadMissingCampaigns` — load campaigns not in CDN

### User Management (2)
7. ✅ `reconcileAnonymousUser` — merge anonymous → identified user
8. ✅ `updateUserProperties` — update user attributes

### Engagement Tracking (3)
9. ✅ `sendCSATResponse` — CSAT feedback submission
10. ✅ `sendReelLikeStatus` — reel engagement tracking
11. ⏳ `identifyTooltips` — multipart tooltip identification (fire-and-forget only)

## What's NOT Yet Done

### AppStorys Integration (CRITICAL - Causes Runtime Crash)
- [ ] Replace RetrofitClient imports with ApiClient
- [ ] Wire ApiClient into AppStorys initialization
- [ ] Update all API call sites to use ApiClient methods
- [ ] Handle missing refresh token logic (new req)

### Old Android Files (For Deletion)
- [ ] `app/appstorys/src/main/java/.../api/RetrofitClient.kt` (50 lines)
- [ ] `app/appstorys/src/main/java/.../api/ApiService.kt` (98 lines)
- [ ] Old `ApiRepository.kt` implementation (498 lines - keep only thin wrapper)
- [ ] Remove Retrofit dependency from `build.gradle.kts`

### Known Runtime Errors (From Logcat)
- App crashing because still using old ApiRepository + CampaignDetails serialization
- "Class discriminator was missing" → old CampaignDeserializer issue
- Old Retrofit logging still visible instead of Ktor logging

## Next Actions (In Order)

**URGENT - Do This First:**
1. Delete old files (RetrofitClient.kt, ApiService.kt)
2. Wire ApiClient into AppStorys.kt (replace all Retrofit imports)
3. Test app launch - should use new Ktor client instead of OkHttp

**Then:**
4. Handle refresh token rotation (if needed)
5. Test all endpoints match old behavior
6. Remove Retrofit dependencies

---

**Current Issue**: AppStorys.kt still imports and uses:
- `RetrofitClient.apiService` 
- `RetrofitClient.webSocketApiService`
- Old `ApiRepository`

This is why you see "ApiRepository" in logcat instead of "ApiClient".

**Fix**: Replace those 3 lines with single `ApiClient` instance, update all 11 call sites in AppStorys.kt.

