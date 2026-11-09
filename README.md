# Valit

Sistema web para **controle de validade de produtos** em pequenas e médias empresas.
Projeto PSOF · 3MD · Manhã.

- **backEnd/** – API em Node.js + Express + MySQL (porta **3309**)
- **front_end/** – Next.js (porta **3000**)

## Funcionalidades

1. **Login do funcionário** com dois níveis de acesso (Administrador e Funcionário)
2. **Cadastro de produtos** com nome, categoria, lote, quantidade, data de validade e observação
3. **Listagem de produtos** ordenada pelo vencimento, com status (Vencido / Vence em breve / Dentro da validade), resumo, busca e filtros
4. **Exportação de relatórios** em **PDF** ou **CSV** (Excel), respeitando os filtros da tela
5. **Gestão de usuários** (só administrador): criar funcionários, mudar nível de acesso, desativar, redefinir senha
6. **Modo claro / modo escuro** (preto e branco), com a escolha salva no navegador

## Logins de teste

| Nível | E-mail | Senha |
|---|---|---|
| Administrador | admin@valit.com | admin123 |
| Funcionário | teste@email.com | 123456 |

## Níveis de acesso

| Ação | Funcionário | Administrador |
|---|:---:|:---:|
| Entrar no sistema | ✓ | ✓ |
| Ver e filtrar produtos | ✓ | ✓ |
| Cadastrar e editar produtos | ✓ | ✓ |
| Exportar PDF / CSV | ✓ | ✓ |
| Excluir produtos | — | ✓ |
| Gerenciar usuários | — | ✓ |

## Rodando com Docker (recomendado) – Windows

| Arquivo | Quando usar |
|---|---|
| **`configurar.bat`** | Primeira vez **e sempre que o código for atualizado**. Abre o Docker se precisar, escolhe portas livres, reconstrói tudo, testa o login e abre o site. Se algo falhar, gera `diagnostico.txt`. |
| **`rodar.bat`** | Dia a dia: liga o sistema e abre o navegador. |
| **`parar.bat`** | Desliga o sistema (os dados do banco são mantidos). |

Para apagar o banco e recomeçar do zero: `configurar.bat -Resetar`.

Manualmente, com o Docker Desktop aberto, na pasta do projeto: `docker compose up -d --build`.

| Serviço | Endereço |
|---|---|
| Site | http://localhost:3000 |
| API | http://localhost:3309/api/health |
| MySQL (Workbench) | 127.0.0.1, porta mostrada no fim do `configurar.bat` (padrão 3307), root / senai@123 |

## Sem Docker – Windows

Com Node.js 20+ e MySQL rodando na porta 3306: dois cliques em **`sem-docker-instalar.bat`**. Nas próximas vezes, **`sem-docker-rodar.bat`**.

Passo a passo manual:

```bash
cd backEnd
npm install
copy .env.example .env      # ajuste DB_USER / DB_PASSWORD se precisar
npm run db:setup            # cria banco, tabelas, logins de teste e produtos de exemplo
npm run dev

# em outro terminal
cd front_end
npm install
copy .env.local.example .env.local
npm run dev
```

## Regra de validade

`dias restantes = data de validade − hoje`

| Status | Regra |
|---|---|
| Vencido | dias restantes < 0 |
| Vence em breve | 0 a 7 dias (ajustável em `DIAS_ALERTA`) |
| Dentro da validade | mais de 7 dias |

## Rotas da API

Todas, menos login e health, exigem o header `Authorization: Bearer <token>`.

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| GET | /api/health | público | API no ar |
| POST | /api/auth/login | público | `{ usuario, senha }` → `{ token, usuario }` |
| GET | /api/auth/me | logado | Dados do usuário logado |
| GET | /api/produtos | logado | Lista (filtros: `busca`, `status`, `categoria`) |
| GET | /api/produtos/resumo | logado | Totais por status |
| GET | /api/produtos/categorias | logado | Categorias usadas |
| GET | /api/produtos/:id | logado | Um produto |
| POST | /api/produtos | logado | Cadastrar |
| PUT | /api/produtos/:id | logado | Editar |
| DELETE | /api/produtos/:id | admin | Excluir |
| GET | /api/relatorios/produtos?formato=pdf\|csv | logado | Exportar relatório |
| GET | /api/usuarios | admin | Listar usuários |
| POST | /api/usuarios | admin | Criar usuário |
| PUT | /api/usuarios/:id | admin | Editar nome, nível, situação ou senha |
| DELETE | /api/usuarios/:id | admin | Excluir usuário |

## Páginas

- `/` – Login
- `/produtos` – Produtos (resumo, filtros, cadastro, edição, exportação)
- `/usuarios` – Usuários (só administrador)
