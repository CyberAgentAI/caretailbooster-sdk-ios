//
//  BannerAd.swift
//  AdSDKSampler
//
//  Created by 田中 穏識 on 2025/01/31.
//

import SwiftUI

@available(iOS 13.0, *)
public struct BannerAd: View {
    let ad: Banner
    
    public var body: some View {
        let vm = BaseWebViewVM()
        SwiftUIWebView(viewModel: vm)
            .onAppear() {
                vm.loadWebPage(webResource: ad.webview_url)
            }
            .frame(width: CGFloat(ad.width), height: CGFloat(ad.height))
    }
}
