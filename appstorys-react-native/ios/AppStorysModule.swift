import Foundation
import React

@objc(AppStorysReactNative)
class AppStorysModule: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { return false }

  @objc func initialize(_ appId: String,
                        accountId: String,
                        userId: String,
                        resolver resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true) // Stub
  }

  @objc func getScreenCampaigns(_ screenName: String,
                                resolver resolve: @escaping RCTPromiseResolveBlock,
                                rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func getCampaignsJson(_ resolve: @escaping RCTPromiseResolveBlock,
                              rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve("[]")
  }

  @objc func getCampaignsByTypeJson(_ type: String,
                                    resolver resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve("[]")
  }

  @objc func getPersonalizationDataJson(_ resolve: @escaping RCTPromiseResolveBlock,
                                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve("{}")
  }

  @objc func getUserId(_ resolve: @escaping RCTPromiseResolveBlock,
                       rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve("")
  }

  @objc func isReady(_ resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(false)
  }

  @objc func trackEvent(_ campaignId: String?,
                        event: String,
                        metadata: NSDictionary?,
                        resolver resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func setUserId(_ userId: String,
                       resolver resolve: @escaping RCTPromiseResolveBlock,
                       rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func setUserProperties(_ attributes: NSDictionary,
                               resolver resolve: @escaping RCTPromiseResolveBlock,
                               rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func dismissCampaign(_ campaignId: String,
                             resolver resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func captureCsatResponse(_ csatId: String,
                                 userId: String,
                                 rating: Double,
                                 feedbackOption: String?,
                                 additionalComments: String?,
                                 resolver resolve: @escaping RCTPromiseResolveBlock,
                                 rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func captureSurveyResponse(_ surveyId: String,
                                   userId: String,
                                   responseOptions: NSArray,
                                   comment: String?,
                                   resolver resolve: @escaping RCTPromiseResolveBlock,
                                   rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }

  @objc func sendReelLikeStatus(_ campaignId: String,
                                userId: String,
                                isLiked: Bool,
                                resolver resolve: @escaping RCTPromiseResolveBlock,
                                rejecter reject: @escaping RCTPromiseRejectBlock) {
    resolve(true)
  }
}

