-- Rode isto uma vez no Neon (SQL Editor do projeto "buggo", branch
-- "production") antes de usar o backend.

create extension if not exists pgcrypto;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  password_hash text not null,
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

create table if not exists password_reset_tokens (
  token text primary key,
  user_id uuid not null references users(id) on delete cascade,
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);

-- ── Login com Google + compras do Google Play ────────────────────────────
-- Rode este bloco no mesmo SQL Editor do Neon. É idempotente.

-- Conta criada pelo Google não tem senha, então password_hash deixa de ser
-- obrigatório. Contas antigas (e-mail/senha) seguem funcionando.
alter table users alter column password_hash drop not null;

-- "sub" do token do Google. Único, mas nulo para quem entra por senha.
alter table users add column if not exists google_id text;
create unique index if not exists users_google_id_idx on users (google_id)
  where google_id is not null;

-- Uma linha por compra confirmada pela Play Developer API. A chave primária
-- ser o purchase_token é o que impede replay: reenviar o mesmo token não
-- credita moedas de novo.
create table if not exists purchases (
  purchase_token text primary key,
  user_id uuid not null references users(id) on delete cascade,
  product_id text not null,
  kind text not null check (kind in ('product', 'subscription')),
  coins_granted int4 not null default 0,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists purchases_user_idx on purchases (user_id);

-- ── Histórico do monitor ─────────────────────────────────────────────────
-- Rode este bloco no SQL Editor do Neon. É idempotente.
--
-- Uma linha por minuto, no máximo: a chave primária é o minuto arredondado,
-- e /api/health insere com "on conflict do nothing". Assim o gráfico tem
-- histórico de verdade (inclusive de quando ninguém está olhando, graças à
-- checagem de hora em hora do GitHub Actions) sem que um monte de acessos
-- à página vire um monte de escrita no banco.
--
-- Sem esta tabela o monitor continua funcionando: ele só mostra o gráfico
-- vazio e avisa que o histórico não está disponível.
create table if not exists health_samples (
  bucket timestamptz primary key,
  status text not null,
  total_ms int4 not null,
  db_ms int4
);

create index if not exists health_samples_bucket_idx on health_samples (bucket desc);

-- ── Desafio diário gerado por IA ─────────────────────────────────────────
-- Rode este bloco no SQL Editor do Neon. É idempotente.
--
-- O desafio é personalizado pela trilha e pelo ponto em que a pessoa está,
-- não por pessoa: quem estuda Rust e terminou o nível 1 recebe o mesmo
-- desafio de quem está no mesmo lugar. Isso mantém a geração limitada (uma
-- por combinação por dia, no pior caso) e ainda permite comparar quem
-- resolveu.
create table if not exists daily_challenges (
  id uuid primary key default gen_random_uuid(),
  challenge_date date not null,
  language_id text not null,
  stage int4 not null,
  difficulty text not null check (difficulty in ('facil', 'media', 'dificil')),
  -- Enunciado, alternativas e gabarito. O gabarito nunca sai daqui: a
  -- resposta é conferida no servidor.
  payload jsonb not null,
  generator_model text not null,
  reviewer_model text,
  review_notes text,
  created_at timestamptz not null default now(),
  unique (challenge_date, language_id, stage)
);

create index if not exists daily_challenges_lookup_idx
  on daily_challenges (challenge_date, language_id, stage);

-- Um resgate por pessoa por dia. A chave primária é o que impede farmar
-- moedas reenviando a mesma resposta — mesma ideia do purchase_token.
create table if not exists daily_completions (
  user_id uuid not null references users(id) on delete cascade,
  challenge_date date not null,
  challenge_id uuid not null references daily_challenges(id) on delete cascade,
  coins_granted int4 not null,
  created_at timestamptz not null default now(),
  primary key (user_id, challenge_date)
);

create index if not exists daily_completions_user_idx
  on daily_completions (user_id, challenge_date desc);

-- ── Recarga de vidas por anúncio ─────────────────────────────────────────
-- Guarda quando o usuário assistiu ao último anúncio recompensado. O limite
-- é de uma recarga por dia; guardado só no aparelho, bastava limpar os dados
-- do app para assistir de novo.
alter table users add column if not exists last_ad_refill_at timestamptz;

-- ── Avatares pagos ───────────────────────────────────────────────────────
-- Índices dos avatares comprados com moeda. Os gratuitos não entram: valem
-- para todo mundo e não precisam ser gravados por usuário.
alter table users add column if not exists unlocked_avatars int4[] not null default '{}';
