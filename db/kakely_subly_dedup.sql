-- Kakely: 自動追加レコード（サブスク・固定費・分割払い）の重複クリーンアップ＋再発防止
-- Supabase ダッシュボード > SQL Editor で実行してください
--
-- 背景: syncFromCloud の二重実行で「サブスク自動追加:」「固定費:」「分割:」の
-- 自動追加レコードが同じ日に複数件入ることがあった。アプリ側にも同期ゲート・
-- 自動修復を入れたが、複数端末の同時アクセスに備えて DB 側でも一意性を保証する。
--
-- ※ 2026-08-13 に既存重複21件（分割20・固定費1）は REST 経由で削除済み。
--    このSQLの 1) は再実行しても安全（何も残っていなければ0件削除）。

-- 1) 既存の重複を削除（同じユーザー×同じmemo×同じ日付は最古の1件だけ残す）
delete from kakely_transactions t
using kakely_transactions k
where t.user_id = k.user_id
  and t.memo = k.memo
  and t.date = k.date
  and (t.memo like 'サブスク自動追加:%' or t.memo like '固定費:%' or t.memo like '分割:%')
  and (k.created_at < t.created_at
       or (k.created_at = t.created_at and k.id < t.id));

-- 2) 再発防止: 自動追加レコードに部分ユニークインデックス
create unique index if not exists kakely_txn_auto_unique
  on kakely_transactions(user_id, memo, date)
  where memo like 'サブスク自動追加:%' or memo like '固定費:%' or memo like '分割:%';
