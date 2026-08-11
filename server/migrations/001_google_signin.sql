-- Login com Google.
--
-- Rode isto no SQL Editor do Neon (projeto "buggo", branch "production")
-- ANTES de publicar a versão do app com o botão "Entrar com Google".
-- É seguro rodar mais de uma vez.

-- Quem entra pelo Google nunca define senha, então a coluna deixa de ser
-- obrigatória.
alter table users alter column password_hash drop not null;

-- Identificador estável do usuário no Google (a claim "sub" do ID token).
-- Não usamos o e-mail como chave porque o Google permite trocá-lo.
alter table users add column if not exists google_sub text;

create unique index if not exists users_google_sub_idx
  on users (google_sub) where google_sub is not null;

-- Toda conta precisa de pelo menos uma forma de entrar. Sem isto, um bug
-- futuro poderia criar uma linha sem senha e sem Google — uma conta órfã,
-- impossível de acessar e impossível de recadastrar (o e-mail já existiria).
alter table users drop constraint if exists users_has_auth_method;
alter table users add constraint users_has_auth_method
  check (password_hash is not null or google_sub is not null);
