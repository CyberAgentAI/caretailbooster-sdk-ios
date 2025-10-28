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
            bannerOptions: nil
        )

        // Directly set mock data
        self.rewardAds = mockResponse.rewardAds
        self.bannerAds = mockResponse.bannerAds
        self.adType = mockResponse.adType
        self.areaName = mockResponse.tagGroup?.areaName
        self.areaDescription = mockResponse.tagGroup?.areaDescription
    }
}
