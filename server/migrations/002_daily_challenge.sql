-- Desafio diário gerado e corrigido pela DeepSeek.
--
-- Rode no SQL Editor do Neon (projeto "buggo", branch "production").
-- É seguro rodar mais de uma vez.

create table if not exists daily_challenges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,

  -- Data no fuso de São Paulo (ver lib/challenge.ts). Um desafio por dia por
  -- aluno: a constraint abaixo é o que impede duas chamadas simultâneas de
  -- gerarem (e cobrarem) dois desafios diferentes.
  challenge_date date not null,

  language text not null,
  title text not null,
  statement text not null,
  starter_code text not null,

  -- Gabarito: o que o código precisa fazer para passar. NUNCA é enviado ao
  -- app — se fosse, bastaria abrir o tráfego para ver a resposta. Só a rota
  -- de correção lê esta coluna.
  expected_behavior text not null,

  xp_reward int4 not null default 40,
  coin_reward int4 not null default 20,

  solved boolean not null default false,
  attempts int4 not null default 0,
  last_feedback text,

  created_at timestamptz not null default now(),

  constraint daily_challenges_user_date_key unique (user_id, challenge_date)
);

create index if not exists daily_challenges_user_idx
  on daily_challenges (user_id, challenge_date desc);
