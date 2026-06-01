# Totonoi — プロジェクト設計ドキュメント

> 毎日を、シンプルに。暮らしを整えるライフダッシュボード

---

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [ファイル構成](#2-ファイル構成)
3. [技術スタック](#3-技術スタック)
4. [デプロイ構成](#4-デプロイ構成)
5. [アプリ一覧と機能](#5-アプリ一覧と機能)
6. [Subly — 詳細設計](#6-Subly--詳細設計)
7. [データ設計](#7-データ設計)
8. [無料・有料プラン](#8-無料有料プラン)
9. [管理者・プロモコード](#9-管理者プロモコード)
10. [PWA設定](#10-pwa設定)
11. [アイコン](#11-アイコン)
12. [今後の実装予定](#12-今後の実装予定)
13. [本番移行チェックリスト](#13-本番移行チェックリスト)

---

## 1. プロジェクト概要

| 項目 | 内容 |
|---|---|
| プロジェクト名 | Totonoi |
| 種別 | スマホ向けWebアプリ（PWA） |
| 対象ユーザー | 不特定多数 |
| ホスティング | Vercel（無料プラン） |
| 収益モデル | 広告（Google AdSense）＋ 有料プラン（Stripe予定） |
| データ保存 | localStorage / IndexedDB（端末内） |

---

## 2. ファイル構成

```
mylife-tools/
│
├── index.html                    # ポータルサイト（トップページ）
├── subly.html             # Subly
├── medly.html                  # 筋トレ記録アプリ（開発予定）
├── cookly.html                   # レシピまとめアプリ（開発予定）
│
├── vercel.json                   # Vercelルーティング設定
│
├── manifest-portal.json          # ポータル PWA設定
├── manifest-subscription.json    # サブスク管理 PWA設定
├── manifest-workout.json         # 筋トレ記録 PWA設定
├── manifest-recipe.json          # レシピまとめ PWA設定
│
├── icon-portal-192.png           # ポータルアイコン 192px
├── icon-portal-512.png           # ポータルアイコン 512px
├── icon-subscription-192.png     # サブスク管理アイコン 192px
├── icon-subscription-512.png     # サブスク管理アイコン 512px
├── icon-workout-192.png          # 筋トレ記録アイコン 192px
├── icon-workout-512.png          # 筋トレ記録アイコン 512px
├── icon-recipe-192.png           # レシピまとめアイコン 192px
├── icon-recipe-512.png           # レシピまとめアイコン 512px
│
├── apple-touch-icon-portal.png       # iOS用アイコン
├── apple-touch-icon-subscription.png # iOS用アイコン
├── apple-touch-icon-workout.png      # iOS用アイコン
└── apple-touch-icon-recipe.png       # iOS用アイコン
```

---

## 3. 技術スタック

| 分類 | 技術 |
|---|---|
| フロントエンド | HTML / CSS / Vanilla JavaScript（ライブラリなし） |
| フォント | Google Fonts（Outfit / DM Sans / Playfair Display） |
| アイコン取得 | Google Favicon API |
| データ保存 | localStorage（テキストデータ） / IndexedDB（画像・レシピ予定） |
| PWA | Web App Manifest + Service Worker（予定） |
| ホスティング | Vercel |
| 決済（予定） | Stripe |
| 広告（予定） | Google AdSense |
| アクセス解析（予定） | Google Analytics 4（GA4） |

---

## 4. デプロイ構成

```
GitHub リポジトリ
      ↓ push
Vercel（自動デプロイ）
      ↓
https://yoursite.com
```

### vercel.json — ルーティング設定

```json
{
  "rewrites": [
    { "source": "/subscription", "destination": "/subly.html" },
    { "source": "/workout",      "destination": "/medly.html" },
    { "source": "/recipe",       "destination": "/cookly.html" }
  ]
}
```

### 更新方法

```bash
# GitHubにファイルをアップするだけで自動デプロイ
# またはVercel CLIを使う場合：
vercel --prod
```

---

## 5. アプリ一覧と機能

| アプリ | URL | 状態 | データ保存 |
|---|---|---|---|
| ポータル | `/` | ✅ 完成 | なし |
| Subly（サブスク管理） | `/subly` | ✅ 完成 | localStorage |
| Medly（サプリ・薬管理） | `/medly` | 🔧 開発予定 | localStorage |
| Cookly（レシピ管理） | `/cookly` | 🔧 開発予定 | IndexedDB（画像対応） |

---

## 6. Subly — 詳細設計

### 画面構成（タブ）

```
サブスク管理
├── 一覧タブ
│   ├── 今月の実際の支出カード
│   ├── 無料プランバナー（無料時のみ）
│   └── サービスカード一覧（支払い日が近い順）
│
├── カレンダータブ
│   ├── 月別カレンダー
│   └── 請求日タップ → ポップアップで詳細表示
│
├── 分析タブ
│   ├── 支出履歴グラフ（無料：3ヶ月 / 有料：全期間）
│   ├── 年間予測・統計カード
│   ├── 金額ランキング（🥇🥈🥉）
│   ├── 決済方法別合計
│   ├── 削減提案
│   └── データ管理（エクスポート・インポート）
│
└── 設定タブ
    ├── プラン表示・アップグレード
    ├── プロモ・管理者コード入力
    ├── SNS共有（X・LINE・リンクコピー）
    ├── 開発者へのお問い合わせ
    └── アプリについて（バージョン等）
```

### サービス追加モーダル

- プリセット選択（9カテゴリ・40種類以上）
- 手動入力（名前・絵文字・金額・周期・次回請求日・決済方法）

### 対応する支払い周期

| 値 | 表示 |
|---|---|
| `weekly` | 毎週 |
| `monthly` | 毎月 |
| `3months` | 3ヶ月ごと |
| `6months` | 6ヶ月ごと |
| `yearly` | 毎年 |
| `2years` | 2年ごと |
| `3years` | 3年ごと |
| `custom` | カスタム（任意の月数・年数） |
| `once` | 買い切り |

### 対応する決済方法

- クレジットカード：Visa / Mastercard / JCB / AMEX
- キャリア決済：docomo / au / SoftBank
- デジタル決済：PayPay / 楽天Pay / LINE Pay
- プラットフォーム：App Store / Google Play / PayPal
- その他：銀行振込 / コンビニ払い

### プリセットサービス（カテゴリ別）

| カテゴリ | サービス例 |
|---|---|
| 動画 | Netflix / Disney+ / Amazon Prime / Hulu / U-NEXT / Apple TV+ / YouTube Premium / DAZN / ABEMAプレミアム |
| 音楽 | Spotify / Apple Music / YouTube Music / Amazon Music |
| クラウド | iCloud / Google One / Dropbox / OneDrive |
| 読書・学習 | Kindle Unlimited / 楽天マガジン / Audible / Duolingo |
| ゲーム | Nintendo Switch Online / PS Plus / Xbox Game Pass |
| ニュース | 日経電子版 / NewsPicks |
| セキュリティ | 1Password / NordVPN / Norton |
| AI・仕事 | Adobe CC / ChatGPT Plus / Claude Pro / Notion / GitHub / Canva Pro / Zoom / Microsoft 365 |
| 生活・その他 | 楽天プレミアム / Uber One |

---

## 7. データ設計

### サービスデータ（`localStorage: 'subs'`）

```json
[
  {
    "id": "1234567890",
    "name": "Netflix",
    "icon": "🎬",
    "domain": "netflix.com",
    "amount": 1490,
    "cycle": "monthly",
    "nextBillingDate": "2026-06-15",
    "payment": "visa",
    "customNum": null,
    "customUnit": null
  }
]
```

### 支払い履歴データ（`localStorage: 'subHistory'`）

```json
[
  {
    "id": "1234567890",
    "name": "Netflix",
    "icon": "🎬",
    "domain": "netflix.com",
    "amount": 1490,
    "cycle": "monthly",
    "paidDate": "2026-05-15",
    "payment": "visa"
  }
]
```

### 自動履歴記録の仕組み

```
アプリ起動時
  ↓
nextBillingDate が今日以前？
  ↓ YES
履歴（subHistory）に記録
  ↓
nextBillingDate を次回日付に更新
  （月払い → 翌月 / 年払い → 翌年 / カスタム → 指定期間後）
  ↓
localStorageに保存
```

---

## 8. 無料・有料プラン

| 機能 | 無料 | 有料 |
|---|---|---|
| 登録件数 | 5件まで | 無制限 |
| カレンダー表示 | ✅ | ✅ |
| 支出グラフ | 過去3ヶ月 | 全期間 |
| 分析・ランキング | ✅ | ✅ |
| エクスポート（JSON・CSV） | ❌ | ✅ |
| インポート | ❌ | ✅ |
| 広告 | あり | なし |

### isPro フラグの管理

```javascript
// 読み込み
var isPro = localStorage.getItem('isPro') === 'true';

// 有効化（Stripe決済完了時 or コード入力時）
localStorage.setItem('isPro', 'true');

// 無効化
localStorage.removeItem('isPro');
```

---

## 9. 管理者・プロモコード

設定タブ →「プロモ・管理者コード」欄にコードを入力するとProモードがONになります。

### コードの変更方法

`subly.html` 内の以下を編集：

```javascript
var ADMIN_CODES = ['ADMIN2024', 'MYLIFETOOLS'];
```

### Stripe連携後の流れ（予定）

```
ユーザーが決済完了
  ↓
Stripe Webhook → サーバー
  ↓
localStorage.setItem('isPro', 'true')
  ↓
updateProUI() で画面を即時反映
```

---

## 10. PWA設定

各アプリは独立したPWAとしてホーム画面に追加できます。

### ホーム画面への追加方法

**iOS（Safari）**
1. Safariでアプリページを開く
2. 下部の共有ボタン「□↑」をタップ
3. 「ホーム画面に追加」を選択

**Android（Chrome）**
1. Chromeでアプリページを開く
2. メニュー「⋮」→「ホーム画面に追加」

### manifest.json の構成

```json
{
  "name": "サブスク管理",
  "short_name": "サブスク",
  "start_url": "/subscription",
  "display": "standalone",
  "background_color": "#1a1a24",
  "theme_color": "#1a1a24",
  "icons": [
    { "src": "/icon-subscription-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-subscription-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ]
}
```

---

## 11. アイコン

各アプリのアイコンはSVGで設計し、PNGに変換して使用しています。

| ファイル | サイズ | 用途 |
|---|---|---|
| `icon-{app}-192.png` | 192×192px | Android・PWA標準 |
| `icon-{app}-512.png` | 512×512px | スプラッシュ・ストア |
| `apple-touch-icon-{app}.png` | 180×180px | iOSホーム画面 |

### カラーコンセプト

| アプリ | メインカラー | イメージ |
|---|---|---|
| ポータル | マルチカラー | 4つのアプリを象徴するグリッド |
| サブスク管理 | `#6c8eff`（ブルー） | クレジットカード |
| 筋トレ記録 | `#5ecfa0`（グリーン） | ダンベル |
| レシピまとめ | `#ff7c6e`（レッド） | フライパン |

---

## 12. 今後の実装予定

### 筋トレ記録アプリ
- 種目・セット・回数・重量の記録
- 部位別カレンダー
- 記録グラフ（重量の推移）
- localStorage保存
- PWA対応

### レシピまとめアプリ
- レシピ名・材料・手順・写真の保存
- 写真はIndexedDB（大容量対応）
- カテゴリ・タグで絞り込み
- PWA対応

### 共通
- Google Analytics 4 導入（`G-XXXXXXXXXX`を各ページに追加）
- Google AdSense 導入（審査通過後）
- Stripe決済実装（サーバー必要：Vercel + Next.js 推奨）
- 独自ドメイン取得（AdSense審査のため推奨）

---

## 13. 本番移行チェックリスト

### デプロイ前
- [ ] `your@email.com` を実際のメールアドレスに変更
- [ ] `https://yoursite.com` を実際のURLに変更
- [ ] `ADMIN_CODES` を推測されにくいコードに変更
- [ ] GA4タグを`<head>`に追加

### AdSense申請前
- [ ] 独自ドメイン取得
- [ ] プライバシーポリシーページ作成
- [ ] 利用規約ページ作成
- [ ] ある程度のコンテンツ・アクセス数を確保

### Stripe導入時
- [ ] Vercel + Next.js（またはEdge Functions）へ移行
- [ ] Stripe Webhookの実装
- [ ] 決済完了後に`isPro`フラグをONにする処理

---

*最終更新：2026年5月*

---

## コンセプト

> 管理するのではなく、整える。
> 記録するのではなく、次に起こることを知らせる。
> 情報を増やすのではなく、気になることを減らす。

**ブランドメッセージ：** 覚えることを減らし、大切なことに集中できる毎日へ。
