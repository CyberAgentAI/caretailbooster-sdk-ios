import Foundation
@testable import CaRetailBoosterSDK

/// Utility structure providing mock data for testing
@available(iOS 13.0, *)
struct MockData {

    // MARK: - AdWebViewUrl

    static let sampleAdWebViewUrl = AdWebViewUrl(
        contents: "https://example.com/ad/contents",
        getting: "https://example.com/ad/getting",
        interruption: "https://example.com/ad/interruption"
    )

    // MARK: - TagGroup

    static let sampleTagGroup = TagGroup(
        length: 3,
        areaName: "おすすめエリア",
        areaDescription: "あなたにおすすめの広告"
    )

    static let emptyTagGroup = TagGroup(
        length: 0,
        areaName: nil,
        areaDescription: nil
    )

    // MARK: - Reward Ads

    static let sampleReward1 = Reward(
        ad_id: 1001,
        index: 0,
        tag_id: "reward_tag_1",
        format_type: "video",
        video_type: "mp4",
        is_granted: false,
        webview_url: sampleAdWebViewUrl,
        imp_url: "https://example.com/imp/1001",
        view_url: "https://example.com/view/1001",
        param: "param_1001"
    )

    static let sampleReward2 = Reward(
        ad_id: 1002,
        index: 1,
        tag_id: "reward_tag_2",
        format_type: "survey",
        video_type: nil,
        is_granted: false,
        webview_url: sampleAdWebViewUrl,
        imp_url: "https://example.com/imp/1002",
        view_url: "https://example.com/view/1002",
        param: "param_1002"
    )

    static let sampleReward3 = Reward(
        ad_id: 1003,
        index: 2,
        tag_id: "reward_tag_3",
        format_type: "video",
        video_type: "webm",
        is_granted: true,
        webview_url: sampleAdWebViewUrl,
        imp_url: "https://example.com/imp/1003",
        view_url: "https://example.com/view/1003",
        param: "param_1003"
    )

    static let allRewards = [sampleReward1, sampleReward2, sampleReward3]

    // MARK: - Banner Ads

    static let sampleBanner1 = Banner(
        ad_id: 2001,
        index: 0,
        tag_id: "banner_tag_1",
        width: 320,
        height: 50,
        imp_url: "https://example.com/imp/2001",
        param: "param_2001",
        webview_url: "https://example.com/banner/2001",
        landing_page_url: "https://example.com/landing/2001"
    )

    static let sampleBanner2 = Banner(
        ad_id: 2002,
        index: 1,
        tag_id: "banner_tag_2",
        width: 300,
        height: 250,
        imp_url: "https://example.com/imp/2002",
        param: "param_2002",
        webview_url: "https://example.com/banner/2002",
        landing_page_url: nil
    )

    static let allBanners = [sampleBanner1, sampleBanner2]

    // MARK: - GetRewardResponse

    static let rewardResponse = GetRewardResponse(
        adType: .REWARD,
        tagGroup: sampleTagGroup,
        rewardAds: allRewards,
        bannerAds: []
    )

    static let bannerResponse = GetRewardResponse(
        adType: .BANNER,
        tagGroup: sampleTagGroup,
        rewardAds: [],
        bannerAds: allBanners
    )

    static let emptyResponse = GetRewardResponse(
        adType: nil,
        tagGroup: nil,
        rewardAds: [],
        bannerAds: []
    )

    // MARK: - RewardAds / BannerAds (Decodable wrappers)

    static let sampleRewardAds = RewardAds(
        adType: "REWARD",
        tagGroup: sampleTagGroup,
        ads: allRewards
    )

    static let sampleBannerAds = BannerAds(
        adType: "BANNER",
        tagGroup: sampleTagGroup,
        ads: allBanners
    )
}
