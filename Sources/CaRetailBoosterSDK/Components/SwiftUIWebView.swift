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
        print("⚪️ [SwiftUIWebView.makeUIView] Creating WebView")
        
        let userContentController = vm.webView
            .configuration
            .userContentController
        
        // Clear all message handlers, if any
        self.removeAllScriptMessageHandlers(userContentController: userContentController)
        
        // Message handler without reply
        userContentController.add(context.coordinator, name: MessageHandler.playVideo.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.showModal.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.playVideoSurvey.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.closeModal.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.onMarkSuccess.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.onRewardFinish.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.fetchAds.rawValue)
        userContentController.add(context.coordinator, name: MessageHandler.openUrl.rawValue)
        
        // Handle alert
        vm.webView.uiDelegate = context.coordinator
        
        vm.webView.navigationDelegate = context.coordinator
        
        // background color setting
        vm.webView.isOpaque = false
        vm.webView.backgroundColor = .clear
        vm.webView.scrollView.backgroundColor = .clear
        vm.webView.allowsLinkPreview = false
        vm.webView.scrollView.bouncesZoom = false
        vm.webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        
        let css = "body { -webkit-user-select: none; -webkit-touch-callout: none; }"
        let script = WKUserScript(source: "var style = document.createElement('style'); style.innerHTML = '\(css)'; document.head.appendChild(style);", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(script)
        
        let viewportScript = WKUserScript(
            source: "var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; document.getElementsByTagName('head')[0].appendChild(meta);",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(viewportScript)
        
        // window.open()を許可
        vm.webView.uiDelegate = context.coordinator
        vm.webView.navigationDelegate = context.coordinator
        
        // タップジェスチャーのデバッグ
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDebugTap))
        tapGesture.cancelsTouchesInView = false
        vm.webView.addGestureRecognizer(tapGesture)
        
        print("⚪️ [SwiftUIWebView.makeUIView] WebView created with gesture recognizer")
        
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
            print("⚪️ [webView.didFinish] URL: \(webView.url?.absoluteString ?? "nil")")
            print("⚪️ [webView.didFinish] Can evaluate JS: true")
            
            // メッセージハンドラーが登録されているか確認
            webView.evaluateJavaScript("typeof window.webkit !== 'undefined' && typeof window.webkit.messageHandlers !== 'undefined'") { result, error in
                if let result = result {
                    print("⚪️ [webView.didFinish] webkit.messageHandlers available: \(result)")
                }
                if let error = error {
                    print("🔴 [webView.didFinish] JS evaluation error: \(error)")
                }
            }
            
            // ページ読み込み完了後に可視性の監視を開始
            if viewModel.enableTracking {
                Task { @MainActor in
                    AdTracking.trackImpression(
                        webView: webView,
                        endpoint: viewModel.trackingEndpoint ?? "",
                        param: viewModel.trackingParam ?? "",
                        adId: viewModel.trackingAdId ?? 0
                    )
                    
                }
            }
            // Web view finished loading content
            print("[SwiftUIWebView] web view loaded")
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
        
        // MARK: - Debug tap handler
        @objc func handleDebugTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            print("⚪️ [handleDebugTap] Native tap detected at: \(location)")
            print("⚪️ [handleDebugTap] WebView isLoading: \(viewModel.webView.isLoading)")
            print("⚪️ [handleDebugTap] WebView URL: \(viewModel.webView.url?.absoluteString ?? "nil")")
        }
        
        // MARK: - WKScriptMessageHandler delegate function
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            print("🔵 [userContentController] START - Message received")
            print("🔵 [userContentController] Message name: \(message.name)")
            print("🔵 [userContentController] Message body: \(message.body)")
            print("🔵 [userContentController] Thread: \(Thread.isMainThread ? "Main" : "Background")")
            
            guard let fromHandler = MessageHandler(rawValue: message.name) else {
                print("🔴 [userContentController] ERROR - Unknown message handler: \(message.name)")
                return
            }
            
            print("🔵 [userContentController] Handler recognized: \(fromHandler)")
            print("🔵 [userContentController] Calling messageFrom...")
            
            self.viewModel.messageFrom(fromHandler: fromHandler, message: message.body as? String ?? "")
            
            print("🔵 [userContentController] END - messageFrom called")
        }
    }
}
