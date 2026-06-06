/**
 * Bookly 用 CSV 生成スクリプト（Node.js）
 * Z:\Comics\漫画 のフォルダ構成から Bookly の CSV インポート形式を生成する。
 *
 * 出力形式は Bookly の importCSV が期待する14列：
 *   タイトル,著者,カテゴリ,タイプ,読了巻/P,全巻/P,ステータス,形態,評価,読了日,メモ,完結済み,次巻発売日,発売日
 *
 * 使い方:
 *   node generate_bookly_csv.mjs
 */

import fs from 'fs';
import path from 'path';

// ── 設定 ──────────────────────────────────────────────────────────────────
const COMICS_ROOT = String.raw`Z:\Comics\漫画`;
const OUTPUT_CSV  = String.raw`C:\Users\kyoji\Dev\totonoi-one\bookly_import.csv`;
const SUPPORTED_EXTS = new Set(['.cbz', '.zip', '.cbr', '.rar']);

// タイトルフォルダ末尾の巻数パターン
//   例: " 01-12"  " 1-5"  " 01"  " 1"  " 001-100"
const VOL_SUFFIX_RE = /\s+\d{1,4}(?:\s*[-–－～~]\s*\d{1,4})?\s*$/;
// ──────────────────────────────────────────────────────────────────────────

/** カテゴリフォルダかどうかを判定 */
function isCategoryFolder(name) {
  if (!name) return false;
  // '_' 始まり（_カラー版 等の特殊カテゴリ）
  if (name[0] === '_') return true;
  // ひらがな・カタカナ・漢字始まり（あ行/か行 等の五十音順フォルダ）
  return /^[ぁ-ゖァ-ヶ一-鿿]/.test(name);
}

/** '_' フォルダ配下のタイトル名から末尾の巻数部分を除去 */
function stripVolumeSuffix(name) {
  return name.replace(VOL_SUFFIX_RE, '').trim();
}

/** タイトルフォルダ直下の対応ファイル数を返す */
function countVolumes(folderPath) {
  try {
    const entries = fs.readdirSync(folderPath, { withFileTypes: true });
    return entries.filter(e => {
      if (!e.isFile()) return false;
      const ext = path.extname(e.name).toLowerCase();
      return SUPPORTED_EXTS.has(ext);
    }).length;
  } catch {
    return 0;
  }
}

/** CSV の1行分を生成（カンマやダブルクォートを適切にエスケープ） */
function csvRow(fields) {
  return fields.map(f => {
    const s = String(f ?? '');
    // カンマ・ダブルクォート・改行を含む場合はダブルクォートで囲む
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
      return '"' + s.replace(/"/g, '""') + '"';
    }
    return s;
  }).join(',');
}

function main() {
  if (!fs.existsSync(COMICS_ROOT)) {
    console.error(`[エラー] フォルダが見つかりません: ${COMICS_ROOT}`);
    process.exit(1);
  }

  const titles = new Map(); // title → total_vols

  let catEntries;
  try {
    catEntries = fs.readdirSync(COMICS_ROOT, { withFileTypes: true })
      .filter(e => e.isDirectory())
      .sort((a, b) => a.name.localeCompare(b.name, 'ja'));
  } catch (err) {
    console.error(`[エラー] ${COMICS_ROOT} を読み取れません: ${err.message}`);
    process.exit(1);
  }

  for (const catEntry of catEntries) {
    if (!isCategoryFolder(catEntry.name)) continue;

    const isSpecial = catEntry.name.startsWith('_');
    const catPath = path.join(COMICS_ROOT, catEntry.name);

    let titleEntries;
    try {
      titleEntries = fs.readdirSync(catPath, { withFileTypes: true })
        .filter(e => e.isDirectory())
        .sort((a, b) => a.name.localeCompare(b.name, 'ja'));
    } catch {
      continue;
    }

    for (const titleEntry of titleEntries) {
      const rawName = titleEntry.name;
      // '_' フォルダ配下は末尾の巻数を除去してタイトルを取得
      const title = isSpecial ? stripVolumeSuffix(rawName) : rawName;
      if (!title) continue;

      const titlePath = path.join(catPath, rawName);
      const volCount = countVolumes(titlePath);
      if (volCount === 0) continue; // 対応ファイルなしはスキップ

      // 重複タイトルは巻数を合算
      titles.set(title, (titles.get(title) ?? 0) + volCount);
    }
  }

  if (titles.size === 0) {
    console.warn('[警告] 対象作品が見つかりませんでした。');
    console.warn(`       スキャン対象: ${COMICS_ROOT}`);
    process.exit(0);
  }

  // ソート（NFKC正規化後に辞書順）
  const sortedTitles = [...titles.entries()]
    .sort(([a], [b]) => a.normalize('NFKC').localeCompare(b.normalize('NFKC'), 'ja'));

  // ── CSV 出力 ──
  // Bookly の importCSV が期待する14列（位置固定）
  const header = ['タイトル','著者','カテゴリ','タイプ','読了巻/P','全巻/P','ステータス','形態','評価','読了日','メモ','完結済み','次巻発売日','発売日'];

  const lines = [
    '﻿' + csvRow(header), // BOM付きで Excel でも文字化けしない
    ...sortedTitles.map(([title, totalVols]) => csvRow([
      title,       // タイトル
      '',          // 著者
      'manga',     // カテゴリ（Bookly内部コード: manga=漫画）
      'series',    // タイプ
      0,           // 読了巻/P（全巻未読として0）
      totalVols,   // 全巻/P
      'reading',   // ステータス
      '',          // 形態
      '',          // 評価
      '',          // 読了日
      '',          // メモ
      'false',     // 完結済み
      '',          // 次巻発売日
      '',          // 発売日
    ])),
  ];

  fs.mkdirSync(path.dirname(OUTPUT_CSV), { recursive: true });
  fs.writeFileSync(OUTPUT_CSV, lines.join('\r\n'), 'utf8');

  // ── 結果サマリー ──
  const totalVolsAll = [...titles.values()].reduce((s, v) => s + v, 0);
  console.log(`[完了] ${sortedTitles.length} 作品 / 計 ${totalVolsAll} 巻`);
  console.log(`       → ${OUTPUT_CSV}`);
  console.log();

  const previewCount = Math.min(20, sortedTitles.length);
  console.log(`--- 先頭${previewCount}作品 ---`);
  for (const [title, vols] of sortedTitles.slice(0, previewCount)) {
    console.log(`  ${title.padEnd(30)} ${String(vols).padStart(4)} 巻`);
  }
  if (sortedTitles.length > previewCount) {
    console.log(`  ...他 ${sortedTitles.length - previewCount} 作品`);
  }
}

main();
