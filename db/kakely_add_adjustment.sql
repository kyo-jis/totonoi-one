-- =====================================================
-- kakely_transactions に is_adjustment カラムを追加
-- （残高調整機能で使用。実残高との差額を「調整」取引として記録し、
--   収支統計からは除外する。振替 is_transfer と同じ「集計除外」フラグ）
-- Supabase ダッシュボード > SQL Editor で実行してください
-- =====================================================

ALTER TABLE public.kakely_transactions
  ADD COLUMN IF NOT EXISTS is_adjustment boolean DEFAULT false;
