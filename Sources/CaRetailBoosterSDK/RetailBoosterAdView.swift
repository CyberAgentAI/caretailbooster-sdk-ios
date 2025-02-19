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
    
    public init(mediaId: String, userId: String, crypto: String, tagGroupId: String, runMode: RunMode, callback: Callback? = nil, options: Options? = nil) {
        self.adVm = AdViewModel(mediaId: mediaId, userId: userId, crypto: crypto, tagGroupId: tagGroupId, runMode: runMode, callback: callback, options: options)
    }
    
    public var body: some View {
        ScrollView(.horizontal) {
            HStack {
                if $adVm.adType.wrappedValue == .BANNER {
                    ForEach($adVm.bannerAds, id: \.index) { ad in
                        BannerAd(ad: ad.wrappedValue)
                    }
                } else if $adVm.adType.wrappedValue == .REWARD {
                    ForEach($adVm.rewardAds, id: \.index) { ad in
                        RewardAd(ad: ad.wrappedValue)
                            .environmentObject(adVm)
                    }
                }
            }
            .onAppear {
                Task {
                    await adVm.fetchAds()
                }
            }
        }
    }
}
