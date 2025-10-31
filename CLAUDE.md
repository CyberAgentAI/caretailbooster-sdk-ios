# CLAUDE.md

このファイルは、Claude Code（claude.ai/code）がこのリポジトリで作業する際のガイダンスを提供します。

## CaRetailBoosterSDK iOS 概要

リテール向け iOS アプリケーションにバナー広告とリワード広告機能を提供する広告 SDK です。retaiboo.com 広告プラットフォームと統合し、プログラマティック API と SwiftUI 宣言的 API の両方をサポートしています。

## 開発コマンド

### Example アプリのビルドと実行

コマンドラインから実行する場合：

```bash
cd Examples
make build    # デフォルトシミュレータ向けビルド
make run      # デフォルトシミュレータでビルド＆実行
make release  # リリースバージョンのビルド
make clean    # ビルドディレクトリのクリーン
make list     # 利用可能なシミュレータ一覧
make list-booted  # 起動中のシミュレータ一覧
```

もしくは通常通り Xcode から実行してください：

1. `Examples/Example.xcodeproj`を Xcode で開く
2. スキームとシミュレータを選択
3. ⌘+R でビルド＆実行

### パッケージ管理

- **Swift Package Manager**: `Package.swift`で定義される配布方法
- **CocoaPods**: `CaRetailBoosterSDK.podspec`で定義される配布方法

### テスト

```bash
swift test              # すべてのユニットテストを実行
swift test --filter RtBBannerAdTests  # 特定のテストクラスのみ実行
```

テストは `Tests/CaRetailBoosterSDKTests/` ディレクトリに配置されています。XCTest フレームワークを使用し、以下のテストが含まれます：

- RtBBannerAdTests: バナー広告のテスト
- RtBRewardAdTests: リワード広告のテスト
- RtBPopupAdTests: ポップアップ広告のテスト
- RetailBoosterTests: メインインターフェースのテスト

## アーキテクチャ

### コアコンポーネント

- **RetailBooster**: メイン SDK エントリーポイント（初期化と設定）
- **RtBBannerAd**: バナー広告の SwiftUI ビュー
- **RtBRewardAd**: リワード広告の SwiftUI ビュー
- **RtBPopupAd**: ポップアップ広告の SwiftUI ビュー
- **AdViewModel**: Combine を使用した中央状態管理（@Published プロパティ）
- **AdCall**: 広告取得のための API サービス（URLSession による非同期通信）
- **AdTracking**: インプレッションとビュートラッキングサービス（ビューアビリティ測定）

### UI コンポーネント

- **BannerAd**: バナー広告（サイズはオプションで指定可能）
- **RewardAd**: リワード付きインタラクティブ広告（動画/アンケート）- フルスクリーンモーダル制御
- **SwiftUIWebView**: Web コンテンツ用の WebKit ラッパー（JavaScript-Swift 間通信）
- **RewardModalModifier**: iOS 15以上/以下に対応したモーダル表示の統一実装

### データフロー

1. **初期化**: RetailBooster.initialize() で SDK を初期化し、setUserInfo() でユーザー情報を設定
2. **広告読み込み**: RtBBannerAd/RtBRewardAd/RtBPopupAd の load() メソッドを呼び出し
3. **広告取得**: AdViewModel が内部で getAds() を呼び出し、設定された環境エンドポイントから広告データを取得
4. **データ処理**: 取得した広告データ（bannerAds、rewardAds）と TagGroup 情報（areaName、areaDescription）を保存
5. **ビュー生成**: 各広告クラスの views プロパティから SwiftUI ビューを取得
6. **インタラクション**:
   - リワード広告: JavaScript メッセージに応じて ModalType（video/videoSurvey/survey）でモーダル表示
   - ポップアップ広告: show() メソッドで表示タイミングを制御
7. **トラッキング**: AdTracking がインプレッションと広告の可視性を記録（広告面積の50%以上が1秒以上表示された時点で計測）
8. **コールバック**: リワード獲得やモーダル閉じるなどのイベントをコールバック経由でホストアプリに通知

## 環境設定

SDK は`mode`パラメータで複数の環境をサポート：

- `local`: http://localhost:3000/api/ads
- `dev`: https://dev-ad.retaiboo.com/ad/v1
- `stg`: https://stg-ad.retaiboo.com/ad/v1
- `prd`: https://ad.retaiboo.com/ad/v1
- `mock`: https://mock.retaiboo.com/ad/v1

## 主要な実装詳細

### SDK 初期化

