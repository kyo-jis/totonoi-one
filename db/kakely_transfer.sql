-- =====================================================
-- kakely_transactions に is_transfer カラムを追加
-- Supabase SQL Editor で実行してください
-- =====================================================

ALTER TABLE public.kakely_transactions
  ADD COLUMN IF NOT EXISTS is_transfer boolean DEFAULT false;
