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

**重要**: 現在テストファイルは存在しません。新機能実装時は：

1. `Tests/CaRetailBoosterSDKTests/`ディレクトリにテストファイルを作成
2. XCTest フレームワークを使用してユニットテストを記述
3. RetailBoosterAd（プログラマティック）と RetailBoosterAdView（SwiftUI）の両インターフェースをテスト

## アーキテクチャ

### コアコンポーネント

- **RetailBoosterAd**: プログラマティック API のエントリーポイント（ObservableObject）
- **RetailBoosterAdView**: 宣言的使用のための SwiftUI ビュー
- **AdViewModel**: Combine を使用した中央状態管理（@Published プロパティ）
- **AdCall**: 広告取得のための API サービス（URLSession による非同期通信）
- **AdTracking**: インプレッションとビュートラッキングサービス（ビューアビリティ測定）

### UI コンポーネント

- **BannerAd**: 固定サイズのバナー広告
- **RewardAd**: リワード付きインタラクティブ広告（動画/アンケート）- フルスクリーンモーダル制御
- **SwiftUIWebView**: Web コンテンツ用の WebKit ラッパー（JavaScript-Swift 間通信）

### データフロー

1. AdViewModel が AdCall サービスから広告をリクエスト
2. AdCall が設定された環境エンドポイントから取得
3. 広告がキャッシュされ、UI コンポーネント経由で表示
4. AdTracking がインプレッションとインタラクションを記録
5. コールバックがイベント（リワード、クリック）をホストアプリに通知

## 環境設定

SDK は`mode`パラメータで複数の環境をサポート：

- `local`: http://localhost:3000/api/ads
- `dev`: https://dev-ad.retaiboo.com/ad/v1
- `stg`: https://stg-ad.retaiboo.com/ad/v1
- `prd`: https://ad.retaiboo.com/ad/v1
- `mock`: https://mock.retaiboo.com/ad/v1

## 主要な実装詳細

### SwiftUI 統合

```swift
RetailBoosterAdView(
    mediaId: "media1",
    userId: "user1",
    crypto: "crypto1",
    tagGroupId: "reward1",
    mode: .local,
    callback: Callback(
        onMarkSucceeded: { print("onMarkSucceeded") },
        onRewardModalClosed: { print("onRewardModalClosed") }
    ),
    options: Options(
        rewardAdItemSpacing: 16,
        rewardAdLeadingMargin: 16,
        rewardAdTrailingMargin: 16
    )
)
```

### プログラマティック使用

```swift
let retailBoosterAd = RetailBoosterAd(
    mediaId: "media1",
    userId: "user1",
    crypto: "crypto1",
    tagGroupId: "reward1",
    mode: .local,
    callback: Callback(
        onMarkSucceeded: { print("onMarkSucceeded") },
        onRewardModalClosed: { print("onRewardModalClosed") }
    ),
    options: Options(
        rewardAd: RewardAdOption(width: 173, height: 210)
    )
)

// 広告ビューの取得
retailBoosterAd.getAdViews { result in
    switch result {
    case .success(let views):
        // 広告ビューを使用
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}

// エリア情報へのアクセス
if let areaName = retailBoosterAd.areaName {
    // areaNameを使用
}
```

### エリアベースの広告グループ化

TagGroup モデルを通じて、カスタマイズ可能なタイトルと説明でエリア別に広告をグループ化できます。

### パラメータ詳細

**必須パラメータ:**

- `mediaId`: メディア ID（String）
- `userId`: ユーザー ID（String）
- `crypto`: 認証用暗号化パラメータ（String）
- `tagGroupId`: タググループ ID（String）
- `mode`: 実行環境（RunMode 型: .local, .dev, .stg, .prd, .mock）

**オプションパラメータ:**

- `callback`: コールバック設定（Callback 型）
  - `onMarkSucceeded`: マーク成功時のコールバック
  - `onRewardModalClosed`: リワードモーダル閉じた時のコールバック
- `options`: 表示オプション（Options 型）
  - `rewardAd`: リワード広告のサイズ設定（width, height）
  - `rewardAdItemSpacing`: アイテム間のスペース
  - `rewardAdLeadingMargin`: 左マージン
  - `rewardAdTrailingMargin`: 右マージン
  - `hiddenIndicators`: インジケーター表示設定（デフォルト: true）

## プロジェクト構造

```
Sources/CaRetailBoosterSDK/
├── Models/          # データモデル（Banner、Reward、TagGroup）
├── Services/        # ビジネスロジック（AdCall、AdTracking）
├── ViewModels/      # MVVMビューモデル
├── Views/           # SwiftUIコンポーネント
└── RetailBoosterAd* # パブリックAPIエントリーポイント

Examples/            # SDK使用をデモンストレーションするサンプルiOSアプリ
```

## 重要事項

- SDK は広告取得のためネットワークアクセスが必要
- プライバシーマニフェスト（PrivacyInfo.xcprivacy）の維持が必要
- 広告ターゲティングのためデバイス情報（IFA、スペック）を収集
- 一貫した表示のため、全 UI コンポーネントはライトモードを強制
