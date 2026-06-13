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
  currentPage: number,
  totalPages: number,
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

## 学習方法タイプ（STUDY_TYPES）

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
| `renderSubjects()` | 資格タブ（インライン展開付き） |
| `renderLog()` | 記録タブ（日付グループ + 学習方法アイコン） |
| `renderSettingsStats()` | 設定タブ統計・学習方法内訳グラフ |
| `renderStudyTypeBreakdown()` | 学習方法内訳グラフ（全体＋資格別） |
| `persist()` | localStorage保存 + Supabaseクラウド同期 |
| `saveExam()` | 試験日保存→renderAll()で即時反映 |
| `toggleExamApplied(id)` | 申込済みをONに |
| `cancelExamApplied(id)` | 確認ダイアログ→申込済みをOFFに |
| `saveWeekGoal()` | 週間目標保存→renderSummary() |

## 実装済み機能（2026-06 時点）

- 資格・目標の登録（アイコン・カラー・1日目標）
- 学習セッション記録（手動 / タイマー / ストップウォッチ / ポモドーロ）
- 学習方法タイプ選択（7種類）
- タイマー終了後の自動記録モーダル
- 週間目標とサマリーカード（今日大表示 / 今週・今月・累計）
- 試験日・申込期間登録 + 申込済み管理（キャンセル確認あり）
- 試験カウントダウン（7日以内赤・30日以内黄）
- 申込期限アラート（7日以内⚠️）
- 教材管理（参考書・過去問・進捗バー）
- 学習リソース（YouTube / サイト / PDF）
- 今日タブ資格カードをタップ → Subject Detail Overlay
- 学習方法内訳グラフ（設定タブ）
- 年間ヒートマップ（PC表示）
- Supabaseクラウド同期

## 既知の制限・TODO

- 試験日の編集はSubject Detail Overlayからのみ（今日タブカードから直接編集不可）
- 学習セッションの編集機能なし（削除のみ）
- 過去の日付での記録入力不可（常に今日の日付）
