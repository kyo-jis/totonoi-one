# アプリ名の見せ方 修正メモ（機能名を主役に）

*作成: 2026-07-23 / 出所: 紹介LP検討セッション。LP側は反映済み。本メモは実アプリ側に同じ方針を反映するための作業指示。*

---

## 1. 方針

- 造語（Kakely / Subly / Medly … の「〜ly」）は**何のアプリか直感的に分かりにくい**。
- **機能名（家計簿・サブスク管理 等）を主役**にし、**英字名は小さな添え字（補助）**として残す。
- **内部識別子は変えない**（＝影響範囲を最小化・既存ユーザーのデータを壊さない）:
  - ファイル名・URL（`kakely.html` 等）
  - 内部の app キー（`'subly'` 等。localStorage キーや Supabase `user_data.app` カラム、`bentoPrefs` の並び順など）
  - アイコン画像ファイル名（`icon-subly-192.png` 等）
- 変えるのは**表示名（ユーザーの目に触れる文字）だけ**。

## 2. 表示名の対応表

| app キー（不変） | 機能名（主役／表示） | 英字名（補助・小さく） |
|---|---|---|
| kakely | 家計簿 | Kakely |
| subly | サブスク管理 | Subly |
| medly | サプリ・薬管理 | Medly |
| fitly | トレーニング記録 | Fitly |
| stockly | 在庫・備蓄管理 | Stockly |
| cookly | レシピ管理 | Cookly |
| learnly | 学習プランナー | Learnly |
| renewly | 期限管理 | Renewly |
| bookly | 読書管理 | Bookly |
| readly | メモ・日記 | Readly |

## 3. 修正タスク（触る箇所）

### 3-1. ポータル `index.html`
- 各カードの `bc-name`（現状=英字名・大）と `bc-tag`（現状=機能名・小pill）を**入れ替える**:
  - `bc-name` → 機能名（例「サブスク管理」）
  - `bc-tag` または補助表示 → 英字名（例「Subly」）
- `bc-name` は現状 mincho italic。日本語主役になるので **italic を外す**と読みやすい。
- 管理者ダッシュボードのラベル等、内部向け表示は変更任意。

### 3-2. 各アプリ `*.html`（10ファイル）
- `<title>` を機能名主役に（例: `サブスク管理 (Subly) | Totonoi One`）。
- ヘッダー／ロゴ横のアプリ名表示を機能名主役に。英字名は小さく併記。
- `<meta name="apple-mobile-web-app-title" content="...">` を**機能名**に（iOSホーム画面の表示名）。

### 3-3. PWA マニフェスト `manifest-*.json`（10ファイル）
- 現状例（`manifest-subly.json`）: `"name": "Subly — サブスク管理"` / `"short_name": "Subly"`。
- **`short_name` を機能名に**（ホーム画面に出るのはこちら。例 `"サブスク管理"`）。
- `name` は `"サブスク管理 (Subly)"` など機能名を先頭に。

### 3-4. 使い方ガイド `guide.html`
- 各アプリのセクション見出し・目次（TOC）を機能名主役に。英字名は補助。

## 4. 変えないもの（重要）
- `kakely.html` などの**ファイル名・URL**
- 内部 **app キー** `'kakely' / 'subly' / …`（localStorage・Supabase・bentoPrefs 等が参照）
- **アイコン画像ファイル名** `icon-*.png` / `apple-touch-icon-*.png`
- 各アプリの **Service Worker `sw-*.js`** のキャッシュ対象パス

## 5. 未決事項
1. 英字名を「補助として残す」か、将来的に**完全廃止**するか（LPは補助で残す方針）。
2. PWA `short_name` は機能名のみか、絵文字＋機能名（例「💳 サブスク管理」）か。
3. プロダクトごとの**抜本的な改名**（Subly→別名）に踏み込むかは別途判断（本メモは "見せ方だけ変える" 範囲）。

---

## 補足
- 紹介LP（Artifact）側は本方針を**反映済み**（機能名を大きく・英字名を添え字に、v15）。実アプリと表現がズレないよう、実装時に本メモと突き合わせること。
- 料金まわりの仕様変更は別紙 `docs/pricing-change.md` を参照。
