import UIKit
import SwiftUI
import CaRetailBoosterSDK
import Combine

// MARK: - Constants

struct Constants {
    // SDK Configuration
    static let mediaId = "media1"
    static let userId = "user1"
    static let crypto = "crypto1"
    static let mode = RtBRunMode.local

    // Tag Group IDs
    static let bannerTagGroupId = "banner1"
    static let rewardTagGroupId = "reward1"
    static let popupTagGroupId = "popup1"
}

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Initialize RetailBooster SDK
        RetailBooster.initialize(mediaId: Constants.mediaId, mode: Constants.mode)
        RetailBooster.setUserInfo(userId: Constants.userId, crypto: Constants.crypto)
        // Set log level
        RetailBooster.setLogLevel(.debug)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            let contentView = ExampleContentView()
            let rootViewController = UIHostingController(rootView: contentView)
            rootViewController.view.backgroundColor = .white
            window.rootViewController = rootViewController

            self.window = window
            window.makeKeyAndVisible()
        }
    }
}


// MARK: - Main Example Content View

@available(iOS 13.0, *)
struct ExampleContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BannerAdExampleView()
                Divider()
                RewardAdExampleView()
                Divider()
                PopupAdExampleView()
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Banner Ad Example

@available(iOS 13.0, *)
struct BannerAdExampleView: View {
    @State private var bannerAd: RtBBannerAd?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Banner Ads")
                .font(.title)
                .fontWeight(.bold)

            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }

            if isLoading {
                Text("Loading ads...")
                    .padding()
            }

            if let ad = bannerAd {
                VStack(spacing: 10) {
                    if let areaName = ad.areaName {
                        Text(areaName)
                            .font(.headline)
                    }
                    if let areaDescription = ad.areaDescription {
                        Text(areaDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    ForEach(ad.views.indices, id: \.self) { index in
                        ad.views[index]
                    }
                }
            }
        }
        .onAppear {
            loadBannerAds()
        }
    }

    private func loadBannerAds() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let ad = RtBBannerAd(
            tagGroupId: Constants.bannerTagGroupId,
            eventName: "banner_example",
            options: RtBBannerOptions(size: RtBSizeOption(width: 360, height: 120))
        )

        Task {
            do {
                try await ad.load()
                await MainActor.run {
                    self.bannerAd = ad
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Reward Ad Example

@available(iOS 13.0, *)
struct RewardAdExampleView: View {
    @State private var rewardAd: RtBRewardAd?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var rewardMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Reward Ads")
                .font(.title)
                .fontWeight(.bold)

            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }

            if let message = rewardMessage {
                Text(message)
                    .foregroundColor(.green)
                    .padding()
            }

            if isLoading {
                Text("Loading ads...")
                    .padding()
            }

            if let ad = rewardAd {
                VStack(spacing: 10) {
                    if let areaName = ad.areaName {
                        Text(areaName)
                            .font(.headline)
                    }
                    if let areaDescription = ad.areaDescription {
                        Text(areaDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Horizontal scroll for reward ads
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(ad.views.indices, id: \.self) { index in
                                ad.views[index]
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            loadRewardAds()
        }
    }

    private func loadRewardAds() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        rewardMessage = nil

        let ad = RtBRewardAd(
            tagGroupId: Constants.rewardTagGroupId,
            eventName: "reward_example",
            options: RtBRewardOptions(
                size: RtBSizeOption(width: 180, height: 270)
            )
        ) { callback in
            callback.onMarkSucceeded = {
                print("Reward mark succeeded!")
            }
            callback.onRewardModalClosed = {
                print("Reward modal closed")
            }
        }

        Task {
            do {
                try await ad.load()
                await MainActor.run {
                    self.rewardAd = ad
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Popup Ad Example

@available(iOS 13.0, *)
struct PopupAdExampleView: View {
    @State private var popupAd: RtBPopupAd?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var statusMessage: String = "Not loaded"

    var body: some View {
        VStack(spacing: 20) {
            Text("Popup Ads")
                .font(.title)
                .fontWeight(.bold)

            Text("Status: \(statusMessage)")
                .foregroundColor(.blue)

            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }

            if isLoading {
                Text("Loading popup ad...")
            }

            HStack(spacing: 16) {
                Button("Load Popup Ad") {
                    loadPopupAd()
                }
                .disabled(isLoading || popupAd != nil)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Show Popup Ad") {
                    showPopupAd()
                }
                .disabled(popupAd == nil)
                .padding()
                .background(popupAd != nil ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }

    private func loadPopupAd() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        statusMessage = "Loading..."

        let ad = RtBPopupAd(
            tagGroupId: Constants.popupTagGroupId,
            eventName: "popup_example"
        ) { callback in
            callback.onClose = {
                print("Popup closed")
            }
            callback.onOuterLink = { url in
                print("Outer link clicked: \(url)")
            }
            callback.onInnerLink = { url in
                print("Inner link clicked: \(url)")
            }
        }

        Task {
            do {
                try await ad.load()
                await MainActor.run {
                    self.popupAd = ad
                    self.statusMessage = "Loaded successfully"
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Load failed"
                    self.isLoading = false
                }
            }
        }
    }

    private func showPopupAd() {
        guard let ad = popupAd else { return }
        ad.show()
        statusMessage = "Popup shown"
    }
}
