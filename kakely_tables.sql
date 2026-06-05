-- Kakely テーブル作成 SQL
-- Supabase ダッシュボード > SQL Editor で実行してください

-- カテゴリ
create table if not exists kakely_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  icon text not null default '❓',
  name text not null,
  budget integer,
  sort_order integer not null default 0,
  created_at timestamptz default now()
);
alter table kakely_categories enable row level security;
create policy "own categories" on kakely_categories
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 支払い方法
create table if not exists kakely_payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  icon text not null default '💳',
  name text not null,
  type text not null default 'cash',
  withdrawal_date integer,
  created_at timestamptz default now()
);
alter table kakely_payment_methods enable row level security;
create policy "own payment methods" on kakely_payment_methods
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 収支記録
create table if not exists kakely_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  amount integer not null,
  date date not null,
  is_income boolean not null default false,
  category_id uuid references kakely_categories(id) on delete set null,
  payment_method_id uuid references kakely_payment_methods(id) on delete set null,
  memo text,
  created_at timestamptz default now()
);
alter table kakely_transactions enable row level security;
create policy "own transactions" on kakely_transactions
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- インデックス（月別検索を高速化）
create index if not exists kakely_transactions_user_date
  on kakely_transactions(user_id, date);
