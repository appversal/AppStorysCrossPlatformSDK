import Flutter
import UIKit
import Foundation

// AppStorysCore.xcframework is built from shared-core on macOS via:
//   ./gradlew :shared-core:assembleReleaseXCFramework
// and placed at ios/Frameworks/AppStorysCore.xcframework.
// The #if canImport guard lets the plugin compile and run silently on iOS
// when the framework is absent — initialize succeeds, no campaigns load, no events fire.
#if canImport(AppStorysCore)
import AppStorysCore
#endif

public class AppstorysFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // MARK: - State

    #if canImport(AppStorysCore)
    private let platformStorage = PlatformStorage()
    private lazy var core: AppStorysCore = AppStorysCore(storage: platformStorage)
    private var campaignObserver: CampaignObserver?
    #endif

    private var eventSink: FlutterEventSink?

    // MARK: - Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AppstorysFlutterPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "appstorys_flutter",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: "appstorys_flutter/campaigns_stream",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - Method dispatch

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":                handleInitialize(call, result: result)
        case "getScreenCampaigns":        handleGetScreenCampaigns(call, result: result)
        case "getCampaignsJson":          handleGetCampaignsJson(result)
        case "getCampaignsByTypeJson":    handleGetCampaignsByTypeJson(call, result: result)
        case "getPersonalizationDataJson": handleGetPersonalizationDataJson(result)
        case "getUserId":                 handleGetUserId(result)
        case "isReady":                   handleIsReady(result)
        case "setUserId":                 handleSetUserId(call, result: result)
        case "setUserProperties":         handleSetUserProperties(call, result: result)
        case "trackEvent":                handleTrackEvent(call, result: result)
        case "dismissCampaign":           handleDismissCampaign(call, result: result)
        case "captureCsatResponse":       handleCaptureCsatResponse(call, result: result)
        case "captureSurveyResponse":     handleCaptureSurveyResponse(call, result: result)
        case "sendReelLikeStatus":        handleSendReelLikeStatus(call, result: result)
        case "personalizeText":           handlePersonalizeText(call, result: result)
        case "identifyElements":          handleIdentifyElements(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        #if canImport(AppStorysCore)
        campaignObserver?.cancel()
        campaignObserver = core.observeCampaigns { [weak self] payload in
            DispatchQueue.main.async {
                self?.eventSink?(payload)
            }
        }
        #endif
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        #if canImport(AppStorysCore)
        campaignObserver?.cancel()
        campaignObserver = nil
        #endif
        eventSink = nil
        return nil
    }

    // MARK: - initialize

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "initialize: arguments must be a map", details: nil))
            return
        }
        let appId     = args["appId"]     as? String ?? ""
        let accountId = args["accountId"] as? String ?? ""
        let rawUserId = args["userId"]    as? String
        let userId    = rawUserId ?? ""

        // Mirror Android: if no userId provided, reset stored identity to anonymous.
        if rawUserId == nil {
            platformStorage.putString(key: "appstorys_user_id", value: "")
            platformStorage.putBoolean(key: "appstorys_is_anonymous", value: true)
        }

        // Pre-populate device metadata that getDeviceInfo() reads from NSUserDefaults.
        let defaults = UserDefaults.standard
        defaults.set(
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            forKey: "app_version"
        )
        defaults.set(Bundle.main.bundleIdentifier ?? "", forKey: "package_name")
        defaults.synchronize()

        core.initialize(appId: appId, accountId: accountId, userId: userId)
        #endif
        result(nil)
    }

    // MARK: - getScreenCampaigns

    private func handleGetScreenCampaigns(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result(nil); return }
        let screenName = args["screenName"] as? String ?? ""
        let positions  = args["positionList"] as? [String] ?? []
        core.getScreenCampaigns(screenName: screenName, positionList: positions)
        #endif
        result(nil)
    }

    // MARK: - getCampaignsJson

    private func handleGetCampaignsJson(_ result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        result(core.getCampaignsJson())
        #else
        result("[]")
        #endif
    }

    // MARK: - getCampaignsByTypeJson

    private func handleGetCampaignsByTypeJson(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result("[]"); return }
        let type = args["type"] as? String ?? ""
        result(core.getCampaignsByTypeJson(type: type))
        #else
        result("[]")
        #endif
    }

    // MARK: - getPersonalizationDataJson

    private func handleGetPersonalizationDataJson(_ result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        result(core.getPersonalizationDataJson())
        #else
        result("{}")
        #endif
    }

    // MARK: - getUserId

    private func handleGetUserId(_ result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        result(core.userId)
        #else
        result("")
        #endif
    }

    // MARK: - isReady

    private func handleIsReady(_ result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        result(core.isInitialized())
        #else
        result(false)
        #endif
    }

    // MARK: - setUserId

    private func handleSetUserId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "setUserId: userId is required", details: nil))
            return
        }
        core.setUserId(newUserId: userId)
        #endif
        result(nil)
    }

    // MARK: - setUserProperties

    private func handleSetUserProperties(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any],
              let rawAttrs = args["attributes"] as? [String: Any?] else {
            result(FlutterError(code: "INVALID_ARGS", message: "setUserProperties: attributes map is required", details: nil))
            return
        }
        let attributes = rawAttrs.compactMapValues { $0 }
        core.setUserProperties(attributes: attributes)
        #endif
        result(nil)
    }

    // MARK: - trackEvent

    private func handleTrackEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any],
              let event = args["event"] as? String, !event.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "trackEvent: event is required", details: nil))
            return
        }
        let campaignId = args["campaignId"] as? String
        let rawMeta    = args["metadata"]   as? [String: Any?]
        let metadata   = rawMeta.map { $0.compactMapValues { $0 } }
        core.trackEvent(campaignId: campaignId, event: event, metadata: metadata)
        #endif
        result(nil)
    }

    // MARK: - dismissCampaign

    private func handleDismissCampaign(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any],
              let campaignId = args["campaignId"] as? String, !campaignId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "dismissCampaign: campaignId is required", details: nil))
            return
        }
        core.disableCampaign(campaignId: campaignId)
        #endif
        result(nil)
    }

    // MARK: - captureCsatResponse

    private func handleCaptureCsatResponse(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result(nil); return }
        let csatId             = args["csatId"]             as? String ?? ""
        let userId             = args["userId"]             as? String ?? ""
        let rating             = args["rating"]             as? Double ?? 0.0
        let feedbackOption     = args["feedbackOption"]     as? String
        let additionalComments = args["additionalComments"] as? String
        core.captureCsatResponse(
            csatId: csatId,
            userId: userId,
            rating: rating,
            feedbackOption: feedbackOption,
            additionalComments: additionalComments
        )
        #endif
        result(nil)
    }

    // MARK: - captureSurveyResponse

    private func handleCaptureSurveyResponse(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result(nil); return }
        let surveyId        = args["surveyId"]        as? String  ?? ""
        let userId          = args["userId"]          as? String  ?? ""
        let responseOptions = args["responseOptions"] as? [String] ?? []
        let comment         = args["comment"]         as? String
        core.captureSurveyResponse(
            surveyId: surveyId,
            userId: userId,
            responseOptions: responseOptions,
            comment: comment
        )
        #endif
        result(nil)
    }

    // MARK: - sendReelLikeStatus

    private func handleSendReelLikeStatus(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result(nil); return }
        let campaignId = args["campaignId"] as? String ?? ""
        let userId     = args["userId"]     as? String ?? ""
        let isLiked    = args["isLiked"]    as? Bool   ?? false
        core.sendReelLikeStatus(campaignId: campaignId, userId: userId, isLiked: isLiked)
        #endif
        result(nil)
    }

    // MARK: - personalizeText

    private func handlePersonalizeText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result(""); return }
        let text = args["text"] as? String ?? ""
        result(core.personalizeText(text: text))
        #else
        let text = (call.arguments as? [String: Any])?["text"] as? String ?? ""
        result(text)
        #endif
    }

    // MARK: - identifyElements (tooltip screenshot)

    private func handleIdentifyElements(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(AppStorysCore)
        guard let args = call.arguments as? [String: Any] else { result(nil); return }
        let screenName   = args["screenName"] as? String ?? ""
        let childrenJson = args["children"]   as? String ?? ""
        let screenshotData = (args["screenshot"] as? FlutterStandardTypedData)?.data ?? Data()

        let bytes = [UInt8](screenshotData)
        let kBytes = KotlinByteArray(size: Int32(bytes.count))
        for (i, byte) in bytes.enumerated() {
            kBytes.set(index: Int32(i), value: Int8(bitPattern: byte))
        }
        core.runTooltipIdentify(screenName: screenName, childrenJson: childrenJson, screenshotBytes: kBytes)
        #endif
        result(nil)
    }
}
