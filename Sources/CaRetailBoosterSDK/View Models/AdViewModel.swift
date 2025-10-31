//
//  RewardViewModel.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2024/12/21.
//
import SwiftUI

@MainActor
@available(iOS 13.0, *)
class AdViewModel: ObservableObject {
    @Published public var rewardAds: [Reward] = []
    @Published public var bannerAds: [Banner] = []
    @Published public var adType: AdType? = .BANNER
    @Published public var areaName: String?
    @Published public var areaDescription: String?

    @Published var activeModal: ModalType = .none
    @Published var currentAd: Reward?
    @Published public var rewardCallback: RtBRewardCallback?
    @Published public var popupCallback: RtBPopupCallback?
    @Published public var bannerOptions: RtBBannerOptions?
    @Published public var rewardOptions: RtBRewardOptions?
    @Published public var popupOptions: RtBPopupOptions?
    
    // 強制リフレッシュ用プロパティ
    @Published public var forceRefreshToken = UUID()
    // 最後に取得したデータのキャッシュ
    private var lastFetchedRewardAds: [Reward] = []
    // impリクエストの送信状態を管理
    private var sentImpAdIds: Set<Int> = []
    // WebView VMキャッシュ（事前ロード用）
    private var webViewVMCache: [String: BaseWebViewVM] = [:]
    
    let mediaId: String
    let userId: String
    let crypto: String
    let tagGroupId: String
    let runMode: RtBRunMode
    let eventName: String?

    // Banner広告用 init
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        runMode: RtBRunMode,
        eventName: String? = nil,
        bannerOptions: RtBBannerOptions? = nil
    ) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        self.eventName = eventName
        self.bannerOptions = bannerOptions
    }

    // Reward広告用 init
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        runMode: RtBRunMode,
        eventName: String? = nil,
        rewardCallback: RtBRewardCallback? = nil,
        rewardOptions: RtBRewardOptions? = nil
    ) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        self.eventName = eventName
        self.rewardCallback = rewardCallback
        self.rewardOptions = rewardOptions
    }

    // Popup広告用 init
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        runMode: RtBRunMode,
        eventName: String? = nil,
        popupCallback: RtBPopupCallback? = nil,
        popupOptions: RtBPopupOptions? = nil
    ) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        self.eventName = eventName
        self.popupCallback = popupCallback
        self.popupOptions = popupOptions
    }
    
    public func fetchAdsWithUIUpdate() async {
        Log.debug("fetchAdsWithUIUpdate called at \(Date()) for tagGroupId: \(tagGroupId)", context: "AdViewModel")
        do {
            let body = RewardAdsRequestBody(
                user: .init(id: userId),
                publisher: .init(id: mediaId, crypto: crypto),
                tagInfo: .init(tagGroupId: tagGroupId, eventName: eventName),
                device: .init(make: DeviceInfo.make, os: DeviceInfo.os, osv: DeviceInfo.osVersion, hwv: DeviceInfo.hwv, h: DeviceInfo.height, w: DeviceInfo.width, language: DeviceInfo.language, ifa: DeviceInfo.ifa)
            )
           
            let res = try await getAds(runMode: runMode, body: body)
           
            // メインスレッドで実行することで、確実にUIを更新する
            await MainActor.run {
                // バナー広告は更新の必要がないので、リワード広告のみを対象とする
                let hasRewardAdsChanged = !areSameRewards(res.rewardAds, lastFetchedRewardAds)
                
                let newAdIds = Set(res.rewardAds.map { $0.ad_id })
                sentImpAdIds = sentImpAdIds.intersection(newAdIds)

                // VMキャッシュをクリア
                webViewVMCache.removeAll()

                rewardAds = res.rewardAds
                bannerAds = res.bannerAds
                adType = res.adType
                lastFetchedRewardAds = res.rewardAds
                areaName = res.tagGroup?.areaName
                areaDescription = res.tagGroup?.areaDescription
                
                if hasRewardAdsChanged {
                    forceRefreshToken = UUID()
                }
                preloadWebViews()
            }
        } catch {
            Log.error("Error fetching ads: \(error)", context: "AdViewModel")
            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
        }
    }
       
    private func areSameRewards(_ newAds: [Reward], _ oldAds: [Reward]) -> Bool {
        if newAds.isEmpty && oldAds.isEmpty {
            return true
        }
        
        if newAds.count != oldAds.count {
            return false
        }
        
        let oldHash = oldAds.map { "\($0.ad_id)_\($0.param)" }.joined(separator: "|")
        let newHash = newAds.map { "\($0.ad_id)_\($0.param)" }.joined(separator: "|")
        
        return oldHash == newHash
    }

    public func hasImpressionBeenSent(for adId: Int) -> Bool {
        sentImpAdIds.contains(adId)
    }

    public func markImpressionSent(for adId: Int) {
        sentImpAdIds.insert(adId)
    }

    public func resetImpressionSentAdIds() {
        sentImpAdIds.removeAll()
    }

    func showModal(type: ModalType, ad: Reward) {
        currentAd = ad
        activeModal = type
    }

    func closeModal() {
        activeModal = .none
        currentAd = nil
    }
    
    private func preloadWebViews() {
        guard let adType = adType else {
            Log.debug("No adType set, skipping preload", context: "AdViewModel")
            return
        }

        switch adType {
        case .REWARD:
            Log.debug("Preloading WebViews for \(rewardAds.count) reward ads", context: "AdViewModel")
            for ad in rewardAds {
                let vm = BaseWebViewVM(ad: ad, rewardVm: self)
                let key = "reward_\(ad.ad_id)_\(ad.param)"
                webViewVMCache[key] = vm
                // 非同期でロード開始
                vm.loadWebPageOnce(webResource: ad.webview_url.contents)
            }

        case .BANNER:
            Log.debug("Preloading WebViews for \(bannerAds.count) banner ads", context: "AdViewModel")
            for ad in bannerAds {
                let vm = BaseWebViewVM(bannerAd: ad)
                let key = "banner_\(ad.ad_id)_\(ad.param)"
                webViewVMCache[key] = vm
                // 非同期でロード開始
                vm.loadWebPageOnce(webResource: ad.webview_url)
            }
        case .POPUP:
            break
        }
    }
    
    func getOrCreateRewardVM(for ad: Reward) -> BaseWebViewVM {
        let key = "reward_\(ad.ad_id)_\(ad.param)"
        if let cached = webViewVMCache[key] {
            Log.debug("Using cached VM for reward ad \(ad.ad_id)", context: "AdViewModel")
            return cached
        }
        // フォールバック（キャッシュミス時）
        Log.debug("Cache miss, creating new VM for reward ad \(ad.ad_id)", context: "AdViewModel")
        let vm = BaseWebViewVM(ad: ad, rewardVm: self)
        webViewVMCache[key] = vm
        return vm
    }

    func getOrCreateBannerVM(for ad: Banner) -> BaseWebViewVM {
        let key = "banner_\(ad.ad_id)_\(ad.param)"
        if let cached = webViewVMCache[key] {
            Log.debug("Using cached VM for banner ad \(ad.ad_id)", context: "AdViewModel")
            return cached
        }
        // フォールバック（キャッシュミス時）
        Log.debug("Cache miss, creating new VM for banner ad \(ad.ad_id)", context: "AdViewModel")
        let vm = BaseWebViewVM(bannerAd: ad)
        webViewVMCache[key] = vm
        return vm
    }
}
