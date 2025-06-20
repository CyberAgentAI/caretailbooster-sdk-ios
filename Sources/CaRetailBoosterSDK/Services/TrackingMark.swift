//
//  http.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2024/12/17.
//

import Foundation
import SwiftUI
import WebKit
import Combine


struct AdTracking {
    private static let visibilityThreshold: CGFloat = 0.5
    private static let visibilityDuration: TimeInterval = 1.0
    
    static func impression(endpoint: String, param: String) async throws {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [URLQueryItem(name: "param", value: param)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        let (_, response) = try await URLSession.shared.data(from: url)
        
        // if not 200, throw error
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    @MainActor
    private final class TimerManager {
        static let shared = TimerManager()
        private var timers: [String: (timer: Timer, startTime: Date)] = [:]
        
        func addTimer(key: String, timer: Timer, startTime: Date) {
            timers[key] = (timer, startTime)
        }
        
        func getStartTime(for key: String) -> Date? {
            return timers[key]?.startTime
        }
        
        func getTimer(for key: String) -> Timer? {
            return timers[key]?.timer
        }
        
        func stopTimer(for key: String) {
            if let timerInfo = timers[key] {
                timerInfo.timer.invalidate()
                timers.removeValue(forKey: key)
            }
        }
        
        func stopAllTimers() {
            for (_, timerInfo) in timers {
                timerInfo.timer.invalidate()
            }
            timers.removeAll()
        }
    }
    
    @MainActor
    static func trackImpression(webView: WKWebView, endpoint: String, param: String) {
        let trackingKey = "impression_\(param)"
        
        // すでに動いているタイマーがあれば停止
        TimerManager.shared.stopTimer(for: trackingKey)
        
        let startTime = Date()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                let isVisible = isWebViewVisible(webView: webView)
                if !isVisible {
                    // 可視でない場合は時間をリセット
                    if let timer = TimerManager.shared.getTimer(for: trackingKey) {
                        TimerManager.shared.addTimer(key: trackingKey, timer: timer, startTime: Date())
                    }
                    return
                }
                
                // 1秒以上経過したかチェック
                if let existingStartTime = TimerManager.shared.getStartTime(for: trackingKey),
                   Date().timeIntervalSince(existingStartTime) >= visibilityDuration {
                    // 1秒以上経過している場合、タイマーを停止
                    TimerManager.shared.stopTimer(for: trackingKey)
                    Task {
                        do {
                            try await impression(endpoint: endpoint, param: param)
                        } catch {
                            print("Failed to track impression: \(error)")
                        }
                    }
                }
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
        
        // タイマーを保存
        TimerManager.shared.addTimer(key: trackingKey, timer: timer, startTime: startTime)
    }
    
    @MainActor
    private static func isWebViewVisible(webView: WKWebView) -> Bool {
        // ビューが表示されているか、ウィンドウに追加されているか確認
        guard webView.superview != nil, webView.window != nil else {
            return false
        }
        
        // ビューの表示されている範囲を計算
        let visibleRect = calculateVisibleRect(for: webView)
        let totalArea = webView.bounds.width * webView.bounds.height
        
        // 表示領域が0でないことを確認（ゼロ除算防止）
        guard totalArea > 0 else {
            return false
        }
        
        // 表示領域の比率を計算
        let visibleArea = visibleRect.width * visibleRect.height
        let visibilityRatio = visibleArea / totalArea
        
        return visibilityRatio >= visibilityThreshold
    }
    
    @MainActor
    private static func calculateVisibleRect(for view: UIView) -> CGRect {
        guard let superview = view.superview else { return .zero }
        
        var visibleRect = view.bounds
        // ビューの変換行列を使用してウィンドウ座標系に変換
        let viewFrameInWindow = view.convert(view.bounds, to: nil)
        
        // 画面の境界と交差するか確認
        if let window = view.window {
            let screenBounds = window.bounds
            let intersection = viewFrameInWindow.intersection(screenBounds)
            
            // 交差領域がある場合、その領域をビューの座標系に戻す
            if !intersection.isNull && intersection.width > 0 && intersection.height > 0 {
                let visibleRectInWindow = viewFrameInWindow.intersection(screenBounds)
                visibleRect = view.convert(visibleRectInWindow, from: nil)
            } else {
                // 画面外にある場合
                visibleRect = .zero
            }
        }
        
        return visibleRect
    }
    
    @MainActor
    static func stopTracking(param: String) {
        let trackingKey = "impression_\(param)"
        TimerManager.shared.stopTimer(for: trackingKey)
    }
}

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
