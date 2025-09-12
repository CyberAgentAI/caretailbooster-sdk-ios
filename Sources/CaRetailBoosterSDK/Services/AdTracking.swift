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
        
        #if DEBUG
        print("[AdTracking] Sending impression request to: \(url)")
        #endif
        
        let (_, response) = try await URLSession.shared.data(from: url)
        
        // if not 200, throw error
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            #if DEBUG
            print("[AdTracking] Impression request failed with status code: \(httpResponse.statusCode)")
            #endif
            throw URLError(.badServerResponse)
        }
        
        #if DEBUG
        print("[AdTracking] Impression request successful for param: \(param)")
        #endif
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
    static func trackImpression(webView: WKWebView, endpoint: String, param: String, adId: Int) {
        let trackingKey = "impression_\(adId)_\(param)"
        
        #if DEBUG
        print("[AdTracking] Starting impression tracking for ad ID: \(adId), param: \(param)")
        #endif
        
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
                            print("[AdTracking] Failed to track impression: \(error)")
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
    static func stopTracking(param: String, adId: Int) {
        let trackingKey = "impression_\(adId)_\(param)"
        TimerManager.shared.stopTimer(for: trackingKey)
    }
}