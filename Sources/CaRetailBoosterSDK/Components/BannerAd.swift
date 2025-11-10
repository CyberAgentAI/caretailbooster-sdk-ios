//
//  BannerAd.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/31.
//

import SwiftUI

@available(iOS 13.0, *)
struct BannerAd: View {
    @EnvironmentObject var adVm: AdViewModel
    let ad: Banner
    
    public init (ad: Banner) {
        self.ad = ad
    }
    
    public var body: some View {
        let vm = adVm.getOrCreateBannerVM(for: ad)
        SwiftUIWebView(viewModel: vm)
            .onAppear(perform: {
                vm.enableImpTracking(adType: .BANNER)
                // 既に事前ロード済みの場合はスキップされる
                vm.loadWebPageOnce(webResource: ad.webview_url)
            })
            .frame(
                width: adVm.bannerOptions?.size?.width ?? CGFloat(ad.width),
                height: adVm.bannerOptions?.size?.height ?? CGFloat(ad.height)
            )
            .onDisappear(perform: {
                vm.stopTracking()
            })
    }
}
