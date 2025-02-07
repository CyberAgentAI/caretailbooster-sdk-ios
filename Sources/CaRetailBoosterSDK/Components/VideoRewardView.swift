import SwiftUI

@available(iOS 13.0, *)
public struct VideoRewardView: View {
    @EnvironmentObject var rewardAdVm: AdViewModel
    let vm: BaseWebViewVM
    let landingPageUrl: String
    let isAdCallStatus: Bool
    
    init(isAdCallStatus: Bool, landingPageUrl: String) {
        self.landingPageUrl = landingPageUrl
        self.isAdCallStatus = isAdCallStatus

        vm = BaseWebViewVM()
    }
    
    public var body: some View {
        VStack {
            SwiftUIWebView(viewModel: vm)
                .onAppear(perform: {
                    vm.ad = rewardAdVm.currentAd
                    vm.rewardVm = rewardAdVm
                    
                    // TODO: isAdCallStatusによってリワードを出し分ける
                    if isAdCallStatus {
                        // event=getRewardをURL parameterに付与
                        vm.loadWebPage(webResource: self.landingPageUrl)
                    } else {
                        // event=failedGetRewardをURL parameterに付与
                        vm.loadWebPage(webResource: self.landingPageUrl)
                    }
                })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@available(iOS 13.0, *)
#Preview {
    VideoRewardView(isAdCallStatus: true, landingPageUrl: "http://localhost:3000/coupon/1")
        .environmentObject(AdViewModel(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "reward1", runMode: RunMode.stg))
}
