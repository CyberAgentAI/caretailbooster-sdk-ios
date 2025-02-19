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
            
            let contentView = VStack {
                Text("Reward Ads")
                RetailBoosterAdView(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "reward1", runMode: RunMode.local, callback: Callback(onMarkSucceeded: {
                    print("onMarkSucceeded")
                }, onRewardModalClosed: {
                    print("onRewardModalClosed")
                }))
                
                Text("Banner Ads")
                RetailBoosterAdView(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "banner1", runMode: RunMode.local)
            }
                .background(Color.blue.opacity(0.2))
            
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
