import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class RtBBannerAd: ViewableAd {
    public let tagGroupId: String
    public let eventName: String?
    public let options: BannerOptions?

    public var areaName: String? {
        viewModel?.areaName
    }

    public var areaDescription: String? {
        viewModel?.areaDescription
    }

    private var viewModel: AdViewModel?
    private var isLoaded: Bool = false

    public init?(tagGroupId: String, eventName: String? = nil, options: BannerOptions? = nil) {
        guard RetailBooster.isInitialized else {
            #if DEBUG
            print("[RtBBannerAd] Error: SDK not initialized")
            #endif
            return nil
        }

        self.tagGroupId = tagGroupId
        self.eventName = eventName
        self.options = options

        #if DEBUG
        print("[RtBBannerAd] Initialized with tagGroupId: \(tagGroupId)")
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
        print("[RtBBannerAd] Loading banner ads for tagGroupId: \(tagGroupId)")
        #endif

        await MainActor.run {
            self.viewModel = AdViewModel(
                mediaId: config.mediaId,
                userId: userId,
                crypto: crypto,
                tagGroupId: tagGroupId,
                runMode: config.mode,
                bannerOptions: self.options
            )
        }

        await viewModel?.fetchAdsWithUIUpdate()
        isLoaded = true

        #if DEBUG
        let adCount = viewModel?.bannerAds.count ?? 0
        print("[RtBBannerAd] Loaded \(adCount) banner ads")
        #endif
    }

    public var views: [AnyView] {
        guard isLoaded, let vm = viewModel else {
            return []
        }

        return vm.bannerAds.map { ad in
            AnyView(BannerAd(ad: ad).environmentObject(vm))
        }
    }

    deinit {
        let vm = self.viewModel
        Task { @MainActor in
            vm?.resetImpressionSentAdIds()
        }
    }
}
