# Valit


Sistema web para **controle de validade de produtos** em pequenas e médias empresas: mostra o que está vencido ou perto de vencer, para reduzir desperdício, prejuízo e descarte de mercadorias.

Projeto **PSOF · 3MD · Manhã** · [Logo no Canva](https://canva.link/0sfddx651wxve7n)

| Integrante | Função |
|---|---|
| Gabriel Escobar Silva | Desenvolvedor Front-End |
| Heitor Magnane de Farias | Gerente de Projetos e Desenvolvedor Back-End |
| Leonardo Ferreira Virginio | Analista de Banco de Dados |
| Luiz Fillipe Santana dos Reis | Desenvolvedor de Banco de Dados |
| Matheus Rodrigues da Silva | Desenvolvedor Front-End |

**Sumário:** [Acesso para avaliação](#acesso-para-avaliação) · [Funcionalidades](#funcionalidades) · [Como rodar](#como-rodar) · [Logins e níveis de acesso](#logins-e-níveis-de-acesso) · [Documentação de desenvolvimento](#documentação-de-desenvolvimento)

---

## Acesso para avaliação

Logins de teste, criados automaticamente na primeira vez que a API inicia:

| Perfil | E-mail | Senha | O que dá para testar |
|---|---|---|---|
| **Administrador** | `admin@valit.com` | `admin123` | Tudo: produtos, exclusão, relatórios e a tela **Usuários** |
| **Funcionário** | `teste@email.com` | `123456` | Produtos (cadastrar, editar, filtrar) e relatórios; sem exclusão e sem Usuários |

Como testar:

1. Rode o projeto seguindo [Como rodar](#como-rodar) e acesse http://localhost:3000.
2. Entre como **Funcionário**: a lista já vem com 6 produtos de exemplo (vencido, vencendo em breve e dentro da validade). Cadastre um produto, clique nos cartões de resumo para filtrar e use **Exportar PDF** / **Exportar CSV**.
3. Clique em **Sair** e entre como **Administrador**: aparecem o botão **Excluir** e o menu **Usuários**, onde é possível criar um funcionário, mudar o nível de acesso ou desativá-lo.
4. Use o botão de lua/sol no topo para alternar entre modo claro e escuro.

---

## Funcionalidades

1. **Login do funcionário** com dois níveis de acesso (Administrador e Funcionário)
2. **Cadastro de produtos**: nome, categoria, lote, quantidade, data de validade e observação
3. **Listagem de produtos** ordenada pelo vencimento, com status (Vencido / Vence em breve / Dentro da validade), cartões de resumo, busca e filtros
4. **Exportação de relatórios** em **PDF** (com logo) ou **CSV** (Excel), respeitando os filtros da tela
5. **Gestão de usuários** (só administrador): criar, mudar nível de acesso, desativar, redefinir senha, excluir
6. **Modo claro / escuro** (preto e branco), com a escolha salva no navegador

## Como rodar

**Pré-requisitos:** Node.js 20 ou superior e MySQL 8 (ou MariaDB) rodando na porta 3306.

**1. Backend** (terminal 1)

```bash
cd backEnd
npm install
copy .env.example .env      # Linux/Mac: cp .env.example .env
# se o seu MySQL não usar root / senai@123, ajuste DB_USER e DB_PASSWORD no .env
npm run db:setup            # cria o banco db_valit, as tabelas, os logins de teste e produtos de exemplo
npm run dev
```

Deve aparecer `Banco de dados pronto.` e `API rodando na porta 3309`.

> Alternativa ao `db:setup`: executar `backEnd/database.sql` no MySQL Workbench. As tabelas, os logins e os produtos de exemplo são completados pela API ao iniciar.

**2. Frontend** (terminal 2)

```bash
cd front_end
npm install
copy .env.local.example .env.local   # Linux/Mac: cp .env.local.example .env.local
npm run dev
```

**3.** Acesse **http://localhost:3000**.

| Serviço | Endereço |
|---|---|
| Site | http://localhost:3000 |
| API | http://localhost:3309/api/health |
| MySQL | 127.0.0.1:3306 · banco `db_valit` |

## Logins e níveis de acesso

| Nível | E-mail | Senha |
|---|---|---|
| Administrador | admin@valit.com | admin123 |
| Funcionário | teste@email.com | 123456 |

| Ação | Funcionário | Administrador |
|---|:---:|:---:|
| Entrar no sistema | ✓ | ✓ |
| Ver, buscar e filtrar produtos | ✓ | ✓ |
| Cadastrar e editar produtos | ✓ | ✓ |
| Exportar PDF / CSV | ✓ | ✓ |
| Excluir produtos | — | ✓ |
| Gerenciar usuários | — | ✓ |

> Para uso real, troque as senhas de teste na tela **Usuários**.

---

# Documentação de desenvolvimento

## Arquitetura

```
 Navegador ──JSON + token──▶  API (Node + Express)  ──SQL──▶  MySQL 8
 Next.js :3000                 :3309                           db_valit
```

- O **frontend** nunca acessa o banco: tudo passa pela API.
- A **API** confere login (JWT) e nível de acesso em toda requisição, calcula o status de validade e gera os relatórios.

| Camada | Tecnologia | Bibliotecas |
|---|---|---|
| Frontend | Next.js 16.4.5 + React 19 (App Router, componentes client) | @fontsource/poppins |
| Backend | Node.js 22 + Express 4 | mysql2, bcryptjs, jsonwebtoken, pdfkit, cors, dotenv |
| Banco | MySQL 8 (ou MariaDB) | — |

## Estrutura de pastas

```
projeto_valit/
├── backEnd/
│   ├── server.js                  # inicia a API: migra o banco e abre a porta
│   ├── database.sql               # script do banco (Workbench)
│   ├── scripts/setupDb.js         # npm run db:setup
│   ├── assets/logo.png            # logo usada no PDF
│   └── src/
│       ├── database/
│       │   ├── connection.js      # pool do MySQL (dateStrings: true)
│       │   └── migrate.js         # cria/atualiza tabelas e dados iniciais
│       ├── middlewares/
│       │   └── authMiddleware.js  # autenticar() e exigirPerfil("admin")
│       ├── routes/                # authRoutes, produtoRoutes, usuarioRoutes, relatorioRoutes
│       ├── controllers/           # validação da entrada e resposta HTTP
│       ├── models/                # SQL (produtoModel, usuarioModel)
│       ├── services/authService.js
│       └── utils/
│           ├── validade.js        # regra de status, DIAS_ALERTA, datas
│           └── capturar.js        # wrapper de erros para controllers async
├── front_end/
│   ├── public/logo.png
│   └── src/
│       ├── app/
│       │   ├── layout.jsx         # fonte, tema salvo (sem "piscar")
│       │   ├── globals.css        # variáveis de tema + estilos das telas internas
│       │   ├── page.jsx           # /          → Login
│       │   ├── produtos/page.jsx  # /produtos  → listagem, resumo, filtros, exportação
│       │   └── usuarios/page.jsx  # /usuarios  → só administrador
│       ├── components/
│       │   ├── AppShell.jsx       # menu, proteção de rota, contexto do usuário
│       │   ├── LoginForm.jsx + login.css
│       │   ├── ProdutoForm.jsx    # modal de cadastro/edição
│       │   ├── Modal.jsx
│       │   └── ThemeToggle.jsx    # modo claro/escuro
│       ├── services/              # api.js (fetch + token), authService, produtoService, usuarioService
│       └── utils/formatar.js      # datas dd/mm/aaaa, textos de prazo e status
└── README.md
```

**Camadas do backend:** `routes` (URL + permissões) → `controllers` (valida e responde) → `models` (SQL). Regras compartilhadas ficam em `utils`.

## Banco de dados

### Tabelas

**usuarios**

| Campo | Tipo | Observação |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| nome | VARCHAR(120) | |
| usuario | VARCHAR(100) UNIQUE | e-mail do login |
| senha | VARCHAR(255) | hash bcrypt |
| perfil | ENUM('admin','funcionario') | padrão `funcionario` |
| ativo | TINYINT(1) | 0 bloqueia o acesso |
| criado_em | TIMESTAMP | |

**produtos**

| Campo | Tipo | Observação |
|---|---|---|
| id | INT PK AUTO_INCREMENT | |
| nome | VARCHAR(150) | obrigatório |
| categoria | VARCHAR(80) | |
| lote | VARCHAR(60) | |
| quantidade | INT | ≥ 0 |
| data_validade | DATE (índice) | obrigatório |
| observacao | VARCHAR(255) | |
| criado_por | INT FK → usuarios.id | `ON DELETE SET NULL` |
| criado_em / atualizado_em | TIMESTAMP | `atualizado_em` muda sozinho |

### Regra de validade

`dias_restantes = DATEDIFF(data_validade, CURDATE())`, calculado pelo MySQL (`src/utils/validade.js`).

| Status (API) | Texto na tela | Regra |
|---|---|---|
| `vencido` | Vencido | dias < 0 |
| `proximo` | Vence em breve | 0 ≤ dias ≤ `DIAS_ALERTA` (padrão 7) |
| `ok` | Dentro da validade | dias > `DIAS_ALERTA` |

### Migrações

`src/database/migrate.js` roda **toda vez que a API inicia** e é idempotente:

1. cria as tabelas que não existem;
2. adiciona colunas novas que faltam (consulta `information_schema`), o que atualiza bancos de versões antigas sem perder dados;
3. insere os logins de teste (`INSERT IGNORE`);
4. insere 6 produtos de exemplo **só se a tabela estiver vazia**.

Para mudar o banco: altere `database.sql` (instalações novas) **e** `migrate.js` (bancos existentes). Nunca apague colunas no `migrate.js` sem combinar com o time.

Enquanto o MySQL não responde, a API tenta de novo a cada 3 s e só abre a porta quando o banco está pronto.

## API

Base: `http://localhost:3309/api`. Fora `login` e `health`, toda rota exige `Authorization: Bearer <token>`.

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| GET | /health | público | API no ar |
| POST | /auth/login | público | `{ usuario, senha }` → `{ token, usuario }` |
| GET | /auth/me | logado | Usuário logado (nome, e-mail, perfil) |
| GET | /produtos | logado | Lista. Query: `busca`, `status` (`vencido`\|`proximo`\|`ok`), `categoria` |
| GET | /produtos/resumo | logado | `{ total, vencidos, proximos, ok, unidades, diasAlerta }` |
| GET | /produtos/categorias | logado | Categorias já usadas |
| GET | /produtos/:id | logado | Um produto |
| POST | /produtos | logado | Cadastrar |
| PUT | /produtos/:id | logado | Editar |
| DELETE | /produtos/:id | admin | Excluir |
| GET | /relatorios/produtos?formato=pdf\|csv | logado | Baixa o relatório (aceita os mesmos filtros da listagem) |
| GET | /usuarios | admin | Listar |
| POST | /usuarios | admin | Criar `{ nome, usuario, senha, perfil }` |
| PUT | /usuarios/:id | admin | Editar `{ nome?, perfil?, ativo?, senha? }` |
| DELETE | /usuarios/:id | admin | Excluir |

Exemplo de produto retornado:

```json
{
  "id": 3,
  "nome": "Pão de forma",
  "categoria": "Padaria",
  "lote": "PF4410",
  "quantidade": 15,
  "data_validade": "2026-11-14",
  "observacao": "",
  "dias_restantes": 5,
  "status": "proximo",
  "criado_por_nome": "Administrador"
}
```

**Erros:** sempre `{ "message": "texto em português" }` com 400 (dados inválidos), 401 (sem login / sessão inválida / usuário desativado), 403 (sem permissão), 404 (não encontrado) ou 409 (e-mail já cadastrado).

Teste rápido pelo terminal:

```bash
curl -X POST http://localhost:3309/api/auth/login -H "Content-Type: application/json" \
  -d "{\"usuario\":\"admin@valit.com\",\"senha\":\"admin123\"}"
# copie o token e:
curl http://localhost:3309/api/produtos -H "Authorization: Bearer SEU_TOKEN"
```

## Autenticação e permissões

1. `POST /auth/login` confere a senha com bcrypt e devolve um **JWT de 8 h** com `id`, `usuario` e `perfil`.
2. O frontend guarda `token` e `usuario` no `localStorage` (`services/authService.js`).
3. `services/api.js` envia o token em toda chamada. Se a API responder **401**, limpa a sessão e volta ao login.
4. No backend, `autenticar` valida o token **e busca o usuário no banco** a cada requisição: quem foi desativado perde o acesso na hora, e mudanças de perfil valem imediatamente.
5. `exigirPerfil("admin")` protege rotas de administrador.
6. Regras de usuário: não é possível rebaixar, desativar ou excluir o **último administrador ativo**, nem a própria conta.

No frontend, `AppShell` redireciona quem não está logado e, com `apenasAdmin`, quem não é administrador. Isso é só conforto visual: **a segurança real está no backend**.

## Frontend

- **Tema:** as cores ficam em variáveis CSS em `globals.css`. `:root` é o modo claro e `:root[data-theme="dark"]` o escuro. `ThemeToggle` troca o atributo `data-theme` do `<html>` e salva em `localStorage("tema")`; um script em `layout.jsx` aplica o tema antes de a página aparecer. **Ao criar estilos, use as variáveis** (`var(--text)`, `var(--surface)`...), nunca cores fixas, para funcionar nos dois modos.
- **Logo:** `public/logo.png`. No modo escuro ela recebe `filter: invert(1)` (`--logo-filter`).
- **Telas internas:** envolva a página em `<AppShell>`; dentro, `useUsuario()` devolve o usuário logado.
- **Componentes de UI prontos** (`globals.css`): `.btn`, `.btn-outline`, `.btn-perigo`, `.btn-sm`, `.campo`, `.tabela`, `.badge` (`vencido`/`proximo`/`ok`/`neutro`/`admin`), `.modal`, `.form-grid`, `.rotulo`, `.aviso`.
- **Next.js:** `next.config.mjs` usa `cacheComponents`, que mantém a tela anterior oculta para voltar mais rápido. Em testes automatizados, selecione elementos visíveis (ex.: `.app-header:visible`).

## Como adicionar uma funcionalidade (exemplo: campo "fornecedor" no produto)

1. **Banco:** adicione a coluna no `CREATE TABLE produtos` de `database.sql` e, em `migrate.js`, um bloco `if (!(await colunaExiste("produtos", "fornecedor"))) await db.query("ALTER TABLE produtos ADD COLUMN ...")` (igual ao usado para `usuarios`).
2. **Model:** inclua o campo no `SELECT_BASE`, no `INSERT` e no `UPDATE` de `produtoModel.js`.
3. **Controller:** valide e normalize o campo em `validar()` de `produtoController.js`.
4. **Relatório:** se precisar, adicione a coluna em `relatorioController.js` (CSV e PDF).
5. **Frontend:** adicione o campo no estado `VAZIO` e no formulário de `ProdutoForm.jsx` e, se quiser, uma coluna em `produtos/page.jsx`.
6. **Teste:** reinicie a API (`npm run dev` já recarrega sozinho) e confira o fluxo nos dois perfis.

Nova rota protegida no backend:

```js
// src/routes/exemploRoutes.js
const router = require("express").Router();
const { autenticar, exigirPerfil } = require("../middlewares/authMiddleware");
const capturar = require("../utils/capturar");

router.get("/", autenticar, capturar(async (req, res) => res.json({ ok: true })));
router.delete("/:id", autenticar, exigirPerfil("admin"), capturar(async (req, res) => res.status(204).end()));

module.exports = router;
// e em server.js: app.use("/api/exemplo", require("./src/routes/exemploRoutes"));
```

## Variáveis de ambiente

**backEnd/.env** (copie de `.env.example`)

| Variável | Padrão | Descrição |
|---|---|---|
| PORT | 3309 | Porta da API |
| FRONTEND_URL | http://localhost:3000 | Origem liberada no CORS |
| DB_HOST / DB_PORT | 127.0.0.1 / 3306 | Endereço do MySQL |
| DB_USER / DB_PASSWORD | root / senai@123 | Credenciais do MySQL |
| DB_NAME | db_valit | Nome do banco |
| JWT_SECRET | (obrigatória) | Chave de assinatura dos tokens |
| DIAS_ALERTA | 7 | Dias para considerar "vence em breve" |

**front_end/.env.local** (copie de `.env.local.example`)

| Variável | Padrão | Descrição |
|---|---|---|
| NEXT_PUBLIC_API_URL | http://localhost:3309/api | Endereço da API usado pelo navegador |

## Comandos

| Comando | Pasta | O que faz |
|---|---|---|
| `npm run dev` | backEnd | API com recarga automática (`node --watch`) |
| `npm start` | backEnd | API sem recarga |
| `npm run db:setup` | backEnd | Cria/atualiza o banco |
| `npm run dev` | front_end | Next.js em modo desenvolvimento |
| `npm run build` / `npm start` | front_end | Build e servidor de produção |

## Roteiro de testes manuais

- [ ] Sem login, abrir `/produtos` volta para o login
- [ ] Login com senha errada mostra "Usuário ou senha inválidos"
- [ ] Funcionário: não vê o menu **Usuários** nem o botão **Excluir**; abrir `/usuarios` volta para Produtos
- [ ] Cadastrar e editar produto; validação de data e quantidade
- [ ] Cartões de resumo filtram a lista; busca e filtros funcionam
- [ ] Exportar CSV abre no Excel com acentos; PDF mostra logo e cores por status
- [ ] Administrador: excluir produto; criar, editar, desativar e excluir usuário
- [ ] Usuário desativado não consegue entrar
- [ ] Modo escuro continua ativo após recarregar a página

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| "Não foi possível conectar ao servidor" na tela | API desligada ou `.env.local` faltando | Rode `npm run dev` no `backEnd` e confira o `front_end/.env.local` |
| "Banco indisponível (tentativa N)" no terminal da API | MySQL desligado ou senha errada | Ligue o MySQL e confira `DB_USER` / `DB_PASSWORD` no `backEnd/.env` |
| `JWT_SECRET não definido` | Falta o `backEnd/.env` | `copy .env.example .env` |
| Porta 3000 ou 3309 em uso | Outro programa na porta | Feche o programa ou troque `PORT` (API) / use `npm run dev -- -p 3001` (site) e ajuste `FRONTEND_URL` / `NEXT_PUBLIC_API_URL` |

## Como contribuir

1. Atualize: `git pull`
2. Crie um branch: `git checkout -b feature/nome-da-funcionalidade`
3. Faça commits pequenos e descritivos, em português (ex.: `adiciona filtro por lote`)
4. Teste com o roteiro acima
5. `git push -u origin feature/nome-da-funcionalidade` e abra um Pull Request para `main`

Nunca suba `.env`, `.env.local` ou `node_modules` (já estão no `.gitignore`).
