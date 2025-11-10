import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
public class RtBRewardAd: ViewableAd {
    public let tagGroupId: String
    public let eventName: String?
    public let options: RtBRewardOptions?
    private var callback: RtBRewardCallback

    public var areaName: String? {
        viewModel?.areaName
    }

    public var areaDescription: String? {
        viewModel?.areaDescription
    }

    private var viewModel: AdViewModel?
    private var isLoaded: Bool = false

    public init(
        tagGroupId: String,
        eventName: String? = nil,
        options: RtBRewardOptions? = nil,
        configureCallback: ((inout RtBRewardCallback) -> Void)? = nil
    ) {
        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options

        var callback = RtBRewardCallback()
        configureCallback?(&callback)
        self.callback = callback

        Log.debug("Initialized with tagGroupId: \(tagGroupId)", context: "RtBRewardAd")
    }

    public func load() async throws {
        guard let config = RetailBooster.currentConfig else {
            throw RtBError.notInitialized
        }

        guard let userId = config.userId, let crypto = config.crypto else {
            throw RtBError.userInfoNotSet
        }

        Log.info("Loading reward ads for tagGroupId: \(tagGroupId)", context: "RtBRewardAd")

        await MainActor.run {
            self.viewModel = AdViewModel(
                mediaId: config.mediaId,
                userId: userId,
                crypto: crypto,
                tagGroupId: tagGroupId,
                runMode: config.mode,
                eventName: self.eventName,
                rewardCallback: self.callback,
                rewardOptions: self.options
            )
        }

        await viewModel?.fetchAdsWithUIUpdate()
        isLoaded = true

        let adCount = viewModel?.rewardAds.count ?? 0
        Log.info("Loaded \(adCount) reward ads", context: "RtBRewardAd")
        let areaName = viewModel?.areaName
        let areaDescription = viewModel?.areaDescription
        Log.info("Area name: \(areaName ?? ""), Area description: \(areaDescription ?? "")", context: "RtBRewardAd")
    }

    public var views: [AnyView] {
        guard isLoaded, let vm = viewModel else {
            return []
        }

        return vm.rewardAds.compactMap { ad in
            let webViewVM = vm.getOrCreateRewardVM(for: ad)
            // エラーが発生したWebViewは除外
            guard !webViewVM.hasError else {
                Log.debug("Excluding reward ad \(ad.ad_id) due to WebView error", context: "RtBRewardAd")
                return nil
            }
            return AnyView(
                RewardAd(ad: ad)
                    .environmentObject(vm)
                    .id("reward_\(ad.index)_\(vm.forceRefreshToken)")
            )
        }
    }

    deinit {
        let vm = self.viewModel
        Task { @MainActor in
            vm?.resetImpressionSentAdIds()
        }
    }

    // Test init - inject mock ViewModel
    #if DEBUG
    internal init(tagGroupId: String, eventName: String? = nil, options: RtBRewardOptions? = nil, callback: RtBRewardCallback = RtBRewardCallback(), mockViewModel: AdViewModel) {
        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options
        self.callback = callback
        self.viewModel = mockViewModel
        self.isLoaded = true
    }
    #endif
}
