-- Rode isto uma vez no Neon (SQL Editor do projeto "buggo", branch
-- "production") antes de usar o backend.

create extension if not exists pgcrypto;

-- Instalação nova já nasce com o login Google. Banco que existia antes
-- disso: rode migrations/001_google_signin.sql em vez deste arquivo.
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  -- Nulo para contas criadas pelo Google, que não têm senha.
  password_hash text,
  -- Claim "sub" do ID token do Google. Chave estável: o e-mail pode mudar.
  google_sub text,
  name text not null,
  language text not null default 'logic',
  level text not null default 'adult',
  daily_goal_minutes int4 not null default 15,
  xp int4 not null default 0,
  coins int4 not null default 0,
  streak int4 not null default 0,
  last_study_date timestamptz,
  completed_lessons text[] not null default '{}',
  unlocked_achievements text[] not null default '{}',
  avatar_index int4 not null default 0,
  custom_photo_path text,
  lives int4 not null default 5,
  last_life_lost_at timestamptz,
  unlimited_lives_until timestamptz,
  streak_freezes int4 not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists users_xp_idx on users (xp desc);
create index if not exists users_streak_idx on users (streak desc);

create unique index if not exists users_google_sub_idx
  on users (google_sub) where google_sub is not null;

-- Toda conta precisa de pelo menos uma forma de entrar.
alter table users drop constraint if exists users_has_auth_method;
alter table users add constraint users_has_auth_method
  check (password_hash is not null or google_sub is not null);

create table if not exists password_reset_tokens (
  token text primary key,
  user_id uuid not null references users(id) on delete cascade,
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);
