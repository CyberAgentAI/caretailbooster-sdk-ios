import WebKit

enum MessageHandler: String, CaseIterable {
    case playVideo
    case playVideoSurvey
    case showModal
    case closeModal
    case onMarkSuccess
    case onRewardFinish
    case fetchAds
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
            print("Bad URL")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Functions for messaging
    
    func messageFrom(fromHandler: MessageHandler, message: String) {
        switch fromHandler {
        case .playVideo:
            if ad != nil {
                rewardVm?.currentAd = ad
                rewardVm?.videoUrl = message
                rewardVm?.isVideoPlaying = true
            }
        case .playVideoSurvey:
            if ad != nil {
                rewardVm?.currentAd = ad
                rewardVm?.videoSurveyUrl = message
                rewardVm?.isVideoSurveyPlaying = true
            }
        case .showModal:
            if ad != nil {
                rewardVm?.currentAd = ad
                rewardVm?.surveyUrl = message
                rewardVm?.isSurveyPanelShowed = true
            }
        case .closeModal:
            if ad != nil {
                rewardVm?.currentAd = nil
                rewardVm?.isSurveyPanelShowed = false // リワード獲得済みなのでサーベイモーダルを閉じる
            }
            
            rewardVm?.isVideoPlaying = false
            rewardVm?.isVideoSurveyPlaying = false
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
        
        // パラメータが取得でき、かつ未送信の場合のみ有効化
        if let param = param,
           let rewardVm = rewardVm,
           let adId = adType == .REWARD ? ad?.ad_id : bannerAd?.ad_id,
           !rewardVm.hasImpressionBeenSent(for: adId) {
            enableTracking = true
            trackingEndpoint = switch adType {
            case .REWARD:
                ad?.imp_url ?? ""
            case .BANNER:
                bannerAd?.imp_url ?? ""
            }
            self.trackingParam = param
        }
    }
    
    func stopTracking() {
        enableTracking = false
        Task { @MainActor in   
            AdTracking.stopTracking(param: trackingParam ?? "")
        }
    }
}
