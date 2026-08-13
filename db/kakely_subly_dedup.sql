-- Kakely: サブスク自動追加の重複クリーンアップ＋再発防止
-- Supabase ダッシュボード > SQL Editor で実行してください
--
-- 背景: syncFromCloud の二重実行で「サブスク自動追加:<id>:<date>」の記録が
-- 2件入ることがあった。アプリ側にもガード・自動修復を入れたが、
-- 複数端末の同時アクセスに備えて DB 側でも一意性を保証する。

-- 1) 既存の重複を削除（同じユーザー×同じmemo×同じ日付は最古の1件だけ残す）
delete from kakely_transactions t
using kakely_transactions k
where t.user_id = k.user_id
  and t.memo = k.memo
  and t.date = k.date
  and t.memo like 'サブスク自動追加:%'
  and (k.created_at < t.created_at
       or (k.created_at = t.created_at and k.id < t.id));

-- 2) 再発防止: サブスク自動追加の記録に部分ユニークインデックス
create unique index if not exists kakely_txn_subly_auto_unique
  on kakely_transactions(user_id, memo, date)
  where memo like 'サブスク自動追加:%';
