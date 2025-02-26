//
//  RewardViewModel.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2024/12/21.
//
import SwiftUI

@MainActor
@available(iOS 13.0, *)
public class AdViewModel: ObservableObject {
    @Published public var rewardAds: [Reward] = []
    @Published public var bannerAds: [Banner] = []
    @Published public var adType: AdType = .BANNER
    
    @Published var isVideoPlaying: Bool = false
    @Published var isSurveyPanelShowed: Bool = false
    @Published var isSurveyAnswerd: Bool = false
    @Published var isRewardCoverOpened: Bool = false
    @Published var isVideoInterrupted: Bool = false
    
    @Published var currentAd: Reward?
    @Published var videoUrl: String?
    @Published var surveyUrl: String?
    
    @Published public var callback: Callback?
    @Published public var options: Options?
    
    let mediaId: String
    let userId: String
    let crypto: String
    let tagGroupId: String
    let runMode: RunMode
    
    public init(mediaId: String, userId: String, crypto: String, tagGroupId: String, runMode: RunMode, callback: Callback? = nil, options: Options? = nil) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        
        if let callback = callback {
            self.callback = callback
        }
        if let options = options {
            self.options = options
        }
    }
    
    public func fetchAds() async -> String {
        do {
            let body = RewardAdsRequestBody(
                user: .init(id: userId),
                publisher: .init(id: mediaId, crypto: crypto),
                tagInfo: .init(tagGroupId: tagGroupId),
                device: .init(make: DeviceInfo.make, os: DeviceInfo.os, osv: DeviceInfo.osVerion, hwv: DeviceInfo.hwv, h: DeviceInfo.height, w: DeviceInfo.width, language: DeviceInfo.language, ifa: DeviceInfo.ifa)
            )
            let res = try await getAds(runMode: runMode, body: body)
            bannerAds = res.bannerAds
            rewardAds = res.rewardAds
            adType = res.adType
        } catch {
            print("Error fetching ads: \(error)")
            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
        }
        
        return "OK"
    }
}

public struct Callback {
    var onMarkSucceeded: () -> Void?
    var onRewardModalClosed: () -> Void?
    
    public init(onMarkSucceeded: @escaping () -> Void?, onRewardModalClosed: @escaping () -> Void?) {
        self.onMarkSucceeded = onMarkSucceeded
        self.onRewardModalClosed = onRewardModalClosed
    }
}

// 必要なOptionは随時追加していく
public struct Options {
    var rewardAd: RewardAdOption?
    
    public init(rewardAd: RewardAdOption? = nil) {
        self.rewardAd = rewardAd
    }
}

public struct RewardAdOption {
    var width: CGFloat?
    var height: CGFloat?
    
    public init(width: Int?, height: Int?) {
        self.width = width != nil ? CGFloat(width!) : nil
        self.height = height != nil ? CGFloat(height!) : nil
    }
}

public enum RunMode: String {
    case local
    case dev
    case stg
    case prd
    case mock
}
