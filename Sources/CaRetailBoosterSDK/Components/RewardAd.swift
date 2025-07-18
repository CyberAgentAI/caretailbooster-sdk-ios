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
        let vm = BaseWebViewVM()
        if #available(iOS 15.0, *) {
            SwiftUIWebView(viewModel: vm)
                .onAppear(perform: {
                    vm.ad = ad
                    vm.rewardVm = adVm
                    if !adVm.hasImpressionBeenSent(for: ad.ad_id) {
                        vm.enableImpTracking(adType: .REWARD)
                        adVm.markImpressionSent(for: ad.ad_id)
                    }
                    vm.loadWebPage(webResource: ad.webview_url.contents)
                })
                .frame(width: adVm.options?.rewardAd?.width ?? 173, height: adVm.options?.rewardAd?.height ?? 210)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Alert))
            { data in
                print("Alert notification received")
                // TODO: エラー通知
                showErrorAlert = true
            }
            .onDisappear(perform: {
                vm.stopTracking()
            })
            .fullScreenCover(
                isPresented: $adVm.isVideoPlaying,
                content: {
                    let videoSurveyVm = BaseWebViewVM(ad: adVm.currentAd)
                    VStack {
                        SwiftUIWebView(viewModel: videoSurveyVm)
                            .onAppear() {
                                videoSurveyVm.rewardVm = adVm
                                videoSurveyVm.loadWebPage(webResource: adVm.videoUrl ?? "")
                            }
                    }.background(.black.opacity(0.5))
                })
            .fullScreenCover(
                isPresented: $adVm.isVideoSurveyPlaying,
                content: {
                    let videoSurveyVm = BaseWebViewVM(ad: adVm.currentAd)
                    VStack {
                        SwiftUIWebView(viewModel: videoSurveyVm)
                            .onAppear() {
                                videoSurveyVm.rewardVm = adVm
                                videoSurveyVm.loadWebPage(webResource: adVm.videoSurveyUrl ?? "")
                            }
                    }.background(.black.opacity(0.5))
                })
            .fullScreenCover(isPresented: $adVm.isSurveyPanelShowed, content: {
                let surveyVm = BaseWebViewVM(ad: adVm.currentAd)
                VStack {
                    SwiftUIWebView(viewModel: surveyVm)
                        .onAppear() {
                            surveyVm.rewardVm = adVm
                            surveyVm.loadWebPage(webResource: adVm.surveyUrl ?? "")
                        }
                }.background(.black.opacity(0.5))
            })
        } else {
            // Fallback on earlier versions
            SwiftUIWebView(viewModel: vm)
                .onAppear(perform: {
                    vm.ad = ad
                    vm.rewardVm = adVm
                    if !adVm.hasImpressionBeenSent(for: ad.ad_id) {
                        vm.enableImpTracking(adType: .REWARD)
                        adVm.markImpressionSent(for: ad.ad_id)
                    }
                    vm.loadWebPage(webResource: ad.webview_url.contents)
                })
                .frame(width: adVm.options?.rewardAd?.width ?? 173, height: adVm.options?.rewardAd?.height ?? 210)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Alert))
            { data in
                print("Alert notification received")
                // TODO: エラー通知
                showErrorAlert = true
            }
            .onDisappear(perform: {
                vm.stopTracking()
            })
            .fullScreenModal(
                isPresented: $adVm.isVideoPlaying,
                content: {
                    let videoSurveyVm = BaseWebViewVM(ad: adVm.currentAd)
                    VStack {
                        SwiftUIWebView(viewModel: videoSurveyVm)
                            .onAppear() {
                                videoSurveyVm.rewardVm = adVm
                                videoSurveyVm.loadWebPage(webResource: adVm.videoUrl ?? "")
                            }
                    }.background(Color.black.opacity(0.5))
                })
            .fullScreenModal(
                isPresented: $adVm.isVideoSurveyPlaying,
                content: {
                    let videoSurveyVm = BaseWebViewVM(ad: adVm.currentAd)
                    VStack {
                        SwiftUIWebView(viewModel: videoSurveyVm)
                            .onAppear() {
                                videoSurveyVm.rewardVm = adVm
                                videoSurveyVm.loadWebPage(webResource: adVm.videoSurveyUrl ?? "")
                            }
                }.background(Color.black.opacity(0.5))
            })
            .fullScreenModal(isPresented: $adVm.isSurveyPanelShowed, content: {
                let surveyVm = BaseWebViewVM(ad: adVm.currentAd)
                VStack {
                    SwiftUIWebView(viewModel: surveyVm)
                        .onAppear() {
                            surveyVm.rewardVm = adVm
                            surveyVm.loadWebPage(webResource: adVm.surveyUrl ?? "")
                        }
                }
                .background(Color.black.opacity(0.5))
            })

        }
    }
}
