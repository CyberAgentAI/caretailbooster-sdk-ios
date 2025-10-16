# WebView タップイベント問題 - 原因と対応ドキュメント

## 📋 問題の概要

Flutter SDKで外部スクロール中にWebViewをタップすると、WebView内のJavaScriptイベントハンドラ（`onclick`等）が実行されない問題が発生。

### 症状

- ✅ タップ時の**視覚的フィードバック（CSSアニメーション）は動作する**
- ❌ **JavaScriptのイベントハンドラ（onclick等）が実行されない**
- ❌ 一度この状態になると、**アプリを再起動するまで復帰しない**
- ✅ 横スクロール（adView内部のScrollView）では問題は発生しない
- ✅ スクロールせずにタップした場合は正常に動作する

---

## 🔍 根本原因

### タッチイベントの流れ

#### 正常時（スクロールなし）

**イベントシーケンス**
```
touchstart → touchend → mousedown → mouseup → click ✅
```

**ログ出力例**
```
📱 [JS Console] 🟡 [JS Event #1] touchstart on SPAN
📱 [JS Console] 🟡 [JS Event #2] touchend on SPAN
📱 [JS Console] 🟡 [JS Event #3] mousedown on SPAN
📱 [JS Console] 🟡 [JS Event #4] mouseup on SPAN
📱 [JS Console] 🟡 [JS Event #5] click on SPAN ← ✅ clickイベントが発火
```

#### 異常時（スクロール後）

**イベントシーケンス**
```
touchstart → touchend → mousedown → mouseup → ❌ click発火せず
```

**ログ出力例**
```
📱 [JS Console] 🟡 [JS Event #1] touchstart on IMG
📱 [JS Console] 🟡 [JS Event #2] touchend on IMG
📱 [JS Console] 🟡 [JS Event #3] mousedown on IMG
📱 [JS Console] 🟡 [JS Event #4] mouseup on IMG
← ❌ clickイベントが発火しない（Event #5が出力されない）
```

### 原因の詳細

**外部スクロールとの競合**
- Flutter側のScrollViewとWKWebViewのタッチ処理が競合
- ブラウザエンジンがタッチをスクロールと誤判断
- タッチシーケンスが中断され、clickイベント生成がキャンセルされる

---

## ✅ 実装した対応

### JavaScript側でのclickイベント補完

**ファイル**: `Sources/CaRetailBoosterSDK/Components/SwiftUIWebView.swift`

#### 実装ロジック

```javascript
(function() {
    // タッチ情報の記録
    var touchStartTime = 0;
    var touchStartTarget = null;
    var touchStartX = 0;
    var touchStartY = 0;
    var clickFired = false;

    // touchstart時: 開始時刻、座標、ターゲット要素を保存
    document.addEventListener('touchstart', function(e) {
        touchStartTime = Date.now();
        touchStartTarget = e.target;
        if (e.touches && e.touches[0]) {
            touchStartX = e.touches[0].clientX;
            touchStartY = e.touches[0].clientY;
        }
        clickFired = false;
    }, true);

    // click時: フラグを立てる
    document.addEventListener('click', function(e) {
        clickFired = true;
    }, true);

    // touchend時: clickが発火しない場合は手動生成
    document.addEventListener('touchend', function(e) {
        var touchDuration = Date.now() - touchStartTime;
        var touchEndX = e.changedTouches[0].clientX;
        var touchEndY = e.changedTouches[0].clientY;
        var distance = Math.sqrt(
            Math.pow(touchEndX - touchStartX, 2) +
            Math.pow(touchEndY - touchStartY, 2)
        );

        // 条件を満たす場合、clickイベントを手動で生成
        if (!clickFired && touchDuration < 300 && distance < 10) {
            setTimeout(function() {
                if (!clickFired) {
                    var clickEvent = new MouseEvent('click', {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        clientX: touchEndX,
                        clientY: touchEndY
                    });
                    e.target.dispatchEvent(clickEvent);
                }
            }, 50);
        }
    }, true);
})();
```

#### 判定条件

| 条件 | 値 | 理由 |
|------|-----|------|
| タッチ時間 | < 300ms | 短いタップ（長押しではない） |
| 移動距離 | < 10px | タップ位置の移動が少ない（スワイプではない） |
| clickフラグ | false | 自然なclickイベントが発火していない |

---

### デバッグ機能の追加

#### console.logのキャプチャ

```javascript
// JavaScriptのconsole.logをネイティブ側に送信
var originalLog = console.log;
console.log = function() {
    var message = Array.prototype.slice.call(arguments).join(' ');
    window.webkit.messageHandlers.consoleLog.postMessage(message);
    originalLog.apply(console, arguments);
};
```

#### タッチイベントの詳細ログ

- **座標**: `(x, y)`
- **時間**: `duration (ms)`
- **距離**: `distance (px)`
- **ターゲット要素**: `tagName`
- **click発火状態**: `clickFired`

#### JavaScript実行状態の監視

```javascript
// 5秒ごとのHeartbeat
setInterval(function() {
    console.log('🟢 [JS Heartbeat] ' + new Date().getTime());
}, 5000);
```

---

## 📊 修正後の動作

### ログ出力例（正常動作）

```
📱 [JS Console] 🔵 [TouchFix] touchstart on path at (150,200)
📱 [JS Console] 🔵 [TouchFix] touchend on path - duration: 31ms, distance: 2.5px, clickFired: false
📱 [JS Console] 🔵 [TouchFix] start target: path, end target: path
📱 [JS Console] 🟠 [TouchFix] Simulating click event on path
📱 [JS Console] 🟡 [JS Event #3] mousedown on path
📱 [JS Console] 🟡 [JS Event #4] mouseup on path
📱 [JS Console] 🟡 [JS Event #5] click on path ← ✅ 成功！
📱 [JS Console] 🔵 [TouchFix] click fired naturally
📱 [JS Console] 🟢 [TouchFix] Click event dispatched manually on path
```

### ログ出力例（条件不一致）

```
📱 [JS Console] 🔵 [TouchFix] touchstart on div at (100,150)
📱 [JS Console] 🔵 [TouchFix] touchend on div - duration: 450ms, distance: 1.2px, clickFired: false
📱 [JS Console] 🔴 [TouchFix] Conditions not met - clickFired: false, duration: 450, distance: 1.2
```
（タッチ時間が300msを超えているため、長押しと判定）

---

## 🎯 効果

| 項目 | 結果 |
|------|------|
| スクロール後のタップ | ✅ 正常に処理 |
| JavaScriptイベントハンドラ | ✅ 確実に実行 |
| HTML構造の違い | ✅ 影響なし |
| タップとスワイプの区別 | ✅ 正確に判定 |
| 長押しの誤検知 | ✅ 防止 |
| 正常なclickイベント | ✅ 妨害しない |

---