アプリ起動時（SceneDelegate または AppDelegate）で SDK を初期化します。

```swift
import CaRetailBoosterSDK

// SDK の初期化
RetailBooster.initialize(mediaId: "your_media_id", mode: .prd)

// ユーザー情報の設定
RetailBooster.setUserInfo(userId: "user123", crypto: "encrypted_value")

// ログレベルの設定（デバッグ時）
RetailBooster.setLogLevel(.debug)
```

### バナー広告の実装

```swift
struct BannerAdExampleView: View {
    @State private var bannerAd: RtBBannerAd?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }

            if isLoading {
                Text("Loading ads...")
            }

            if let ad = bannerAd {
                VStack(spacing: 10) {
                    // エリア名と説明を表示
                    if let areaName = ad.areaName {
                        Text(areaName).font(.headline)
                    }
                    if let areaDescription = ad.areaDescription {
                        Text(areaDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // 広告ビューを表示
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
            tagGroupId: "your_tag_group_id",
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
```

### リワード広告の実装

```swift
struct RewardAdExampleView: View {
    @State private var rewardAd: RtBRewardAd?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }

            if isLoading {
                Text("Loading ads...")
            }

            if let ad = rewardAd {
                VStack(spacing: 10) {
                    if let areaName = ad.areaName {
                        Text(areaName).font(.headline)
                    }
                    if let areaDescription = ad.areaDescription {
                        Text(areaDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // 横スクロールでリワード広告を表示
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

        let ad = RtBRewardAd(
            tagGroupId: "your_tag_group_id",
            eventName: "reward_example",
            options: RtBRewardOptions(
                size: RtBSizeOption(width: 180, height: 270)
            )
        ) { callback in
            callback.onMarkSucceeded = {
                print("リワード獲得成功！")
            }
            callback.onRewardModalClosed = {
                print("リワードモーダルが閉じられました")
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
```

### ポップアップ広告の実装

```swift
struct PopupAdExampleView: View {
    @State private var popupAd: RtBPopupAd?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var statusMessage: String = "Not loaded"

    var body: some View {
        VStack(spacing: 20) {
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
            tagGroupId: "your_tag_group_id",
            eventName: "popup_example"
        ) { callback in
            callback.onClose = {
                print("ポップアップが閉じられました")
            }
            callback.onOuterLink = { url in
                print("外部リンクがクリックされました: \(url)")
            }
            callback.onInnerLink = { url in
                print("内部リンクがクリックされました: \(url)")
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
```

### 重要なポイント

1. **非同期処理**: すべての広告読み込みは `async/await` を使用
2. **エラーハンドリング**: `try/catch` で適切にエラーを処理
3. **State 管理**: `@State` を使用して読み込み状態とエラーを管理
4. **コールバック**: リワード広告とポップアップ広告はコールバックで各種イベントを受け取る
5. **エリア情報**: `areaName` と `areaDescription` でエリアベースの広告グループ情報を取得可能
6. **ポップアップ広告**: `load()` と `show()` を分離して、表示タイミングを制御可能

## プロジェクト構造

```
Sources/CaRetailBoosterSDK/
├── Components/           # UI コンポーネント（BannerAd、RewardAd、SwiftUIWebView）
├── Const/                # 定数定義（サーバーURL等）
├── Models/               # データモデルと設定型（ModalType、Callback、Options、RunMode）
├── Protocols/            # プロトコル定義
├── Services/             # ビジネスロジック（AdCall、AdTracking、Notification）
├── Utils/                # ユーティリティ（DeviceInfo）
├── View Models/          # MVVM ビューモデル（AdViewModel、BaseWebViewVM）
├── ViewModifier/         # SwiftUI ViewModifier（FullScreenModalModifier）
├── RetailBooster.swift   # メイン SDK エントリーポイント
├── RtBBannerAd.swift     # バナー広告ビュー
├── RtBRewardAd.swift     # リワード広告ビュー
├── RtBPopupAd.swift      # ポップアップ広告ビュー
└── PrivacyInfo.xcprivacy # プライバシーマニフェスト

Examples/                 # SDK使用をデモンストレーションするサンプルiOSアプリ
Tests/CaRetailBoosterSDKTests/  # XCTest ユニットテスト
```

## 重要事項

- SDK は広告取得のためネットワークアクセスが必要
- プライバシーマニフェスト（PrivacyInfo.xcprivacy）の維持が必要
- 広告ターゲティングのためデバイス情報（IFA、スペック）を収集
- 一貫した表示のため、全 UI コンポーネントはライトモードを強制
