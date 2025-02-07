import SwiftUI
import AVKit
import NotificationCenter

@available(iOS 13.0, *)
public struct YouTubeView: View {
    @EnvironmentObject var rewardAdVm: AdViewModel
    @Binding var isEnded: Bool
    @State var timeText: String = ""
    var videoDuration: Double = 0
    @State var isMuted: Bool = true
    var vm: BaseWebViewVM
    var videoUrl: String
    
    init(isEnded: Binding<Bool>, videoUrl: String) {
        _isEnded = isEnded
        
        self.vm = BaseWebViewVM()
        self.videoUrl = videoUrl
    }
    
    var pub = NotificationCenter.default.publisher(
        for: .AVPlayerItemDidPlayToEndTime
    )
    
    public var body: some View {
        VStack {
            SwiftUIWebView(viewModel: vm)
                .onAppear() {
                    vm.rewardVm = rewardAdVm
                    // YouTube再生用WebページのURLをロードする
                    vm.loadWebPage(webResource: videoUrl)
                }
        }
        // TODO: 再生中は背景を黒にし、再生終了後投下させるUIを実装する.
        .background(Color.black)
    }
}

#Preview {
    YouTubeView(
        isEnded: .constant(false),
        videoUrl: "http://localhost:3000/youtube.html?videoId=fOnj3_aNDGQ"
    )
    .environmentObject(AdViewModel(mediaId: "media1", userId: "user1", crypto: "crypto1", tagGroupId: "reward1", runMode: RunMode.stg))
}
