import WebKit

enum MessageHandler: String, CaseIterable {
    case playVideo
    case playVideoSurvey
    case showModal
    case closeModal
    case onMarkSuccess
    case onRewardFinish
    case fetchAds
    case openUrl
    case consoleLog
}

@MainActor
@available(iOS 13.0, *)
class BaseWebViewVM: ObservableObject {
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // this will not require any gesture for triggering playback
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(
            frame: .zero,
            configuration: config)

        if #available(iOS 16.4, *) {
#if DEBUG
            webView.isInspectable = true
#endif
        } else {
            // Fallback on earlier versions
        }

        return webView
    }()

    var rewardVm: AdViewModel?
    var ad: Reward?
    var bannerAd: Banner?

    // Tracking用のパラメータ
    var enableTracking: Bool = false
    var trackingEndpoint: String?
    var trackingParam: String?
    var trackingAdId: Int?
    
    // WebViewロード済みフラグ（onAppear多重実行防止）
    private var isLoaded: Bool = false

    // init for banner
    init(bannerAd: Banner) {
        self.bannerAd = bannerAd
    }

    // init for reward
    init(ad: Reward? = nil, rewardVm: AdViewModel) {
        self.ad = ad
        self.rewardVm = rewardVm
    }
    
    func loadWebPage(webResource: String) {
        guard let url = URL(string: webResource) else {
            print("[BaseWebViewVM] Bad URL")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func loadWebPageOnce(webResource: String) {
        guard !isLoaded else {
            #if DEBUG
            print("[BaseWebViewVM] WebView already loaded, skipping reload")
            #endif
            return
        }
        loadWebPage(webResource: webResource)
        isLoaded = true
    }
    
    // MARK: - Functions for messaging
    // メインスレッドで実行することで、スクロールなどとの処理競合を防ぐ
    @MainActor
    func messageFrom(fromHandler: MessageHandler, message: String) {
        print("🟢 [messageFrom] START - Handler: \(fromHandler)")
        print("🟢 [messageFrom] Message: \(message)")
        print("🟢 [messageFrom] Thread: \(Thread.isMainThread ? "Main" : "Background")")
        print("🟢 [messageFrom] ad: \(ad?.ad_id ?? -1), rewardVm: \(rewardVm != nil)")
        
        switch fromHandler {
        case .playVideo:
            print("🟢 [messageFrom] Case: playVideo")
            if let ad {
                print("🟢 [messageFrom] Calling showModal for video - URL: \(message)")
                rewardVm?.showModal(type: .video(url: message), ad: ad)
                print("🟢 [messageFrom] showModal called")
            } else {
                print("🔴 [messageFrom] ERROR - ad is nil for playVideo")
            }
        case .playVideoSurvey:
            print("🟢 [messageFrom] Case: playVideoSurvey")
            if let ad {
                print("🟢 [messageFrom] Calling showModal for videoSurvey - URL: \(message)")
                rewardVm?.showModal(type: .videoSurvey(url: message), ad: ad)
                print("🟢 [messageFrom] showModal called")
            } else {
                print("🔴 [messageFrom] ERROR - ad is nil for playVideoSurvey")
            }
        case .showModal:
            print("🟢 [messageFrom] Case: showModal")
            if let ad {
                print("🟢 [messageFrom] Calling showModal for survey - URL: \(message)")
                rewardVm?.showModal(type: .survey(url: message), ad: ad)
                print("🟢 [messageFrom] showModal called")
            } else {
                print("🔴 [messageFrom] ERROR - ad is nil for showModal")
            }
        case .closeModal:
            print("🟢 [messageFrom] Case: closeModal")
            rewardVm?.closeModal()
        case .onMarkSuccess:
            // マーク完了をSDKユーザーに通知
            rewardVm?.callback?.onMarkSucceeded()
        case .onRewardFinish:
            // リワード獲得をSDKユーザーに通知
            rewardVm?.callback?.onRewardModalClosed()
        case .fetchAds:
            // 広告を取得
            Task {
                if let rewardVm = self.rewardVm {
                    await rewardVm.fetchAdsWithUIUpdate()
                }
            }
            // notificationを使用して、Flutter側にfetchAdsを通知する
            NotificationCenter.default.post(name: NSNotification.FetchAds, object: nil)
        case .openUrl:
            guard
                let bannerAd,
                let urlString = bannerAd.landing_page_url,
                let url = URL(string: urlString) else {
                return
            }
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("[BaseWebViewVM] Failed to open URL: \(urlString)")
                }
                print("[BaseWebViewVM] Opened URL: \(urlString)")
            }
        case .consoleLog:
            // consoleLog is handled in SwiftUIWebView.Coordinator
            // This case should not be reached
            break
        }
    }
    
    func enableImpTracking(adType: AdType) {
        // パラメータの取得
        let param: String? = switch adType {
        case .REWARD:
            ad?.param
        case .BANNER:
            bannerAd?.param
        }
        
        // BannerAdの場合は重複チェックなし、RewardAdの場合のみ重複チェック
        let shouldEnableTracking: Bool = switch adType {
        case .REWARD:
            if let param = param,
               let rewardVm = rewardVm,
               let adId = ad?.ad_id,
               !rewardVm.hasImpressionBeenSent(for: adId) {
                true
            } else {
                false
            }
        case .BANNER:
            // BannerAdは重複チェックなし
            param != nil
        }
        
        if shouldEnableTracking {
            enableTracking = true
            trackingEndpoint = switch adType {
            case .REWARD:
                ad?.imp_url ?? ""
            case .BANNER:
                bannerAd?.imp_url ?? ""
            }
            self.trackingParam = param
            
            // ad_idも保存
            self.trackingAdId = switch adType {
            case .REWARD:
                ad?.ad_id
            case .BANNER:
                bannerAd?.ad_id
            }
            
            #if DEBUG
            let adId = trackingAdId ?? 0
            print("[BaseWebViewVM] Impression tracking enabled for \(adType) ad (ID: \(adId), endpoint: \(trackingEndpoint ?? "nil"))")
            #endif
        } else {
            #if DEBUG
            print("[BaseWebViewVM] Impression tracking NOT enabled for \(adType) ad - conditions not met")
            #endif
        }
    }
    
    func stopTracking() {
        enableTracking = false
        Task { @MainActor in   
            AdTracking.stopTracking(param: trackingParam ?? "", adId: trackingAdId ?? 0)
        }
    }
}
