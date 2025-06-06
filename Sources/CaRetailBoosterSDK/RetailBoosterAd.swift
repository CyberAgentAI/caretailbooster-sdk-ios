import SwiftUI

@MainActor
@available(iOS 13.0, *)
public class RetailBoosterAd {
    private var viewModel: AdViewModel
    
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        mode: RunMode,
        callback: Callback? = nil,
        options: Options? = nil
    ) {
        self.viewModel = AdViewModel(
            mediaId: mediaId,
            userId: userId,
            crypto: crypto,
            tagGroupId: tagGroupId,
            runMode: mode,
            callback: callback,
            options: options
        )
    }
    deinit {
        let viewModel = self.viewModel
        Task { @MainActor in
            viewModel.resetImpressionSentAdIds()
        }
    }

    public func getAdViews(completion: @escaping (Result<[AnyView], Error>) -> Void) {
        Task {
            do {
                await viewModel.fetchAdsWithUIUpdate()
                let views = getCurrentAdViews()
                completion(.success(views))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func getCurrentAdViews() -> [AnyView] {
        let views: [AnyView]
        
        if viewModel.adType == .BANNER {
            views = viewModel.bannerAds.map { AnyView(BannerAd(ad: $0)) }
        } else {
            views = viewModel.rewardAds.map { 
                AnyView(
                    RewardAd(ad: $0)
                        .environmentObject(viewModel)
                        .id("reward_\($0.index)_\(viewModel.forceRefreshToken)")
                )
            }
        }
        
        return views
    }

    public func loadAds(completion: @escaping (Error?) -> Void) {
        Task {
            do {
                await viewModel.fetchAdsWithUIUpdate()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
