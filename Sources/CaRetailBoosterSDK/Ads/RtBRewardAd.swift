import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
public class RtBRewardAd: ViewableAd {
    public let tagGroupId: String
    public let eventName: String?
    public let options: RewardOptions?
    private var callback: RewardCallback

    public var areaName: String? {
        viewModel?.areaName
    }

    public var areaDescription: String? {
        viewModel?.areaDescription
    }

    private var viewModel: AdViewModel?
    private var isLoaded: Bool = false

    public init?(
        tagGroupId: String,
        eventName: String? = nil,
        options: RewardOptions? = nil,
        configureCallback: ((inout RewardCallback) -> Void)? = nil
    ) {
        guard RetailBooster.isInitialized else {
            #if DEBUG
            print("[RtBRewardAd] Error: SDK not initialized")
            #endif
            return nil
        }

        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options

        var callback = RewardCallback()
        configureCallback?(&callback)
        self.callback = callback

        #if DEBUG
        print("[RtBRewardAd] Initialized with tagGroupId: \(tagGroupId)")
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
        print("[RtBRewardAd] Loading reward ads for tagGroupId: \(tagGroupId)")
        #endif

        await MainActor.run {
            self.viewModel = AdViewModel(
                mediaId: config.mediaId,
                userId: userId,
                crypto: crypto,
                tagGroupId: tagGroupId,
                runMode: config.mode,
                rewardCallback: self.callback,
                rewardOptions: self.options
            )
        }

        await viewModel?.fetchAdsWithUIUpdate()
        isLoaded = true

        #if DEBUG
        let adCount = viewModel?.rewardAds.count ?? 0
        print("[RtBRewardAd] Loaded \(adCount) reward ads")
        #endif
    }

    public var views: [AnyView] {
        guard isLoaded, let vm = viewModel else {
            return []
        }

        return vm.rewardAds.map { ad in
            AnyView(
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
}
