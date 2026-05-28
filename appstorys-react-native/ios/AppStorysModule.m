#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// Base class is RCTEventEmitter so the module can emit "onCampaignsUpdate" events.
// addListener / removeListeners are inherited — no extern declaration needed.
RCT_EXTERN_MODULE(AppStorysReactNative, RCTEventEmitter)

RCT_EXTERN_METHOD(initialize:(NSString *)appId accountId:(NSString *)accountId userId:(NSString *)userId
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getScreenCampaigns:(NSString *)screenName
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getCampaignsJson:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getCampaignsByTypeJson:(NSString *)type
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getPersonalizationDataJson:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getUserId:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(isReady:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(trackEvent:(NSString *)campaignId event:(NSString *)event metadata:(NSDictionary *)metadata
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(setUserId:(NSString *)userId
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(setUserProperties:(NSDictionary *)attributes
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(dismissCampaign:(NSString *)campaignId
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(captureCsatResponse:(NSString *)csatId userId:(NSString *)userId rating:(double)rating
                  feedbackOption:(NSString *)feedbackOption additionalComments:(NSString *)additionalComments
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(captureSurveyResponse:(NSString *)surveyId userId:(NSString *)userId
                  responseOptions:(NSArray *)responseOptions comment:(NSString *)comment
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(sendReelLikeStatus:(NSString *)campaignId userId:(NSString *)userId isLiked:(BOOL)isLiked
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(personalizeText:(NSString *)text
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(identifyElements:(NSString *)screenName childrenJson:(NSString *)childrenJson screenshotPath:(NSString *)screenshotPath
                  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

@end
