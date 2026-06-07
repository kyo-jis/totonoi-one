-- =====================================================
-- kakely テーブルのカラム追加
-- Supabase SQL Editor で実行してください
-- =====================================================

-- 1. kakely_payment_methods に balance カラムを追加
--    （残高管理機能で使用。現金・銀行口座などに残高を記録）
ALTER TABLE public.kakely_payment_methods
  ADD COLUMN IF NOT EXISTS balance integer;

-- 2. kakely_transactions に group_id カラムを追加
--    （資金移動のペアを紐付けるために使用）
ALTER TABLE public.kakely_transactions
  ADD COLUMN IF NOT EXISTS group_id text;
