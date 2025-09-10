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
        let vm = BaseWebViewVM(ad: ad, rewardVm: adVm)
        SwiftUIWebView(viewModel: vm)
            .onAppear(perform: {
                if !adVm.hasImpressionBeenSent(for: ad.ad_id) {
                    vm.enableImpTracking(adType: .REWARD)
                    adVm.markImpressionSent(for: ad.ad_id)
                }
                vm.loadWebPage(webResource: ad.webview_url.contents)
            })
            .frame(width: adVm.options?.size?.width ?? 173, height: adVm.options?.size?.height ?? 210)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Alert)) { data in
                print("Alert notification received")
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
            get: { adVm.activeModal.isPresented },
            set: { newValue in
                if !newValue {
                    adVm.closeModal()
                }
            }
        )
    }

    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .fullScreenCover(
                    isPresented: isModalPresented,
                    content: {
                        if let url = adVm.activeModal.url {
                            let modalVm = BaseWebViewVM(ad: adVm.currentAd, rewardVm: adVm)
                            VStack {
                                SwiftUIWebView(viewModel: modalVm)
                                    .onAppear {
                                        modalVm.loadWebPage(webResource: url)
                                    }
                            }
                            .background(.black.opacity(0.5))
                        }
                    }
                )
        } else {
            content
                .fullScreenModal(
                    isPresented: isModalPresented,
                    content: {
                        if let url = adVm.activeModal.url {
                            let modalVm = BaseWebViewVM(ad: adVm.currentAd, rewardVm: adVm)
                            VStack {
                                SwiftUIWebView(viewModel: modalVm)
                                    .onAppear {
                                        modalVm.loadWebPage(webResource: url)
                                    }
                            }
                            .background(Color.black.opacity(0.5))
                        }
                    }
                )
        }
    }
}
