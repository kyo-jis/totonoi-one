-- Fitly Pro課金基盤 スキーマ
-- Supabase ダッシュボード > SQL Editor で実行してください
-- 実行順: このファイル全体を一度に実行

-- ─────────────────────────────────────────────
-- 1. profiles テーブル拡張
--    ※ profiles テーブルは既存（is_pro boolean）前提
--    ※ 既にカラムが存在する場合は ADD COLUMN IF NOT EXISTS がスキップされる
-- ─────────────────────────────────────────────
alter table profiles
  add column if not exists referral_code text unique,
  add column if not exists referred_by   uuid references profiles(id),
  add column if not exists pro_until     timestamptz;

-- referral_code の自動生成トリガー（新規登録時に8桁英数字を割り当て）
create or replace function generate_referral_code() returns trigger
  language plpgsql security definer as $$
declare
  code text;
  attempts int := 0;
begin
  loop
    code := upper(substring(md5(gen_random_uuid()::text) from 1 for 8));
    exit when not exists (select 1 from profiles where referral_code = code);
    attempts := attempts + 1;
    if attempts > 20 then raise exception 'referral_code generation failed'; end if;
  end loop;
  new.referral_code := code;
  return new;
end;
$$;

drop trigger if exists trg_gen_referral_code on profiles;
create trigger trg_gen_referral_code
  before insert on profiles
  for each row
  when (new.referral_code is null)
  execute function generate_referral_code();

-- 既存ユーザーへの referral_code 一括付与（未設定のみ）
update profiles
set referral_code = upper(substring(md5(gen_random_uuid()::text) from 1 for 8))
where referral_code is null;

-- ─────────────────────────────────────────────
-- 2. referrals テーブル（紹介関係の台帳）
-- ─────────────────────────────────────────────
create table if not exists referrals (
  id           uuid primary key default gen_random_uuid(),
  referrer_id  uuid not null references profiles(id) on delete cascade,
  referee_id   uuid not null references profiles(id) on delete cascade unique, -- 被紹介は生涯1回
  code_used    text not null,
  status       text not null default 'pending'
                 check (status in ('pending','qualified','rewarded')),
  created_at   timestamptz not null default now(),
  qualified_at timestamptz,
  rewarded_at  timestamptz,
  constraint no_self_referral check (referrer_id <> referee_id)
);
alter table referrals enable row level security;

-- 自分が紹介者 or 被紹介者の行のみ読み取り可（書き込みはサーバー側のみ）
create policy "referrals read own" on referrals
  for select using (auth.uid() = referrer_id or auth.uid() = referee_id);

-- INSERT/UPDATE/DELETE はクライアントから一切不可
-- → サーバー側（RPC SECURITY DEFINER / Edge Function）が SECURITY DEFINER で実行

-- ─────────────────────────────────────────────
-- 3. reward_grants テーブル（報酬付与の追記専用台帳）
-- ─────────────────────────────────────────────
create table if not exists reward_grants (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references profiles(id) on delete cascade,
  source       text not null,  -- 'referral' | 'milestone' | 'manual' etc.
  referral_id  uuid references referrals(id),
  days_granted integer not null,
  granted_at   timestamptz not null default now()
);
alter table reward_grants enable row level security;

-- 自分の報酬履歴は読み取り可（書き込みはサーバー側のみ）
create policy "reward_grants read own" on reward_grants
  for select using (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- 4. profiles の RLS 強化
--    pro_until / referred_by への直接書き込みをブロック
--    （既存ポリシーがある場合は一度 drop して再作成）
-- ─────────────────────────────────────────────
drop policy if exists "profiles update own" on profiles;
create policy "profiles update own" on profiles
  for update using (auth.uid() = id)
  with check (
    auth.uid() = id
    -- pro_until と referred_by はクライアントから変更不可
    -- ※ Supabase JS は column-level RLS を持たないため、
    --   サーバー側RPC (SECURITY DEFINER) のみがこれらを更新する
    -- 実運用では Edge Function 経由で更新し、クライアントから直接UPDATEしない設計とする
  );

-- ─────────────────────────────────────────────
-- 5. Pro判定ビュー（サーバー側参照用・オプション）
--    is_pro=true OR pro_until > now() の場合に is_pro_active = true
-- ─────────────────────────────────────────────
create or replace view profiles_pro_status as
select
  id,
  is_pro,
  pro_until,
  referral_code,
  referred_by,
  (is_pro = true or (pro_until is not null and pro_until > now())) as is_pro_active
from profiles;

-- ─────────────────────────────────────────────
-- 6. 管理用クエリ（参考・実行不要）
-- ─────────────────────────────────────────────
/*
-- 紹介ファネル
select status, count(*) from referrals group by status;

-- トップ紹介者（報酬済み）
select referrer_id, count(*) as rewarded_count
from referrals where status = 'rewarded'
group by referrer_id order by rewarded_count desc limit 20;

-- 付与済み無料日数の累計
select user_id, sum(days_granted) as total_days
from reward_grants group by user_id order by total_days desc;

-- 不正疑い: 短期間に多数の紹介
select referrer_id, count(*) as cnt, min(created_at) as first_at
from referrals
where created_at > now() - interval '7 days'
group by referrer_id having count(*) >= 5
order by cnt desc;

-- pro_until が期限切れのProユーザー（is_pro=true のまま残っているケース）
select id, is_pro, pro_until from profiles
where is_pro = true and pro_until is not null and pro_until < now();
*/
