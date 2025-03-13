//
//  RewardAd.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/21.
//
import SwiftUI

@available(iOS 13.0, *)
public struct RewardAd: View {
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
                    vm.loadWebPage(webResource: ad.webview_url.contents)
                })
                .frame(width: adVm.options?.rewardAd?.width ?? 173, height: adVm.options?.rewardAd?.height ?? 210)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Alert))
            { data in
                print("Alert notification received")
                // TODO: エラー通知
                showErrorAlert = true
            }
            .fullScreenCover(
                isPresented: $adVm.isVideoPlaying,
                content: {
                    if adVm.currentAd?.video_type == VideoType.YOUTUBE.rawValue {
                        YouTubeView(isEnded: .constant(false), videoUrl: adVm.videoUrl ?? "")
                            .environmentObject(adVm)
                    } else {
                        VideoView(isEnded: .constant(false), videoUrl: adVm.videoUrl ?? "")
                            .environmentObject(adVm)
                    }
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
            .fullScreenCover(
                isPresented: $adVm.isRewardCoverOpened,
                content: {
                    // TODO: adCallからのステータスによってパラメータを渡す
                    VStack {
                        // todo check ad call status
                        VideoRewardView(isAdCallStatus: true,
                                        landingPageUrl: adVm.currentAd?.webview_url.getting ?? ""
                        )
                        .environmentObject(adVm)
                    }
                    .background(.black.opacity(0.5))
                }
            )
            .fullScreenCover(isPresented: $adVm.isVideoInterrupted, content: {
                let vm = BaseWebViewVM()
                VStack {
                    SwiftUIWebView(viewModel: vm)
                        .onAppear() {
                            vm.rewardVm = adVm
                            vm.loadWebPage(webResource: adVm.currentAd?.webview_url.interruption ?? "")
                        }
                        .frame(alignment: .center)
                }
                .background(TransparentBackgroundView())
            })
        } else {
            // Fallback on earlier versions
            SwiftUIWebView(viewModel: vm)
                .onAppear(perform: {
                    vm.ad = ad
                    vm.rewardVm = adVm
                    vm.loadWebPage(webResource: ad.webview_url.contents)
                })
                .frame(width: adVm.options?.rewardAd?.width ?? 173, height: adVm.options?.rewardAd?.height ?? 210)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Alert))
            { data in
                print("Alert notification received")
                // TODO: エラー通知
                showErrorAlert = true
            }
            .sheet(
                isPresented: $adVm.isVideoPlaying,
                content: {
                    if adVm.currentAd?.video_type == VideoType.YOUTUBE.rawValue {
                        YouTubeView(isEnded: .constant(false), videoUrl: adVm.videoUrl ?? "")
                            .environmentObject(adVm)
                    } else {
                        VideoView(isEnded: .constant(false), videoUrl: adVm.videoUrl ?? "")
                            .environmentObject(adVm)
                    }
                })
            .sheet(
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
            .sheet(isPresented: $adVm.isSurveyPanelShowed, content: {
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
            .sheet(
                isPresented: $adVm.isRewardCoverOpened,
                content: {
                    // TODO: adCallからのステータスによってパラメータを渡す
                    VStack {
                        // todo check ad call status
                        VideoRewardView(isAdCallStatus: true,
                                        landingPageUrl: adVm.currentAd?.webview_url.getting ?? ""
                        )
                        .environmentObject(adVm)
                    }
                    .background(Color.black.opacity(0.5))
                }
            )
            .sheet(isPresented: $adVm.isVideoInterrupted, content: {
                let vm = BaseWebViewVM()
                VStack {
                    SwiftUIWebView(viewModel: vm)
                        .onAppear() {
                            vm.rewardVm = adVm
                            vm.loadWebPage(webResource: ad.webview_url.interruption)
                        }
                        .frame(alignment: .center)
                }
                .background(TransparentBackgroundView())
            })

        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var ads: [Reward] = []
    let viewModel = AdViewModel(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "reward1", runMode: RunMode.stg)
    
    List {
        ForEach($ads, id: \.index) { ad in
            RewardAd(ad: ad.wrappedValue)
                .environmentObject(viewModel)
        }
    }.onAppear {
        let body = RewardAdsRequestBody(
            user: .init(id: "user1"),
            publisher: .init(id: "publisherId", crypto: "crypto"),
            tagInfo: .init(tagGroupId: "reward1"),
            device: .init(make: DeviceInfo.make, os: DeviceInfo.os, osv: DeviceInfo.osVerion, hwv: DeviceInfo.hwv, h: DeviceInfo.height, w: DeviceInfo.width, language: DeviceInfo.language, ifa: DeviceInfo.ifa)
        )
        Task {
            let res = try await getAds(runMode: RunMode.stg, body: body)
            let ordered = res.rewardAds.sorted{$0.index < $1.index}
            print("ordered: \(ordered)")
            ads = ordered
        }
    }
}
