import SwiftUI
import WebKit

@available(iOS 13.0, *)
struct SwiftUIWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    var vm: BaseWebViewVM
    init(viewModel: BaseWebViewVM) {
        self.vm = viewModel
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let userContentController = vm.webView
            .configuration
            .userContentController
        
        // Clear all message handlers, if any
        self.removeAllScriptMessageHandlers(userContentController: userContentController)
        
        // Message handler without reply
        userContentController.add(context.coordinator, name: MessageHandler.playVideo.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.showModal.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.closeModal.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.onMarkSuccess.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.onRewardFinish.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.fetchAds.rawValue)
        
        // Handle alert
        vm.webView.uiDelegate = context.coordinator
        
        vm.webView.navigationDelegate = context.coordinator
        
        // background color setting
        vm.webView.isOpaque = false
        vm.webView.backgroundColor = .clear
        vm.webView.scrollView.backgroundColor = .clear
        
        // window.open()を許可
        vm.webView.uiDelegate = context.coordinator
        vm.webView.navigationDelegate = context.coordinator
        
        
        return vm.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: vm)
    }
    
    private func removeAllScriptMessageHandlers(userContentController: WKUserContentController) {
        for name in MessageHandler.allCases {
            userContentController.removeScriptMessageHandler(forName: name.rawValue)
        }
    }
}

@available(iOS 13.0, *)
extension SwiftUIWebView {
    class Coordinator: NSObject, WKUIDelegate,
                       WKScriptMessageHandler, WKNavigationDelegate {
        // webviewのロードが完了した後に受け取るイベント
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            // Web view finished loading content
            print("web view loaded")
        }
        
        // `window.open()` のリクエストを Safari で開く
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return nil
        }
        
        var viewModel: BaseWebViewVM
        
        init(viewModel: BaseWebViewVM) {
            self.viewModel = viewModel
        }
        
        // MARK: - WKScriptMessageHandler delegate function
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let fromHandler = MessageHandler(rawValue: message.name) else {
                return
            }
            self.viewModel.messageFrom(fromHandler: fromHandler, message: message.body as? String ?? "")
        }
    }
}

@available(iOS 13.0, *)
struct SwiftUIWebView_Previews: PreviewProvider {
    static let vm = BaseWebViewVM(webResource: "ad.html",
                                  ad: Reward(
                                    index: 1,
                                    tag_id: "tag_id_1",
                                    format_type: "VIDEO",
                                    video_type: "STANDARD",
                                    is_granted: false,
                                    webview_url: AdWebViewUrl(contents: "http://localhost:3000/reward.html", getting: "http://localhost:3000/survey.html", interruption: "http://localhost:3000/message/interrupt"),
                                    imp_url: "http://localhost:3000/imp/imp",
                                    view_url: "http://localhost:3000/view/view",
                                    param: "param"
                                  )
    )
    
    static var previews: some View {
        SwiftUIWebView(viewModel: vm)
            .onAppear(perform: { vm.loadWebPage(webResource: "http://localhost:3000/reward/1")
            })
    }
}
