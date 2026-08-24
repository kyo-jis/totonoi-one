-- カードの「引き落とし口座」紐付け用カラムを追加
-- Supabase ダッシュボード > SQL Editor で実行してください
-- bank_id はカード種別の支払い方法に、引き落とし先の銀行口座（kakely_payment_methods.id）を保持する。
-- FK 制約は付けない（ローカル先行の一時IDも受けられるよう text 型）。

alter table kakely_payment_methods
  add column if not exists bank_id text;
