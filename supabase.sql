-- Execute este SQL no Supabase > SQL Editor.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  salary numeric(12,2) not null default 2759.74,
  advance_pct numeric(5,2) not null default 40,
  inss numeric(12,2) not null default 224.05,
  assist_pct numeric(5,2) not null default 2,
  life numeric(12,2) not null default 3.82,
  negocial numeric(12,2) not null default 21,
  save_goal numeric(12,2) not null default 0,
  card_limit numeric(12,2) not null default 600,
  horizon integer not null default 12,
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  month integer not null,
  year integer not null,
  type text not null check (type in ('Receita','Despesa','Investimento')),
  category text not null,
  description text not null,
  payment text,
  value numeric(12,2) not null check (value >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  target numeric(12,2) not null default 0,
  saved numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.goals enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles for select using (auth.uid() = id);
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert with check (auth.uid() = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update using (auth.uid() = id);

drop policy if exists transactions_all_own on public.transactions;
create policy transactions_all_own on public.transactions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists goals_all_own on public.goals;
create policy goals_all_own on public.goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();
