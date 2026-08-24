# Learnly — 開発メモ

スタディプランナー。資格・試験対策を管理する学習記録アプリ。

## データ構造

### subjects（資格・目標）
```js
{
  id: string,        // Date.now().toString()
  name: string,      // 表示名
  icon: string,      // 絵文字
  color: string,     // hex (#3c8cbf など)
  dailyGoal: number  // 1日の目標分数（0=目標なし）
}
```

### sessions（学習記録）
```js
{
  id: string,
  subjectId: string,
  date: string,        // "YYYY-MM-DD"（localDateStr形式）
  duration: number,    // 分
  memo: string,
  studyType: string|null,  // 学習方法ID（後述）
  createdAt: string    // ISO文字列
}
```

### exams（試験日）
```js
{
  id: string,
  subjectId: string,
  name: string,
  appStart: string,    // "YYYY-MM-DD" 申込開始日
  appDeadline: string, // "YYYY-MM-DD" 申込締切
  examDate: string,    // "YYYY-MM-DD" 試験日
  applied: boolean,    // 申込済みフラグ
  createdAt: string
}
```

### materials（教材）
```js
{
  id: string,
  subjectId: string,
  type: "book"|"past", // 参考書 or 過去問
  title: string,
  author: string,
  unit: "page"|"question"|"percent"|"loc"|"chapter",  // 進捗の単位（未設定＝"page" 扱い・後方互換）
  currentPage: number,  // 単位に応じた現在値（percent は 0〜100）
  totalPages: number,   // 単位に応じた総量（percent は常に100固定・入力欄は非表示）
  year: string,        // 過去問の年度
  correctRate: number|null,
  createdAt: string
}
```

### resources（学習リソース）
```js
{
  id: string,
  subjectId: string,
  name: string,
  url: string,
  rtype: "youtube"|"site"|"pdf"|"other",
  ytThumb: string|null,
  createdAt: string
}
```

## 教材の進捗単位（MATERIAL_UNITS）

電子書籍はページ番号が表示されない・文字サイズで変わるため、教材ごとに単位を選べる。
**参考書・過去問の両方で使える共通項目**（種類を「過去問」にすると既定で「問」になる。手動で選び直した場合はそちらを優先）。
過去問は進捗バーと正解率バーの2本が並ぶ。

| id | icon | label | 表示例（カード / 記録一覧） |
|----|------|-------|------|
| page     | 📄 | ページ  | `45/300p` / `p.10〜25` |
| question | 📝 | 問      | `45/200問` / `46〜60問` |
| percent  | ％ | ％      | `40%` / `40〜55%` |
| loc      | 🔢 | 位置No. | `1200/5000` / `No.1200〜1400` |
| chapter  | 📑 | 章      | `3/12章` / `3〜4章` |

ヘルパー: `matUnit(m)`（未設定は `page`）、`isPercentUnit(m)`、`matTotal(m)`、`matHasProgress(m)`、`matProgressText(m)`、`matMetaText(m)`、`sessRangeText(m, s)`

## 学習方法タイプ（STUDY_TYPES）

**記録モーダルからは選択欄を削除済み**（入力を速くするため / 2026-08-24）。
`sessions.studyType` のデータ構造・既存記録のアイコン表示・内訳グラフは残してあるため、
記録モーダルに選択UIを戻せば元通り機能する。過去の記録がない場合は設定タブの内訳セクションごと非表示。

| id | icon | label |
|----|------|-------|
| text    | 📖 | テキスト |
| problem | 📝 | 問題集 |
| past    | 📄 | 過去問 |
| video   | 🎥 | 動画 |
| note    | ✍️  | ノート |
| audio   | 🎧 | 音声 |
| other   | 📌 | その他 |

## localStorage キー

