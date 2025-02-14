//
//  http.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2024/12/17.
//

import Foundation


struct AdTracking {
    static func view(endpoint: String, param: String, videoProgressEvent: VideoProgressEvent?) async throws {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [URLQueryItem(name: "param", value: param)]
        if let videoProgressEvent = videoProgressEvent {
            components.queryItems?.append(URLQueryItem(name: "event", value: videoProgressEvent.description))
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (_, response) = try await URLSession.shared.data(from: url)
        
        // if not 200, throw error
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}


enum VideoProgressEvent {
    case start
    case half
    case quarter
    case threeQuarter
    case end
    
    var description: String {
        switch self {
        case .start:
            return "start"
        case .quarter:
            return "quarter"
        case .half:
            return "half"
        case .threeQuarter:
            return "threeQuarter"
        case .end:
            return "end"
        }
    }
}

struct AdWebViewUrl: Decodable {
    let contents: String
    let getting: String
    let interruption: String
}

enum AdFormatType: String {
    case VIDEO
    case INTERSTITIAL
    case LOGIN_BONUS
    case SURVEY
}

enum VideoType: String {
    case STANDARD
    case YOUTUBE
}

public struct Reward: Decodable {
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
    let adType: AdType
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
    default:
        url = DEBUG_AD_SERVER_URL
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
    
    // if not 200, throw error
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
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
