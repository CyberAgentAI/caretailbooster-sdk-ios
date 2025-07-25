import SwiftUI
import Combine

@MainActor
@available(iOS 13.0, *)
public class RetailBoosterAd: ObservableObject {
    private var viewModel: AdViewModel

    @Published public private(set) var areaName: String?
    @Published public private(set) var areaDescription: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        mediaId: String,
        userId: String,
        crypto: String,
        tagGroupId: String,
        mode: RunMode,
        callback: Callback? = nil,
        options: Options? = nil
    ) {
        self.areaName = nil
        self.areaDescription = nil
        
        // ダークモードを無効化
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = .light
        }
        
        self.viewModel = AdViewModel(
            mediaId: mediaId,
            userId: userId,
            crypto: crypto,
            tagGroupId: tagGroupId,
            runMode: mode,
            callback: callback,
            options: options
        )
        
        setupDataBinding()
    }

    deinit {
        let viewModel = self.viewModel
        Task { @MainActor in
            viewModel.resetImpressionSentAdIds()
        }
    }
    
    private func setupDataBinding() {
        viewModel.$areaName
            .sink { [weak self] newAreaName in
                self?.areaName = newAreaName
            }
            .store(in: &cancellables)
            
        viewModel.$areaDescription
            .sink { [weak self] newAreaDescription in
                self?.areaDescription = newAreaDescription
            }
            .store(in: &cancellables)
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
        } else if viewModel.adType == .REWARD {
            views = viewModel.rewardAds.map {
                AnyView(
                    RewardAd(ad: $0)
                        .environmentObject(viewModel)
                        .id("reward_\($0.index)_\(viewModel.forceRefreshToken)")
                )
            }
        } else {
            views = []
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
