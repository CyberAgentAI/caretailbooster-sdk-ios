---
allowed-tools: Bash(grep:*), Bash(git:*), Bash(sed:*)
description: SDKのバージョンを更新してコミットを作成
---

SDKバージョンを更新します。

まず現在のバージョンを確認:

```bash
current_version=$(grep "s\.version" CaRetailBoosterSDK.podspec | grep -o "'[0-9]\+\.[0-9]\+\.[0-9]\+'" | tr -d "'")
echo "現在のバージョン: $current_version"
```

バージョン番号を分解:

```bash
IFS='.' read -r major minor patch <<< "$current_version"
```

どの部分を更新するか選択してもらいます：
- 1: メジャーバージョン (${major}.0.0)
- 2: マイナーバージョン (${major}.${minor}.0)  
- 3: パッチバージョン (${major}.${minor}.$((patch + 1)))

選択に基づいて新しいバージョンを設定:

```bash
case "$1" in
  1)
    new_version="$((major + 1)).0.0"
    ;;
  2)
    new_version="${major}.$((minor + 1)).0"
    ;;
  3)
    new_version="${major}.${minor}.$((patch + 1))"
    ;;
  *)
    echo "1, 2, 3 どれかを選択してください"
    exit 1
    ;;
esac

echo "新しいバージョン: $new_version"
```

CaRetailBoosterSDK.podspec のバージョンを更新:

```bash
sed -i '' -E "s/s\.version.*=.*'[0-9]+\.[0-9]+\.[0-9]+'/s.version          = '$new_version'/" CaRetailBoosterSDK.podspec
```

変更内容を確認:

```bash
git diff CaRetailBoosterSDK.podspec
```

変更をコミット:

```bash
git add CaRetailBoosterSDK.podspec
git commit -m "update sdk version to $new_version"
```

完了しました！