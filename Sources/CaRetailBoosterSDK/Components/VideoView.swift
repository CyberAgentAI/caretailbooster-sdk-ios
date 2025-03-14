import SwiftUI
import AVKit
import NotificationCenter


@available(iOS 13.0, *)
// Create a UIViewControllerRepresentable for AVPlayer
struct AVPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update the player if needed
    }
}

@MainActor
@available(iOS 13.0, *)
public struct VideoView: View {
    @EnvironmentObject var rewardAdVm: AdViewModel
    @Binding var isEnded: Bool
    var player: AVPlayer
    @State var timeText: String = ""
    var videoDuration: Double = 0
    @State var isMuted: Bool = true
    var isGranted: Bool = false
    
    init(isEnded: Binding<Bool>, videoUrl: String, isGranted: Bool) {
        player = AVPlayer(url: URL(string: videoUrl)!)
        _isEnded = isEnded
        // ミュート状態で再生を開始
        player.isMuted = true
        self.isGranted = isGranted
        
        // トータルの再生時間取得
        // TODO 計算に時間がかかってUIをブロッキングするのでadのdurationを使う
        if let currentItem = player.currentItem {
            let duration = CMTimeGetSeconds(currentItem.asset.duration)
            print("Duration: \(duration) s")
            videoDuration = duration
        }
    }
    
    var pub = NotificationCenter.default.publisher(
        for: .AVPlayerItemDidPlayToEndTime
    )
    
    public var body: some View {
        VStack {
            HStack {
                // mute/unmute button
                Button(action: {
                    player.isMuted.toggle()
                    isMuted = player.isMuted
                }, label: {
                    Image(systemName: $isMuted.wrappedValue ? "speaker.slash" : "speaker.3")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.white)
                })
                .padding(.leading, 10)
                
                Spacer()
                
                // close fullscreen button
                Button(action: {
                    player.replaceCurrentItem(with: nil)
                    rewardAdVm.isVideoPlaying = false
                    
                    // 途中で再生を停止した場合、リワードを獲得できない旨をユーザーに通知する
                    // 獲得済みの場合は通知しない
                    rewardAdVm.isVideoInterrupted = !self.isGranted
                }, label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                })
                .padding(.trailing, 10)
            }
            .padding(.top, 80) // 上部のセーフエリアと被るので余白を入れる
            
            AVPlayerView(player: player) // iOS >= 14 であればVideoPlayer(https://developer.apple.com/documentation/avkit/videoplayer)が使える
                .disabled(true) // ユーザーが動画をコントロールできないようにする
                .onReceive(pub, perform: {_ in
                    Task {
                        do {
                            // 再生終了時のイベントをトラッキングサーバーに送信
                            try await AdTracking.view(endpoint: rewardAdVm.currentAd?.view_url ?? "", param: rewardAdVm.currentAd?.param ?? "", videoProgressEvent: VideoProgressEvent.end)
                        } catch {
                            print("Error: \(error)")
                            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
                        }
                    }
                    
                    // モーダルを閉じる
                    isEnded = true
                    rewardAdVm.isVideoPlaying = false
                    // 獲得済みの場合、リワード獲得UIは表示しない
                    rewardAdVm.isRewardCoverOpened = !self.isGranted
                })
                .onAppear {
                    player.play()
                    
                    var is25PercentSent = false
                    var is50PercentSent = false
                    var is75PercentSent = false
                    
                    Task {
                        do {
                            // 再生開始時のイベントをトラッキングサーバーに送信
                            try await AdTracking.view(endpoint: rewardAdVm.currentAd?.view_url ?? "", param: rewardAdVm.currentAd?.param ?? "", videoProgressEvent: VideoProgressEvent.start)
                        } catch {
                            print("Error: \(error)")
                            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
                        }
                    }
                    
                    // 定期的に再生ポジションをチェックしてトラッキングサーバーにイベントを送る
                    player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { (time) in
                        let currentTime = time.seconds
                        let minutes = Int(currentTime) / 60
                        let seconds = Int(currentTime) % 60
                        Task {
                            await MainActor.run {
                                timeText = String(format: "%02d:%02d / %02d:%02d", minutes, seconds, Int(videoDuration) / 60, Int(videoDuration) % 60)
                                
                                
                                let position = Int(floor((time.seconds / videoDuration) * 100))
                                print("position(%):", position)
                                
                                // 25%再生時のイベントをトラッキングサーバーに送信
                                if position >= 25 && !is25PercentSent {
                                    Task {
                                        do {
                                            try await AdTracking.view(endpoint: rewardAdVm.currentAd?.view_url ?? "", param: rewardAdVm.currentAd?.param ?? "", videoProgressEvent: VideoProgressEvent.quarter)
                                        } catch {
                                            print("Error: \(error)")
                                            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
                                        }
                                    }
                                    is25PercentSent = true
                                }
                                
                                // 50%再生時のイベントをトラッキングサーバーに送信
                                if position >= 50 && !is50PercentSent {
                                    Task {
                                        do {
                                            try await AdTracking.view(endpoint: rewardAdVm.currentAd?.view_url ?? "", param: rewardAdVm.currentAd?.param ?? "", videoProgressEvent: VideoProgressEvent.half)
                                        } catch {
                                            print("Error: \(error)")
                                            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
                                        }
                                    }
                                    is50PercentSent = true
                                }
                                
                                // 75%再生時のイベントをトラッキングサーバーに送信
                                if position >= 75 && !is75PercentSent {
                                    Task {
                                        do {
                                            try await AdTracking.view(endpoint: rewardAdVm.currentAd?.view_url ?? "", param: rewardAdVm.currentAd?.param ?? "", videoProgressEvent: VideoProgressEvent.threeQuarter)
                                        } catch {
                                            print("Error: \(error)")
                                            NotificationCenter.default.post(name: NSNotification.Alert, object: nil)
                                        }
                                    }
                                    is75PercentSent = true
                                }
                            }
                        }
                    })
                }
            
            HStack {
                // show play time
                Text($timeText.wrappedValue)
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                
                Spacer()
            }
            .padding(.bottom, 50) // 下部のセーフエリアと被るので余白を入れる
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all) // iOS <= 14でセーフエリアにバックグラウンドカラーが設定されるようにする
    }
}

#Preview {
    let vm = AdViewModel(mediaId: "123", userId: "456", crypto: "789", tagGroupId: "abc", runMode: RunMode.stg)
    
    VideoView(
        isEnded: .constant(false),
        videoUrl: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4",
        isGranted: false
    )
    .onAppear {
        vm.currentAd = Reward(index: 1, tag_id: "tag-id1", format_type: AdFormatType.VIDEO.rawValue, video_type: VideoType.STANDARD.rawValue, is_granted: true, webview_url: AdWebViewUrl(contents: "http://localhost:3000/reward.html", getting: "http://localhost:3000/survey.html", interruption: "http://localhost:3000/message/interrupt"), imp_url: "http://localhost:3000/api/imp/imp", view_url: "http://localhost:3000/api/view/view", param: "param1")
    }
    .environmentObject(vm)
}
