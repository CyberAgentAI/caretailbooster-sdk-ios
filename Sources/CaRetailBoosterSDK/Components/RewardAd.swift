//
//  RewardAd.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/21.
//
import SwiftUI

@available(iOS 13.0, *)
struct RewardAd: View {
    @EnvironmentObject var adVm: AdViewModel
    @State var showErrorAlert: Bool = false
    let ad: Reward
    
    public init(ad: Reward) {
        self.ad = ad
    }
    
    public var body: some View {
        let vm = adVm.getOrCreateRewardVM(for: ad)
        SwiftUIWebView(viewModel: vm)
            .onAppear(perform: {
                if !adVm.hasImpressionBeenSent(for: ad.ad_id) {
                    vm.enableImpTracking(adType: .REWARD)
                    adVm.markImpressionSent(for: ad.ad_id)
                }
                // 既に事前ロード済みの場合はスキップされる
                vm.loadWebPageOnce(webResource: ad.webview_url.contents)
            })
            .frame(width: adVm.options?.size?.width ?? 173, height: adVm.options?.size?.height ?? 210)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Alert)) { data in
                print("[RewardAd] Alert notification received")
                // TODO: エラー通知
                showErrorAlert = true
            }
            .onDisappear(perform: {
                vm.stopTracking()
            })
            .modifier(RewardModalModifier(adVm: adVm))
    }
}

@available(iOS 13.0, *)
private struct RewardModalModifier: ViewModifier {
    @ObservedObject var adVm: AdViewModel
    
    private var isModalPresented: Binding<Bool> {
        Binding(
            get: { 
                let isPresented = adVm.activeModal.isPresented
                print("🟣 [RewardModalModifier] isModalPresented.get: \(isPresented)")
                return isPresented
            },
            set: { newValue in
                print("🟣 [RewardModalModifier] isModalPresented.set: \(newValue)")
                if !newValue {
                    adVm.closeModal()
                }
            }
        )
    }

    func body(content: Content) -> some View {
        let _ = print("🟣 [RewardModalModifier.body] Building view")
        let _ = print("🟣 [RewardModalModifier.body] activeModal.isPresented: \(adVm.activeModal.isPresented)")
        let _ = print("🟣 [RewardModalModifier.body] activeModal.url: \(adVm.activeModal.url ?? "nil")")
        
        if #available(iOS 15.0, *) {
            content
                .fullScreenCover(
                    isPresented: isModalPresented,
                    onDismiss: {
                        print("🟣 [RewardModalModifier] fullScreenCover dismissed")
                    },
                    content: {
                        let _ = print("🟣 [RewardModalModifier] fullScreenCover content building")
                        if let url = adVm.activeModal.url {
                            let _ = print("🟣 [RewardModalModifier] URL available: \(url)")
                            let modalVm = BaseWebViewVM(ad: adVm.currentAd, rewardVm: adVm)
                            VStack {
                                SwiftUIWebView(viewModel: modalVm)
                                    .onAppear {
                                        print("🟣 [RewardModalModifier] Modal WebView appeared")
                                        modalVm.loadWebPage(webResource: url)
                                    }
                            }
                            .background(.black.opacity(0.5))
                        } else {
                            let _ = print("🔴 [RewardModalModifier] ERROR - URL is nil in content block")
                            EmptyView()
                        }
                    }
                )
        } else {
            content
                .fullScreenModal(
                    isPresented: isModalPresented,
                    content: {
                        let _ = print("🟣 [RewardModalModifier] fullScreenModal content building (iOS <15)")
                        if let url = adVm.activeModal.url {
                            let _ = print("🟣 [RewardModalModifier] URL available (iOS <15): \(url)")
                            let modalVm = BaseWebViewVM(ad: adVm.currentAd, rewardVm: adVm)
                            VStack {
                                SwiftUIWebView(viewModel: modalVm)
                                    .onAppear {
                                        print("🟣 [RewardModalModifier] Modal WebView appeared (iOS <15)")
                                        modalVm.loadWebPage(webResource: url)
                                    }
                            }
                            .background(Color.black.opacity(0.5))
                        } else {
                            let _ = print("🔴 [RewardModalModifier] ERROR - URL is nil in content block (iOS <15)")
                            EmptyView()
                        }
                    }
                )
        }
    }
}
