import Foundation
@testable import CaRetailBoosterSDK

@available(iOS 13.0, *)
@MainActor
extension AdViewModel {
    /// Convenience initializer to create AdViewModel with mock response data
    convenience init(mockResponse: GetRewardResponse) {
        self.init(
            mediaId: "mock_media",
            userId: "mock_user",
            crypto: "mock_crypto",
            tagGroupId: "mock_tag_group",
            runMode: .dev,
            eventName: nil,
            bannerOptions: nil
        )

        // Directly set mock data
        self.rewardAds = mockResponse.rewardAds
        self.bannerAds = mockResponse.bannerAds
        self.adType = mockResponse.adType
        self.areaName = mockResponse.tagGroup?.areaName
        self.areaDescription = mockResponse.tagGroup?.areaDescription
    }

    /// Test helper: Mark specific banner ad as having an error
    func markBannerAdAsError(adId: Int) {
        guard let ad = bannerAds.first(where: { $0.ad_id == adId }) else { return }
        let vm = getOrCreateBannerVM(for: ad)
        vm.hasError = true
    }

    /// Test helper: Mark specific reward ad as having an error
    func markRewardAdAsError(adId: Int) {
        guard let ad = rewardAds.first(where: { $0.ad_id == adId }) else { return }
        let vm = getOrCreateRewardVM(for: ad)
        vm.hasError = true
    }
}
