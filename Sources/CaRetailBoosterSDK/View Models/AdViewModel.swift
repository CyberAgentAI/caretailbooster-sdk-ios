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
    @Published public var rewardCallback: RewardCallback?
    @Published public var popupCallback: PopupCallback?
    @Published public var bannerOptions: BannerOptions?
    @Published public var rewardOptions: RewardOptions?
    @Published public var popupOptions: PopupOptions?
    
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
    let runMode: RunMode

    // Banner広告用 init
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        runMode: RunMode,
        bannerOptions: BannerOptions? = nil
    ) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        self.bannerOptions = bannerOptions
    }

    // Reward広告用 init
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        runMode: RunMode,
        rewardCallback: RewardCallback? = nil,
        rewardOptions: RewardOptions? = nil
    ) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        self.rewardCallback = rewardCallback
        self.rewardOptions = rewardOptions
    }

    // Popup広告用 init（将来の実装のため）
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        runMode: RunMode,
        popupCallback: PopupCallback? = nil,
        popupOptions: PopupOptions? = nil
    ) {
        self.mediaId = mediaId
        self.userId = userId
        self.crypto = crypto
        self.tagGroupId = tagGroupId
        self.runMode = runMode
        self.popupCallback = popupCallback
        self.popupOptions = popupOptions
    }
    
    public func fetchAdsWithUIUpdate() async {
        #if DEBUG
        print("[AdViewModel] fetchAdsWithUIUpdate called at \(Date()) for tagGroupId: \(tagGroupId)")
        #endif
        do {
            let body = RewardAdsRequestBody(
                user: .init(id: userId),
                publisher: .init(id: mediaId, crypto: crypto),
                tagInfo: .init(tagGroupId: tagGroupId),
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
            print("[AdViewModel] Error fetching ads: \(error)")
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
            #if DEBUG
            print("[AdViewModel] No adType set, skipping preload")
            #endif
            return
        }
        
        switch adType {
        case .REWARD:
            #if DEBUG
            print("[AdViewModel] Preloading WebViews for \(rewardAds.count) reward ads")
            #endif
            for ad in rewardAds {
                let vm = BaseWebViewVM(ad: ad, rewardVm: self)
                let key = "reward_\(ad.ad_id)_\(ad.param)"
                webViewVMCache[key] = vm
                // 非同期でロード開始
                vm.loadWebPageOnce(webResource: ad.webview_url.contents)
            }
            
        case .BANNER:
            #if DEBUG
            print("[AdViewModel] Preloading WebViews for \(bannerAds.count) banner ads")
            #endif
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
            #if DEBUG
            print("[AdViewModel] Using cached VM for reward ad \(ad.ad_id)")
            #endif
            return cached
        }
        // フォールバック（キャッシュミス時）
        #if DEBUG
        print("[AdViewModel] Cache miss, creating new VM for reward ad \(ad.ad_id)")
        #endif
        let vm = BaseWebViewVM(ad: ad, rewardVm: self)
        return vm
    }
    
    func getOrCreateBannerVM(for ad: Banner) -> BaseWebViewVM {
        let key = "banner_\(ad.ad_id)_\(ad.param)"
        if let cached = webViewVMCache[key] {
            #if DEBUG
            print("[AdViewModel] Using cached VM for banner ad \(ad.ad_id)")
            #endif
            return cached
        }
        // フォールバック（キャッシュミス時）
        #if DEBUG
        print("[AdViewModel] Cache miss, creating new VM for banner ad \(ad.ad_id)")
        #endif
        let vm = BaseWebViewVM(bannerAd: ad)
        return vm
    }
}
