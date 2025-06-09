//
//  RetailBoosterAdView.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/31.
//
import SwiftUI

@available(iOS 13.0, *)
public struct RetailBoosterAdView: View {
    @ObservedObject var adVm: AdViewModel
    
    public init(mediaId: String, userId: String, crypto: String, tagGroupId: String, mode: RunMode, callback: Callback? = nil, options: Options? = nil) {
        self.adVm = AdViewModel(mediaId: mediaId, userId: userId, crypto: crypto, tagGroupId: tagGroupId, runMode: mode, callback: callback, options: options)
    }
    
    public var body: some View {
        let _ = adVm.forceRefreshToken
        ScrollView(.horizontal, showsIndicators: !(adVm.options?.hiddenIndicators ?? true)) {
            HStack(spacing: adVm.options?.rewardAdItemSpacing ?? 0) {
                if let leadingMargin = adVm.options?.rewardAdLeadingMargin, leadingMargin > 0 {
                    Spacer()
                        .frame(width: leadingMargin)
                }
                if $adVm.adType.wrappedValue == .BANNER {
                    ForEach($adVm.bannerAds, id: \.index) { ad in
                        BannerAd(ad: ad.wrappedValue)
                    }
                } else if $adVm.adType.wrappedValue == .REWARD {
                    ForEach($adVm.rewardAds, id: \.index) { ad in
                        RewardAd(ad: ad.wrappedValue)
                            .environmentObject(adVm)
                            .id("reward_\(ad.wrappedValue.index)_\(adVm.forceRefreshToken)")
                    }
                }
                if let trailingMargin = adVm.options?.rewardAdTrailingMargin, trailingMargin > 0 {
                    Spacer()
                        .frame(width: trailingMargin)
                }
            }
            .onAppear {
                Task {
                    await adVm.fetchAdsWithUIUpdate()
                }
            }
        }
        .environment(\.colorScheme, .light)
    }
}
