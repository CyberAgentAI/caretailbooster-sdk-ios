import Foundation
import SwiftUI
import WebKit

struct AdWebViewUrl: Decodable {
    let contents: String
    let getting: String
    let interruption: String
}

struct Reward: Decodable {
    let ad_id: Int
    let index: Int
    let tag_id: String
    let format_type: String
    let video_type: String?
    let is_granted: Bool
    let webview_url: AdWebViewUrl
    let imp_url: String
    let view_url: String
    let param: String
}

struct Banner: Decodable {
    let ad_id: Int
    let index: Int
    let tag_id: String
    let width: Int
    let height: Int
    let imp_url: String
    let param: String
    let webview_url: String
}

struct RewardAds: Decodable {
    let adType: String
    let tagGroup: TagGroup?
    let ads: [Reward]

    enum CodingKeys: String, CodingKey {
        case adType = "ad_type"
        case tagGroup = "tag_group"
        case ads
    }
}

struct GetRewardResponse {
    let adType: AdType?
    let tagGroup: TagGroup?
    let rewardAds: [Reward]
    let bannerAds: [Banner]
}

enum AdType: String {
    case BANNER
    case REWARD
}

struct TagGroup: Decodable {
    let length: Int?
    let areaName: String?
    let areaDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case length
        case areaName = "area_name"
        case areaDescription = "area_description"
    }
}

struct BannerAds: Decodable {
    let adType: String
    let tagGroup: TagGroup?
    let ads: [Banner]

    enum CodingKeys: String, CodingKey {
        case adType = "ad_type"
        case tagGroup = "tag_group"
        case ads
    }
}

struct AdCallResponse: Decodable {
    let ad_type: String
}

struct AdsRequest: Codable {
    struct User: Codable {
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

typealias RewardAdsRequestBody = AdsRequest

@MainActor
@available(iOS 13.0, *)
func getAds(runMode: RunMode, body: RewardAdsRequestBody) async throws -> GetRewardResponse {
    let url: String
    switch runMode {
    case RunMode.dev:
        url = Const.DEV_AD_SERVER_URL
    case RunMode.stg:
        url = Const.STG_AD_SERVER_URL
    case RunMode.prd:
        url = Const.PRD_AD_SERVER_URL
    case RunMode.mock:
        url = Const.MOCK_AD_SERVER_URL
    default:
        url = Const.LOCAL_AD_SERVER_URL
    }
    guard let components = URLComponents(string: url),
          let url = components.url else {
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
        return GetRewardResponse(adType: nil, tagGroup: nil, rewardAds: [], bannerAds: [])
    }

    // レスポンスのad_type=REWARD or BANNERになる
    let res = try JSONDecoder().decode(AdCallResponse.self, from: data)
    if res.ad_type == AdType.BANNER.rawValue {
        let bannerAds = try JSONDecoder().decode(BannerAds.self, from: data)
        return GetRewardResponse(adType: .BANNER, tagGroup: bannerAds.tagGroup, rewardAds: [], bannerAds: bannerAds.ads)
    } else if res.ad_type == AdType.REWARD.rawValue {
        let rewardAds = try JSONDecoder().decode(RewardAds.self, from: data)
        return GetRewardResponse(adType: .REWARD, tagGroup: rewardAds.tagGroup, rewardAds: rewardAds.ads, bannerAds: [])
    }

    return GetRewardResponse(adType: nil, tagGroup: nil, rewardAds: [], bannerAds: [])
}
