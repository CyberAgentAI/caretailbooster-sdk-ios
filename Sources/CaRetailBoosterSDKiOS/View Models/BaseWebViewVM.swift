import Foundation
import WebKit

struct VideoAdMessage: Decodable {
    let index: Int
}

struct OnClickAdMessage: Decodable {
    let adID: Int
}

enum MessageHandler: String, CaseIterable {
    case playVideo
    case showModal
    case closeModal
    case onMarkSuccess
    case onRewardFinish
    case fetchAds
}

@MainActor
@available(iOS 13.0, *)
class BaseWebViewVM: ObservableObject {
    @Published var webResource: String?
    var webView: WKWebView
    
    // MARK: - Properties for Javascript alert, confirm, and prompt dialog boxes
    
    @Published var showPanel: Bool = false
    @Published var isSurveyPanelShowed: Bool = false
    @Published var isSurveyAnswerd: Bool = false
    
    var adVm: BaseWebViewVM?
    
    // ビデオ広告用メッセージ
    var videoAdMessage: VideoAdMessage?
    var onClickAdMessage: OnClickAdMessage?
    
    var rewardAds: RewardAds?
    var rewardVm: AdViewModel?
    
    var onVideoStart: (() -> Void)?
    
    var ad: Reward?
    var bannerAd: Banner?
    
    var youtubeVideoId: String?
    
    init(webResource: String? = nil, rewardVm: AdViewModel? = nil, onVideoStart: (() -> Void)? = nil, ad: Reward? = nil, youtubeVideoId: String? = nil) {
        self.webResource = webResource
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // this will not require any gesture for triggering playback
        config.mediaTypesRequiringUserActionForPlayback = []
        
        self.webView = WKWebView(frame: .zero,
                                 configuration: config)
        
        if #available(iOS 16.4, *) {
#if DEBUG
            self.webView.isInspectable = true
#endif
        } else {
            // Fallback on earlier versions
        }
        
        if let rewardVm = rewardVm {
            self.rewardVm = rewardVm
        }
        
        self.onVideoStart = onVideoStart
        
        self.ad = ad
        
        if let youtubeVideoId = youtubeVideoId {
            self.youtubeVideoId = youtubeVideoId
        }
    }
    
    func loadWebPage(webResource: String) {
        //        if let webResource = webResource {
        guard let url = URL(string: webResource) else {
            print("Bad URL")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        //        }
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
        case .showModal:
            print("show survey")
            self.isSurveyPanelShowed = true
            
            if ad != nil {
                rewardVm?.currentAd = ad
                rewardVm?.surveyUrl = message
                rewardVm?.isSurveyPanelShowed = true
            }
        case .closeModal:
            if ad != nil {
                rewardVm?.currentAd = nil
                rewardVm?.isSurveyPanelShowed = false // リワード獲得済みなのでサーベイモーダルを閉じる
                rewardVm?.isRewardCoverOpened = false
            }
            
            rewardVm?.isVideoInterrupted = false
        case .onMarkSuccess:
            // マーク完了をSDKユーザーに通知
            rewardVm?.callback?.onMarkSucceeded()
        case .onRewardFinish:
            // リワード獲得をSDKユーザーに通知
            rewardVm?.callback?.onRewardModalClosed()
        case .fetchAds:
            // 広告を取得
            Task {
                await self.rewardVm?.fetchAds()
            }
        }
    }
    
    func messageTo(message: String) {
        let escapedMessage = message.replacingOccurrences(of: "\"", with: "\\\"")
        let js = "window.postMessage(\"\(escapedMessage)\", \"*\")"
        self.webView.evaluateJavaScript(js) { (result, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
