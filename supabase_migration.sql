-- Last 1% — Database Schema Migration
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor)

-- 1. Users table (extends auth.users via trigger)
create table public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  created_at timestamptz default now() not null,
  email text,
  username text,
  avatar_url text,
  timezone text default 'UTC'
);

-- 2. Daily logs table
create table public.daily_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  date date not null,
  category text not null,
  effort_level integer not null check (effort_level >= 1 and effort_level <= 5),
  note text,
  photo_url text,
  created_at timestamptz default now() not null,
  unique(user_id, date)
);

-- 3. Streaks table
create table public.streaks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null unique,
  current_streak integer default 0 not null,
  longest_streak integer default 0 not null,
  last_log_date date
);

-- 4. Weekly stats table
create table public.weekly_stats (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  week_start_date date not null,
  logs_count integer default 0 not null,
  strongest_category text,
  weakest_category text,
  unique(user_id, week_start_date)
);

-- Indexes
create index idx_daily_logs_user_date on public.daily_logs(user_id, date);
create index idx_daily_logs_user_created on public.daily_logs(user_id, created_at);
create index idx_weekly_stats_user_week on public.weekly_stats(user_id, week_start_date);

-- Enable Row Level Security
alter table public.users enable row level security;
alter table public.daily_logs enable row level security;
alter table public.streaks enable row level security;
alter table public.weekly_stats enable row level security;

-- RLS: users
create policy "Users can view own profile"
  on public.users for select using (auth.uid() = id);
create policy "Users can update own profile"
  on public.users for update using (auth.uid() = id);
create policy "Users can insert own profile"
  on public.users for insert with check (auth.uid() = id);

-- RLS: daily_logs
create policy "Users can view own logs"
  on public.daily_logs for select using (auth.uid() = user_id);
create policy "Users can insert own logs"
  on public.daily_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own logs"
  on public.daily_logs for update using (auth.uid() = user_id);
create policy "Users can delete own logs"
  on public.daily_logs for delete using (auth.uid() = user_id);

-- RLS: streaks
create policy "Users can view own streak"
  on public.streaks for select using (auth.uid() = user_id);
create policy "Users can insert own streak"
  on public.streaks for insert with check (auth.uid() = user_id);
create policy "Users can update own streak"
  on public.streaks for update using (auth.uid() = user_id);

-- RLS: weekly_stats
create policy "Users can view own weekly stats"
  on public.weekly_stats for select using (auth.uid() = user_id);
create policy "Users can insert own weekly stats"
  on public.weekly_stats for insert with check (auth.uid() = user_id);
create policy "Users can update own weekly stats"
  on public.weekly_stats for update using (auth.uid() = user_id);

-- Trigger: auto-create user profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Storage: create bucket for log photos
insert into storage.buckets (id, name, public)
values ('log-photos', 'log-photos', true);

-- Storage RLS policies
create policy "Users can upload own photos"
  on storage.objects for insert with check (
    bucket_id = 'log-photos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );
create policy "Anyone can view log photos"
  on storage.objects for select using (
    bucket_id = 'log-photos'
  );
create policy "Users can delete own photos"
  on storage.objects for delete using (
    bucket_id = 'log-photos' and
    auth.uid()::text = (storage.foldername(name))[1]
  );
