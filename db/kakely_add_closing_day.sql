-- kakely_payment_methods にクレカの締め日カラムを追加
-- （引き落とし予定日の計算に使用。withdrawal_date と合わせて利用）
-- Supabase ダッシュボード > SQL Editor で実行してください

alter table kakely_payment_methods
  add column if not exists closing_day integer;
