# Buggo Server

API protegida em frente ao Neon Postgres usada pelo app Flutter (Buggo) para
login, sincronização de perfil e ranking. O app nunca se conecta direto no
Postgres — só chama esta API por HTTPS.

## Deploy (Vercel)

1. Crie um novo projeto na Vercel apontando para este repositório.
2. Em **Settings > General > Root Directory**, defina `server`.
3. Em **Settings > Environment Variables**, adicione as chaves listadas em
   `.env.example` (`DATABASE_URL`, `JWT_SECRET`, `GMAIL_USER`,
   `GMAIL_APP_PASSWORD`, `APP_URL`).
4. Rode `schema.sql` uma vez no SQL Editor do Neon (projeto `buggo`, branch
   `production`) para criar as tabelas.
5. Faça o deploy. A URL gerada (ex: `https://buggo-api.vercel.app`) é o valor
   que vai em `API_BASE_URL` no `.env` do app Flutter.

## Desenvolvimento local

```bash
cd server
npm install
cp .env.example .env   # preencha com um DATABASE_URL de teste
npm run dev             # roda `vercel dev`, exige `vercel login` antes
npm run typecheck
```

## Endpoints

- `POST /api/auth/signup` — `{ email, password, name }` → `{ token, profile }`
- `POST /api/auth/login` — `{ email, password }` → `{ token, profile }`
- `POST /api/auth/forgot-password` — `{ email }` → sempre `200`; envia e-mail
  se a conta existir
- `POST /api/auth/reset-password` — `{ token, newPassword }`
- `GET /api/profile` — header `Authorization: Bearer <token>`
- `PUT /api/profile` — header `Authorization: Bearer <token>`, corpo = perfil
  completo
- `GET /api/leaderboard?by=xp|streak&limit=20` — público
