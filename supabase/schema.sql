-- Ejecutar en Supabase SQL Editor. RLS: cada usuario solo consulta sus propios registros.
create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text default '#607D8B',
  created_at timestamptz not null default now(),
  unique(user_id, name)
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  amount numeric(12,2) not null check (amount > 0),
  period text not null default 'mensual' check (period in ('semanal','mensual')),
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  uuid text not null unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  amount numeric(12,2) not null check (amount > 0),
  category text not null,
  date date not null,
  note text,
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;
alter table public.budgets enable row level security;
alter table public.expenses enable row level security;

create policy "categories owner only" on public.categories for all
using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "budgets owner only" on public.budgets for all
using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "expenses owner only" on public.expenses for all
using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists expenses_user_date_idx on public.expenses(user_id, date desc);
create index if not exists budgets_user_idx on public.budgets(user_id);
