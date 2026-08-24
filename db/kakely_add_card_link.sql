-- 電子マネー（D払い等）の「請求先カード」紐付け用カラムを追加
-- Supabase ダッシュボード > SQL Editor で実行してください
-- card_id は emoney 種別の支払い方法に、請求先のクレジットカード（kakely_payment_methods.id）を保持する。
-- FK 制約は付けない（ローカル先行の一時IDも受けられるよう text 型）。

alter table kakely_payment_methods
  add column if not exists card_id text;
