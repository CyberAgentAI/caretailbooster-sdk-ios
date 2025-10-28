import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
public class RtBPopupAd: OverlayAd {
    public let tagGroupId: String
    public let eventName: String?
    public let options: PopupOptions?
    private var callback: PopupCallback

    private var viewModel: AdViewModel?
    private var isLoaded: Bool = false
    private var isUsed: Bool = false

    public init?(
        tagGroupId: String,
        eventName: String? = nil,
        options: PopupOptions? = nil,
        configureCallback: ((inout PopupCallback) -> Void)? = nil
    ) {
        guard RetailBooster.isInitialized else {
            #if DEBUG
            print("[RtBPopupAd] Error: SDK not initialized")
            #endif
            return nil
        }

        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options

        var callback = PopupCallback()
        configureCallback?(&callback)
        self.callback = callback

        #if DEBUG
        print("[RtBPopupAd] Initialized with tagGroupId: \(tagGroupId)")
        #endif
    }

    public func load() async throws {
        guard let config = RetailBooster.currentConfig else {
            throw RetailBoosterError.notInitialized
        }

        guard let userId = config.userId, let crypto = config.crypto else {
            throw RetailBoosterError.userInfoNotSet
        }

        #if DEBUG
        print("[RtBPopupAd] Loading popup ad for tagGroupId: \(tagGroupId)")
        #endif

        await MainActor.run {
            self.viewModel = AdViewModel(
                mediaId: config.mediaId,
                userId: userId,
                crypto: crypto,
                tagGroupId: tagGroupId,
                runMode: config.mode,
                popupCallback: self.callback,
                popupOptions: self.options
            )
        }

        await viewModel?.fetchAdsWithUIUpdate()
        isLoaded = true

        #if DEBUG
        print("[RtBPopupAd] Load completed")
        #endif
    }

    public func show(from viewController: UIViewController? = nil) {
        guard !isUsed else {
            #if DEBUG
            print("[RtBPopupAd] Ad already used")
            #endif
            callback.onClose?()
            return
        }

        guard isLoaded, let vm = viewModel else {
            #if DEBUG
            print("[RtBPopupAd] Ad not loaded")
            #endif
            callback.onClose?()
            return
        }

        // TODO: Popup広告の表示実装
        // 現在はAdViewModelがPopup広告データを持たないため、一旦callbackのみ実行
        #if DEBUG
        print("[RtBPopupAd] Showing popup ad (not yet implemented)")
        #endif

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
    internal init(tagGroupId: String, eventName: String? = nil, options: PopupOptions? = nil, callback: PopupCallback = PopupCallback(), mockViewModel: AdViewModel) {
        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options
        self.callback = callback
        self.viewModel = mockViewModel
        self.isLoaded = true
    }
    #endif
}
