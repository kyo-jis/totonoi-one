# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**Totonoi One** — 暮らしを整えるライフダッシュボードPWA。11個のミニアプリをひとつのリポジトリで管理。

- **本番URL**: https://totonoi-one.vercel.app/
- **GitHub → Vercel 自動デプロイ**（git push だけで本番反映）

## デプロイ

```bash
git add <files>
git commit -m "..."
git push origin main   # Vercel が自動でデプロイ
```

ビルドステップなし。静的ファイルをそのまま配信。

## アーキテクチャ

### ファイル構成

各アプリは **独立した単一HTMLファイル**（CSS・JS すべて埋め込み）。共有ライブラリは存在しない。

```
index.html          # ポータル（Bento Grid）
subly.html          # サブスク管理
medly.html          # サプリ・薬管理
fitly.html          # 筋トレ記録
stockly.html        # 備蓄・在庫管理
cookly.html         # レシピ管理
renewly.html        # 期限管理（保険・免許等）
readly.html         # メモ・日記
ownly.html          # 持ち物・資産管理
learnly.html        # スタディプランナー
bookly.html         # 本・読書管理
sw-{app}.js         # 各アプリのService Worker
manifest-{app}.json # 各アプリのPWAマニフェスト
api/                # Vercel Serverless Functions（Stripe連携）
```

### データフロー

```
localStorage（オフライン・即時） ←→ Supabase（クラウド同期・ログイン時）
```

- 起動時: `localStorage` から読み込み → `init()` → 画面描画
- ログイン時: `syncFromCloud()` で Supabase から上書き同期
- 保存時: `localStorage.setItem()` + `dbSave(key, data)` を必ず両方呼ぶ

### 認証

- **Google OAuth のみ**（メール認証は削除済み）
- Supabase の `onAuthStateChange` でセッション監視
- ログイン時に `syncFromCloud()` が自動呼び出される

### isPro（有料プラン）判定

```javascript
var isPro = localStorage.getItem('isPro') === 'true';
```

ログイン時、`profiles.is_pro` を Supabase から読み込んで更新。
**管理者 (`kyouji.o.2@gmail.com`) は常に自動でPro有効化**（各アプリの `syncFromCloud()` 内に記述）。

Stripe Webhook（`api/webhook.js`）→ Supabase `profiles.is_pro = true` → 次回同期で反映。

### Service Worker

各 `sw-{app}.js` は **ネットワーク優先・失敗時にキャッシュ** 戦略。
**コードを変更してもブラウザが古いキャッシュを使う場合は `CACHE_NAME` のバージョンを上げる**（例: `subly-v2` → `subly-v3`）。

## 重要な実装パターン

### 日付処理（必須）

`new Date("YYYY-MM-DD")` はUTC解釈のためJST深夜に日付がずれる。**必ず以下のヘルパーを使う**:

```javascript
function parseLocalDate(str) {
  if (!str) return null;
  var p = str.split('-');
  return new Date(+p[0], +p[1]-1, +p[2]);
}
function localDateStr(d) {
  return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0');
}
```

- `new Date("YYYY-MM-DD")` → `parseLocalDate("YYYY-MM-DD")`
- `new Date().toISOString().split('T')[0]` → `localDateStr(new Date())`

`parseLocalDate` と `localDateStr` は subly / fitly には定義済み。他のアプリに追加する際はJSブロック先頭に置く。

### デザインシステム（CSS変数）

```css
--bg: #0c0c18;         /* ページ背景 */
--surface: #14142a;    /* カード背景 */
--surface2: #1c1c38;
--surface3: #242448;
--border: #2e2e50;
--text: #f2f2fa;
--muted: #9494b8;
--spring: cubic-bezier(.34,1.56,.64,1);  /* スプリングアニメーション */
```

- `font-weight: 400`（300は使わない）
- ボタンの押下: `:active { transform: scale(.93); }`

### 認証モーダル（全アプリ共通パターン）

```html
<div class="modal-overlay" id="authModal" onclick="if(event.target===this)this.classList.remove('show')">
  <div class="modal">
    <div class="modal-handle"></div>
    <p style="text-align:center;font-size:1rem;font-weight:500;margin-bottom:1.25rem;">ログイン</p>
    <button onclick="handleGoogleAuth()" style="...">Google でログイン</button>
    <button class="btn-cancel" onclick="document.getElementById('authModal').classList.remove('show')">キャンセル</button>
  </div>
</div>
```

### Supabase クライアント初期化（各アプリ末尾のJSに記述）

```javascript
var _sb = supabase.createClient(
  'https://foknpmvpgbkwgpmlgzrn.supabase.co',
  '<anon key>'
);
var currentUser = null;
var _APP = 'appname'; // 'subly', 'medly', 'fitly' ...
```

`dbSave(key, data)` は `user_data` テーブルに `{user_id, app, key, data}` をupsert。

## Vercel 環境変数（Serverless Functions用）

`api/` 配下のコードが使用:
- `STRIPE_SECRET_KEY`
- `STRIPE_PRICE_ID`
- `STRIPE_WEBHOOK_SECRET`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## アイコン命名規則

| ファイル | サイズ | 用途 |
|---|---|---|
| `icon-{app}-192.png` | 192×192 | Android / PWA |
| `icon-{app}-512.png` | 512×512 | スプラッシュ |
| `apple-touch-icon-{app}.png` | 180×180 | iOS ホーム画面 |

新しいアプリを追加する際は同じ命名規則でアイコンを用意し、`manifest-{app}.json` と `sw-{app}.js` も作成する。
