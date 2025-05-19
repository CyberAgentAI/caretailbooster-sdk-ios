//
//  SceneDelegate.swift
//  AdSDKSampler
//
//  Created by 依田 真明 on 1/17/25.
//

import UIKit
import SwiftUI
import CaRetailBoosterSDK

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            let contentView = ScrollView(.vertical, showsIndicators: false) {
                Text("Reward Ads")
                RetailBoosterAdView(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "reward1", mode: RunMode.mock, callback: Callback(onMarkSucceeded: {
                    print("onMarkSucceeded")
                }, onRewardModalClosed: {
                    print("onRewardModalClosed")
                }), options: Options(
                    rewardAdItemSpacing: 16,
                    rewardAdLeadingMargin: 16,
                    rewardAdTrailingMargin: 16
                ))

                Text("Banner Ads")
                RetailBoosterAdView(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "banner1", mode: RunMode.mock)

                CustomRewardAdListView()
            }
            let rootViewController = UIHostingController(rootView: contentView)
            rootViewController.view.backgroundColor = .lightGray
            window.rootViewController = rootViewController
            
            self.window = window
            window.makeKeyAndVisible()
        }   
    }
}


@available(iOS 13.0, *)
struct CustomRewardAdListView: View {
    @State private var adsLoaded = false
    @State private var adViews: [AnyView] = []

    private let columns: Int = 2
    private let spacing: CGFloat = 16

    var body: some View {
        VStack {
            if adsLoaded, !adViews.isEmpty {
                Text("Custom Reward Ads List")
                ScrollView {
                    VStack(spacing: spacing) {
                        ForEach(0..<(adViews.count + columns - 1) / columns, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<columns, id: \.self) { col in
                                    let index = row * columns + col
                                    if index < adViews.count {
                                        adViews[index]
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                    } else {
                                        Spacer()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadAds()
        }
    }

    private func loadAds() {
        let retailBoosterAd = RetailBoosterAd(
            mediaId: "media1",
            userId: "user1",
            crypto: "crypto1",
            tagGroupId: "reward1",
            mode: RunMode.mock
        )
        retailBoosterAd.getAdViews { result in
            switch result {
            case .success(let views):
                self.adViews = views
                self.adsLoaded = views.isEmpty == false
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
