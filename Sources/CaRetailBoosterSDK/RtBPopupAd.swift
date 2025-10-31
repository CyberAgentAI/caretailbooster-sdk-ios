import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
public class RtBPopupAd: OverlayAd {
    public let tagGroupId: String
    public let eventName: String?
    public let options: RtBPopupOptions?
    private var callback: RtBPopupCallback

    private var viewModel: AdViewModel?
    private var isLoaded: Bool = false
    private var isUsed: Bool = false

    public init(
        tagGroupId: String,
        eventName: String? = nil,
        options: RtBPopupOptions? = nil,
        configureCallback: ((inout RtBPopupCallback) -> Void)? = nil
    ) {
        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options

        var callback = RtBPopupCallback()
        configureCallback?(&callback)
        self.callback = callback

        Log.debug("Initialized with tagGroupId: \(tagGroupId)", context: "RtBPopupAd")
    }

    public func load() async throws {
        guard let config = RetailBooster.currentConfig else {
            throw RtBError.notInitialized
        }

        guard let userId = config.userId, let crypto = config.crypto else {
            throw RtBError.userInfoNotSet
        }

        Log.info("Loading popup ad for tagGroupId: \(tagGroupId)", context: "RtBPopupAd")

        await MainActor.run {
            self.viewModel = AdViewModel(
                mediaId: config.mediaId,
                userId: userId,
                crypto: crypto,
                tagGroupId: tagGroupId,
                runMode: config.mode,
                eventName: self.eventName,
                popupCallback: self.callback,
                popupOptions: self.options
            )
        }

        await viewModel?.fetchAdsWithUIUpdate()
        isLoaded = true

        Log.info("Load completed", context: "RtBPopupAd")
    }

    public func show(from viewController: UIViewController? = nil) {
        guard !isUsed else {
            Log.info("Ad already used", context: "RtBPopupAd")
            callback.onClose?()
            return
        }

        guard isLoaded, let vm = viewModel else {
            Log.error("Ad not loaded", context: "RtBPopupAd")
            callback.onClose?()
            return
        }

        // TODO: Popup広告の表示実装
        // 現在はAdViewModelがPopup広告データを持たないため、一旦callbackのみ実行
        Log.info("Showing popup ad (not yet implemented)", context: "RtBPopupAd")

        isUsed = true
        callback.onClose?()
    }

    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

    // Test init - inject mock ViewModel
    #if DEBUG
    internal init(tagGroupId: String, eventName: String? = nil, options: RtBPopupOptions? = nil, callback: RtBPopupCallback = RtBPopupCallback(), mockViewModel: AdViewModel) {
        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options
        self.callback = callback
        self.viewModel = mockViewModel
        self.isLoaded = true
    }
    #endif
}
