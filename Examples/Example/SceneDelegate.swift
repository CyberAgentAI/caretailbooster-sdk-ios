//
//  SceneDelegate.swift
//  AdSDKSampler
//
//  Created by 依田 真明 on 1/17/25.
//

import UIKit
import SwiftUI
import CaRetailBoosterSDK
import CryptoKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
            let contentView = MainView()
            
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

extension String {
    func sha256() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

struct MainView: View {
    @State private var userId: String = ""
    @State private var isUserIdSubmitted: Bool = false
    
    // test_media を使用
    private let clientSecret = "2G5tDEJNY7vW5Gw6xqItnAjJz9ghTSwACGf1CygGUsAOeSdyOZ8gHfrbHbsS8fcA"
    
    private func generateCrypto(for userId: String) -> String {
        let combinedString = userId + clientSecret
        return combinedString.sha256()
    }
    
    var body: some View {
        VStack {
            if !isUserIdSubmitted {
                VStack(spacing: 20) {
                    Text("ユーザーIDの設定")
                        .font(.headline)
                    
                    TextField("ユーザーIDを入力してください", text: $userId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("送信") {
                        if !userId.isEmpty {
                            isUserIdSubmitted = true
                        }
                    }
                    .frame(width: 100, height: 25)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Reward Ads")
                            .font(.headline)
                        
                        RetailBoosterAdView(
                            mediaId: "1234567890abcdef",
                            userId: userId,
                            crypto: generateCrypto(for: userId),
                            tagGroupId: "0853bf57-70b4-4ddc-b57c-507c196abfca",
                            mode: RunMode.stg,
                            callback: Callback(
                                onMarkSucceeded: {
                                    print("onMarkSucceeded")
                                },
                                onRewardModalClosed: {
                                    print("onRewardModalClosed")
                                }
                            )
                        )
                        
                        Text("Banner Ads")
                            .font(.headline)
                        
                        RetailBoosterAdView(
                            mediaId: "1234567890abcdef",
                            userId: userId,
                            crypto: generateCrypto(for: userId),
                            tagGroupId: "ac0ebf99-f89f-40e5-95ce-09558cf993cc",
                            mode: RunMode.stg
                        )
                        
                        Button("別のユーザーIDで再設定") {
                            userId = ""
                            isUserIdSubmitted = false
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 30)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(Color.blue.opacity(0.2))
                }
            }
        }
    }
}
