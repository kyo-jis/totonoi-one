-- kakely_payment_methods にクレカ用カラムを追加
-- Supabase ダッシュボード > SQL Editor で実行してください

alter table kakely_payment_methods
  add column if not exists brand text,
  add column if not exists expiry text;