| キー | 内容 |
|------|------|
| `learnly_subjects` | subjects 配列 |
| `learnly_sessions` | sessions 配列 |
| `learnly_materials` | materials 配列 |
| `learnly_resources` | resources 配列 |
| `learnly_exams` | exams 配列 |
| `learnly_updated_at` | 最終更新タイムスタンプ（Supabase同期判定用） |
| `learnly_weekly_goal` | 週間目標分数（グローバル設定） |
| `learnly_summary_compact` | サマリーカードの表示状態（`'1'`=コンパクト・既定 / `'0'`=詳細を開く） |
| `learnly_subj_sort` | 資格の並び順（`'exam'`=試験日が近い順・既定 / `'manual'`=手動。手動時の並びは subjects 配列の順序そのもの） |

## Supabase 同期

`user_data` テーブルに `app='learnly'` でキーごとにupsert。  
同期キー: `subjects`, `sessions`, `materials`, `resources`, `exams`

## 主要な関数

| 関数 | 用途 |
|------|------|
| `renderAll()` | 全ビュー再描画（今日・カウントダウン・資格タブ） |
| `renderSummary()` | サマリーカード（今日・今週・今月・累計・週間目標バー） |
| `renderExamCountdown()` | トップの試験カウントダウンカード |
| `renderToday()` | 今日タブの資格カード一覧 |
| `renderSubjects()` | 資格タブ（インライン展開付き・並び順バー・手動時は↑↓ボタン） |
| `sortedSubjects()` | 資格の表示順を返す。**資格を一覧表示する箇所は必ずこれを使う**（今日タブ・資格タブ・記録モーダル・内訳グラフ） |
| `subjectExamTime(id)` | その資格の直近の未来の試験日（無ければ Infinity で末尾へ） |
| `setSubjSort(mode)` | `'exam'` / `'manual'` 切替。手動へ切替時は表示中の並びを subjects に確定させる |
| `moveSubject(id, dir)` | 手動並び替え（dir: -1=上 / +1=下） |
| `renderLog()` | 記録タブ（日付グループ + 学習方法アイコン） |
| `renderLogMaterialSelect(keepId)` | 記録モーダルの教材プルダウン。選択中の資格(`_logSubjId`)の教材だけを出す。引数省略で現在の選択を維持 |
| `renderSettingsStats()` | 設定タブ統計・学習方法内訳グラフ |
| `renderStudyTypeBreakdown()` | 学習方法内訳グラフ（全体＋資格別） |
| `persist()` | localStorage保存 + Supabaseクラウド同期 |
| `saveExam()` | 試験日保存→renderAll()で即時反映 |
| `toggleExamApplied(id)` | 申込済みをONに |
| `cancelExamApplied(id)` | 確認ダイアログ→申込済みをOFFに |
| `saveWeekGoal()` | 週間目標保存→renderSummary() |
| `toggleSummary()` | サマリーカードのコンパクト⇄詳細を切り替え（localStorageに保存） |
| `applySummaryCompact()` | 起動時に保存済みの表示状態を復元（既定はコンパクト） |

## 実装済み機能（2026-06 時点）

- 資格・目標の登録（アイコン・カラー・1日目標）
- 学習セッション記録（手動 / タイマー / ストップウォッチ / ポモドーロ）
- タイマー終了後の自動記録モーダル
- 週間目標とサマリーカード（既定はコンパクト表示。タップで週間目標バー・週バーを展開）
- 試験日・申込期間登録 + 申込済み管理（キャンセル確認あり）
- 試験カウントダウン（7日以内赤・30日以内黄）
- 申込期限アラート（7日以内⚠️）
- 教材管理（参考書・過去問とも進捗バーあり / 進捗の単位を ページ・問・％・位置No.・章 から選択可）
- タブ順は「今日 / 記録 / 資格 / 設定」（他アプリと同様、日々使うものを左・管理系を右）
- 資格の並び替え（既定＝試験日が近い順 / 手動は↑↓で入れ替え。全画面で並びが揃う）
- 学習リソース（YouTube / サイト / PDF）
- 今日タブ資格カードをタップ → Subject Detail Overlay
- 学習方法内訳グラフ（設定タブ）
- 年間ヒートマップ（PC表示）
- Supabaseクラウド同期

## 既知の制限・TODO

- 試験日の編集はSubject Detail Overlayからのみ（今日タブカードから直接編集不可）
- 学習セッションの編集機能なし（削除のみ）
- 過去の日付での記録入力不可（常に今日の日付）
