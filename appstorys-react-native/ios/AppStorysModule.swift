import Foundation
import React
#if canImport(AppStorysCore)
import AppStorysCore
#endif

@objc(AppStorysReactNative)
class AppStorysModule: RCTEventEmitter {

  #if canImport(AppStorysCore)
  private let storage = PlatformStorage()
  private lazy var core = AppStorysCore(storage: storage)
  private var campaignObserver: CampaignObserver?
  #endif

  override static func requiresMainQueueSetup() -> Bool { return false }

  override func supportedEvents() -> [String]! {
    return ["onCampaignsUpdate"]
  }

  // MARK: - Lifecycle

  override init() {
    super.init()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    #if canImport(AppStorysCore)
    campaignObserver?.cancel()
    core.destroy()
    #endif
  }

  @objc private func appWillEnterForeground() {
    #if canImport(AppStorysCore)
    core.onAppResumed()
    #endif
  }

  @objc private func appDidEnterBackground() {
    #if canImport(AppStorysCore)
    core.onAppStopped()
    #endif
  }

  // MARK: - Campaigns observer

  private func startCampaignsObserver() {
    #if canImport(AppStorysCore)
    campaignObserver?.cancel()
    campaignObserver = core.observeCampaigns { [weak self] payload in
      DispatchQueue.main.async {
        self?.sendEvent(withName: "onCampaignsUpdate", body: payload)
      }
    }
    #endif
  }

  // MARK: - Bridge methods

  @objc func initialize(_ appId: String,
                        accountId: String,
                        userId: String,
                        resolver resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let defaults = UserDefaults.standard
    defaults.set(
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
      forKey: "app_version"
    )
    defaults.set(Bundle.main.bundleIdentifier ?? "", forKey: "package_name")
    defaults.synchronize()

    core.initialize(appId: appId, accountId: accountId, userId: userId)
    startCampaignsObserver()
    #endif
    resolve(true)
  }

  @objc func getScreenCampaigns(_ screenName: String,
                                resolver resolve: @escaping RCTPromiseResolveBlock,
                                rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    core.getScreenCampaigns(screenName: screenName)
    #endif
    resolve(true)
  }

  @objc func getCampaignsJson(_ resolve: @escaping RCTPromiseResolveBlock,
                              rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    resolve(core.getCampaignsJson())
    #else
    resolve("[]")
    #endif
  }

  @objc func getCampaignsByTypeJson(_ type: String,
                                    resolver resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    resolve(core.getCampaignsByTypeJson(type: type))
    #else
    resolve("[]")
    #endif
  }

  @objc func getPersonalizationDataJson(_ resolve: @escaping RCTPromiseResolveBlock,
                                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    resolve(core.getPersonalizationDataJson())
    #else
    resolve("{}")
    #endif
  }

  @objc func getUserId(_ resolve: @escaping RCTPromiseResolveBlock,
                       rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    resolve(core.userId)
    #else
    resolve("")
    #endif
  }

  @objc func isReady(_ resolve: @escaping RCTPromiseResolveBlock,
                     rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    resolve(core.isInitialized())
    #else
    resolve(false)
    #endif
  }

  @objc func trackEvent(_ campaignId: String?,
                        event: String,
                        metadata: NSDictionary?,
                        resolver resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let meta = metadata as? [String: Any]
    core.trackEvent(campaignId: campaignId, event: event, metadata: meta)
    #endif
    resolve(true)
  }

  @objc func setUserId(_ userId: String,
                       resolver resolve: @escaping RCTPromiseResolveBlock,
                       rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    core.setUserId(newUserId: userId)
    #endif
    resolve(true)
  }

  @objc func setUserProperties(_ attributes: NSDictionary,
                               resolver resolve: @escaping RCTPromiseResolveBlock,
                               rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let map = (attributes as? [String: Any?])?.compactMapValues { $0 } ?? [:]
    core.setUserProperties(attributes: map)
    #endif
    resolve(true)
  }

  @objc func dismissCampaign(_ campaignId: String,
                             resolver resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    core.disableCampaign(campaignId: campaignId)
    #endif
    resolve(true)
  }

  @objc func captureCsatResponse(_ csatId: String,
                                 userId: String,
                                 rating: Double,
                                 feedbackOption: String?,
                                 additionalComments: String?,
                                 resolver resolve: @escaping RCTPromiseResolveBlock,
                                 rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let resolvedUserId = userId.isEmpty ? core.userId : userId
    core.captureCsatResponse(
      csatId: csatId,
      userId: resolvedUserId,
      rating: rating,
      feedbackOption: feedbackOption,
      additionalComments: additionalComments
    )
    #endif
    resolve(true)
  }

  @objc func captureSurveyResponse(_ surveyId: String,
                                   userId: String,
                                   responseOptions: NSArray,
                                   comment: String?,
                                   resolver resolve: @escaping RCTPromiseResolveBlock,
                                   rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let resolvedUserId = userId.isEmpty ? core.userId : userId
    let options = responseOptions.compactMap { $0 as? String }
    core.captureSurveyResponse(
      surveyId: surveyId,
      userId: resolvedUserId,
      responseOptions: options,
      comment: comment
    )
    #endif
    resolve(true)
  }

  @objc func sendReelLikeStatus(_ campaignId: String,
                                userId: String,
                                isLiked: Bool,
                                resolver resolve: @escaping RCTPromiseResolveBlock,
                                rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let resolvedUserId = userId.isEmpty ? core.userId : userId
    core.sendReelLikeStatus(campaignId: campaignId, userId: resolvedUserId, isLiked: isLiked)
    #endif
    resolve(true)
  }

  @objc func personalizeText(_ text: String,
                             resolver resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    resolve(core.personalizeText(text: text))
    #else
    resolve(text)
    #endif
  }

  @objc func identifyElements(_ screenName: String,
                               childrenJson: String,
                               screenshotPath: String,
                               resolver resolve: @escaping RCTPromiseResolveBlock,
                               rejecter reject: @escaping RCTPromiseRejectBlock) {
    #if canImport(AppStorysCore)
    let url = URL(fileURLWithPath: screenshotPath.hasPrefix("file://")
      ? String(screenshotPath.dropFirst(7)) : screenshotPath)
    if let data = try? Data(contentsOf: url) {
      let bytes = [UInt8](data)
      let kBytes = KotlinByteArray(size: Int32(bytes.count))
      for (i, byte) in bytes.enumerated() {
        kBytes.set(index: Int32(i), value: Int8(bitPattern: byte))
      }
      core.runTooltipIdentify(screenName: screenName, childrenJson: childrenJson, screenshotBytes: kBytes)
    }
    #endif
    resolve(true)
  }
}
