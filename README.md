# Projeto Valit

Sistema com login e cadastro de usuários.

- **backEnd/** – API em Node.js + Express + MySQL (porta **3309**)
- **front_end/** – Next.js (porta **3000**)

## Rodando com Docker (recomendado)

Só precisa do **Docker Desktop** aberto. Na pasta do projeto:

```bash
docker compose up -d --build
```

Na primeira vez demora alguns minutos. Depois acesse http://localhost:3000 (login: teste@email.com / 123456).

| Serviço | Endereço |
|---|---|
| Frontend | http://localhost:3000 |
| API | http://localhost:3309/api/health |
| MySQL (Workbench) | 127.0.0.1, porta **3307**, usuário root / senha senai@123 |

Comandos úteis:

```bash
docker compose ps              # ver se os 3 containers estão rodando
docker compose logs -f backend # ver os logs da API
docker compose down            # parar tudo (os dados do banco são mantidos)
docker compose down -v         # parar e APAGAR o banco (recria do zero no próximo up)
```

> Alterou o código? Rode `docker compose up -d --build` de novo.

## Sem Docker: jeito rápido (Windows)

Com o Node.js e o MySQL instalados, dê dois cliques em **`iniciar.bat`**. Ele instala tudo, cria o banco, sobe o backend e o frontend e abre o navegador. Nas próximas vezes, use **`rodar.bat`**.

## Pré-requisitos

- Node.js 20 ou superior
- MySQL 8 (ou MariaDB) rodando na porta 3306

## 1. Backend

```bash
cd backEnd
npm install
cp .env.example .env        # no Windows: copy .env.example .env
# ajuste DB_USER / DB_PASSWORD no .env se o seu MySQL for diferente
npm run db:setup            # cria o banco db_valit, a tabela e o usuário de teste
npm run dev
```

Deve aparecer: `API rodando na porta 3309` e `Conectado ao banco de dados.`

> Alternativa ao `db:setup`: executar o arquivo `backEnd/database.sql` no MySQL Workbench.

## 2. Frontend (em outro terminal)

```bash
cd front_end
npm install
cp .env.local.example .env.local   # no Windows: copy .env.local.example .env.local
npm run dev
```

Acesse http://localhost:3000

## Usuário de teste

| E-mail | Senha |
|---|---|
| teste@email.com | 123456 |

## Rotas da API

| Método | Rota | Descrição |
|---|---|---|
| GET  | /api/health | Verifica se a API está no ar |
| POST | /api/auth/login | `{ usuario, senha }` → `{ token }` |
| POST | /api/auth/cadastro | `{ usuario, senha }` → `{ token }` (senha mín. 6 caracteres) |
| GET  | /api/auth/me | Header `Authorization: Bearer <token>` → dados do usuário logado |

## Páginas

- `/` – Login
- `/cadastro` – Criar conta
- `/produtos` – Área logada (protegida por token)
