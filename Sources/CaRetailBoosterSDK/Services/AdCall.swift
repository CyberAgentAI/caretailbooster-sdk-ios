import Foundation
import SwiftUI
import WebKit

struct AdWebViewUrl: Decodable {
    let contents: String
    let getting: String
    let interruption: String
}

public struct Reward: Decodable {
    let ad_id: Int
    public let index: Int
    let tag_id: String
    let format_type: String
    let video_type: String?
    let is_granted: Bool
    let webview_url: AdWebViewUrl
    let imp_url: String
    let view_url: String
    let param: String
}

public struct Banner: Decodable {
    let ad_id: Int
    public let index: Int
    let tag_id: String
    let width: Int
    let height: Int
    let imp_url: String
    let param: String
    let webview_url: String
}

public struct RewardAds: Decodable {
    let ad_type: String
    let ads: [Reward]
}

public struct GetRewardResponse {
    let adType: AdType?
    let rewardAds: [Reward]
    let bannerAds: [Banner]
}

public enum AdType: String {
    case BANNER
    case REWARD
}

struct BannerAds: Decodable {
    let ad_type: String
    let ads: [Banner]
}

struct AdCallResponse: Decodable {
    let ad_type: String
}

public struct AdsRequest: Codable {
    public struct User: Codable {
        let id: String
    }

    struct Publisher: Codable {
        let id: String
        let crypto: String
    }

    struct TagInfo: Codable {
        let tagGroupId: String

        enum CodingKeys: String, CodingKey {
            case tagGroupId = "tag_group_id"
        }
    }

    struct Device: Codable {
        let make: String
        let os: String
        let osv: String
        let hwv: String
        let h: Int
        let w: Int
        let language: String
        let ifa: String
    }

    enum CodingKeys: String, CodingKey {
        case user, publisher, device
        case tagInfo = "tag_info"
    }

    let user: User
    let publisher: Publisher
    let tagInfo: TagInfo
    let device: Device

    var json: Data? {
        try? JSONEncoder().encode(self)
    }
}

public typealias RewardAdsRequestBody = AdsRequest

@MainActor
@available(iOS 13.0, *)
public func getAds(runMode: RunMode, body: RewardAdsRequestBody) async throws -> GetRewardResponse {
    let url: String
    switch runMode {
    case RunMode.dev:
        url = DEV_AD_SERVER_URL
    case RunMode.stg:
        url = STG_AD_SERVER_URL
    case RunMode.prd:
        url = PRD_AD_SERVER_URL
    case RunMode.mock:
        url = MOCK_AD_SERVER_URL
    default:
        url = LOCAL_AD_SERVER_URL
    }
    let components = URLComponents(string: url)!
    guard let url = components.url else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body.json
    request.timeoutInterval = 20

    let (data, response) = try await URLSession.shared.data(for: request)

    // if not 200 or 204, throw error
    guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 204) else {
        throw URLError(.badServerResponse)
    }

    // 204 No Contentの場合、空のレスポンスを返す
    if httpResponse.statusCode == 204 {
        return GetRewardResponse(adType: nil, rewardAds: [], bannerAds: [])
    }

    // レスポンスのad_type=REWARD or BANNERになる
    let res = try JSONDecoder().decode(AdCallResponse.self, from: data)
    if res.ad_type == AdType.BANNER.rawValue {
        let bannerAds = try JSONDecoder().decode(BannerAds.self, from: data)
        return GetRewardResponse(adType: AdType.BANNER, rewardAds: [], bannerAds: bannerAds.ads)
    } else if res.ad_type == AdType.REWARD.rawValue {
        let rewardAds = try JSONDecoder().decode(RewardAds.self, from: data)
        return GetRewardResponse(adType: AdType.REWARD, rewardAds: rewardAds.ads, bannerAds: [])
    }

    return GetRewardResponse(adType: AdType.BANNER, rewardAds: [], bannerAds: [])
}
