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
        userContentController.add(context.coordinator, name: MessageHandler.consoleLog.rawValue)
        
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
        
        // Inject JavaScript to fix click event issues during scroll
        let touchFixScript = WKUserScript(
            source: """
            (function() {
                // Capture console.log and send to native
                var originalLog = console.log;
                console.log = function() {
                    var message = Array.prototype.slice.call(arguments).join(' ');
                    window.webkit.messageHandlers.consoleLog.postMessage(message);
                    originalLog.apply(console, arguments);
                };

                var eventCount = 0;
                ['touchstart', 'touchend', 'click', 'mousedown', 'mouseup'].forEach(function(eventType) {
                    document.addEventListener(eventType, function(e) {
                        eventCount++;
                        console.log('🟡 [JS Event #' + eventCount + '] ' + eventType + ' on ' + e.target.tagName);
                    }, true);
                });

                // Fix: Manually trigger click when touchend fires but click doesn't
                var touchStartTime = 0;
                var touchStartTarget = null;
                var touchStartX = 0;
                var touchStartY = 0;
                var clickFired = false;

                document.addEventListener('touchstart', function(e) {
                    touchStartTime = Date.now();
                    touchStartTarget = e.target;
                    if (e.touches && e.touches[0]) {
                        touchStartX = e.touches[0].clientX;
                        touchStartY = e.touches[0].clientY;
                    }
                    clickFired = false;
                    console.log('🔵 [TouchFix] touchstart on ' + e.target.tagName + ' at (' + touchStartX + ',' + touchStartY + ')');
                }, true);

                document.addEventListener('click', function(e) {
                    clickFired = true;
                    console.log('🔵 [TouchFix] click fired naturally on ' + e.target.tagName);
                }, true);

                document.addEventListener('touchend', function(e) {
                    var touchDuration = Date.now() - touchStartTime;
                    var touchEndX = 0;
                    var touchEndY = 0;
                    if (e.changedTouches && e.changedTouches[0]) {
                        touchEndX = e.changedTouches[0].clientX;
                        touchEndY = e.changedTouches[0].clientY;
                    }
                    var distance = Math.sqrt(Math.pow(touchEndX - touchStartX, 2) + Math.pow(touchEndY - touchStartY, 2));

                    console.log('🔵 [TouchFix] touchend on ' + e.target.tagName + ' - duration: ' + touchDuration + 'ms, distance: ' + distance.toFixed(1) + 'px, clickFired: ' + clickFired);
                    console.log('🔵 [TouchFix] start target: ' + (touchStartTarget ? touchStartTarget.tagName : 'null') + ', end target: ' + e.target.tagName);

                    // If touch was short (< 300ms) and minimal movement (< 10px), simulate click
                    // Don't require exact same target element due to HTML structure (IMG inside SPAN, etc)
                    if (!clickFired && touchDuration < 300 && distance < 10) {
                        console.log('🟠 [TouchFix] Simulating click event on ' + e.target.tagName);
                        setTimeout(function() {
                            if (!clickFired) {
                                var clickEvent = new MouseEvent('click', {
                                    bubbles: true,
                                    cancelable: true,
                                    view: window,
                                    clientX: touchEndX,
                                    clientY: touchEndY
                                });
                                e.target.dispatchEvent(clickEvent);
                                console.log('🟢 [TouchFix] Click event dispatched manually on ' + e.target.tagName);
                            }
                        }, 50);
                    } else {
                        console.log('🔴 [TouchFix] Conditions not met - clickFired: ' + clickFired + ', duration: ' + touchDuration + ', distance: ' + distance.toFixed(1));
                    }
                }, true);

                // Monitor if JS execution is blocked
                setInterval(function() {
                    console.log('🟢 [JS Heartbeat] ' + new Date().getTime());
                }, 5000);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(touchFixScript)
        
        // window.open()を許可
        vm.webView.uiDelegate = context.coordinator
        vm.webView.navigationDelegate = context.coordinator
        
        // タップジェスチャーのデバッグ
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDebugTap))
        tapGesture.cancelsTouchesInView = false
        vm.webView.addGestureRecognizer(tapGesture)
        
        // Additional debugging for interaction state
        print("⚪️ [SwiftUIWebView.makeUIView] WebView isUserInteractionEnabled: \(vm.webView.isUserInteractionEnabled)")
        print("⚪️ [SwiftUIWebView.makeUIView] ScrollView delaysContentTouches: \(vm.webView.scrollView.delaysContentTouches)")
        print("⚪️ [SwiftUIWebView.makeUIView] ScrollView canCancelContentTouches: \(vm.webView.scrollView.canCancelContentTouches)")
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
            guard let fromHandler = MessageHandler(rawValue: message.name) else {
                print("�� [userContentController] ERROR - Unknown message handler: \(message.name)")
                return
            }

            // Handle console.log messages separately
            if fromHandler == .consoleLog {
                print("📱 [JS Console] \(message.body)")
                return
            }

            print("🔵 [userContentController] START - Message received")
            print("🔵 [userContentController] Message name: \(message.name)")
            print("🔵 [userContentController] Message body: \(message.body)")
            print("🔵 [userContentController] Thread: \(Thread.isMainThread ? "Main" : "Background")")
            print("🔵 [userContentController] Handler recognized: \(fromHandler)")
            print("🔵 [userContentController] Calling messageFrom...")

            self.viewModel.messageFrom(fromHandler: fromHandler, message: message.body as? String ?? "")

            print("🔵 [userContentController] END - messageFrom called")
        }
    }
}
