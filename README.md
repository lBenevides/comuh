# Comuh

Plataforma de comunidades construída em Ruby on Rails com API REST e interface web server-rendered. O projeto permite listar comunidades, publicar mensagens, responder em threads, reagir sem recarregar a página e consultar endpoints analíticos, incluindo ranking de mensagens por engajamento e detecção de IPs suspeitos.

## Visão geral

- Backend em Ruby on Rails 8
- Frontend com Haml + Hotwire (`Turbo` + `Stimulus`)
- PostgreSQL como banco de dados
- Action Cable com `solid_cable`
- Testes com RSpec
- CI no GitHub Actions
- Deploy em produção no Railway

## Funcionalidades principais

- Listagem de comunidades
- Timeline de mensagens por comunidade
- Criação de mensagens e respostas sem reload
- Reações sem reload
- Thread de comentários
- Score simples de sentimento em novas mensagens
- API REST em `/api/v1`
- Endpoint de top mensagens por engajamento
- Endpoint de analytics para IPs suspeitos

## Requisitos

- Ruby `3.4.4`
- Bundler
- PostgreSQL 16+ em execução local
- Node não é obrigatório para rodar a aplicação atual, já que o projeto usa importmap

## Setup local

1. Instale as dependências:

```bash
bundle install
```

2. Copie as variáveis de ambiente:

```bash
cp .env.example .env
```

3. Ajuste os valores de banco no seu shell ou carregue o `.env`.

4. Prepare o banco:

```bash
bin/rails db:prepare
```

5. Inicie a aplicação:

```bash
bin/dev
```

Se preferir automatizar o setup inicial:

```bash
bin/setup
```

Aplicação local:

- Web: `http://localhost:3000`
- Healthcheck: `http://localhost:3000/up`

## Variáveis de ambiente

As variáveis mais importantes estão documentadas em [`.env.example`](/home/bene/projects/comuh/.env.example).

Principais variáveis:

- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`
- `DB_NAME`, `CABLE_DB_NAME`
- `TEST_DB_NAME`, `TEST_CABLE_DB_NAME`
- `RAILS_MAX_THREADS`
- `DATABASE_URL`, `CABLE_DATABASE_URL` para produção
- `APP_HOST`, `FORCE_SSL`, `RAILS_LOG_LEVEL`
- `SEED_BASE_URL` para popular um ambiente remoto via API

## Banco de dados

O projeto usa PostgreSQL com configuração multi-db para `primary` e `cable`.

Comandos úteis:

```bash
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:schema:load:cable
```

## Seeds

O seed popula o projeto com dados próximos do escopo do teste:

- 5 comunidades
- 50 usuários
- 1000 mensagens
- cerca de 70% posts principais e 30% replies
- 20 IPs únicos
- cerca de 80% das mensagens com ao menos uma reação

Rodar localmente:

```bash
bin/rails db:seed
```

Rodar em um ambiente remoto via API:

```bash
SEED_BASE_URL=https://comuh-production.up.railway.app bin/rails db:seed
```

Variáveis opcionais para personalizar volume:

- `SEED_RESET`
- `SEED_COMMUNITIES`
- `SEED_USERS`
- `SEED_ROOT_MESSAGES`
- `SEED_REPLY_MESSAGES`
- `SEED_REACTION_RATIO`

## Testes e qualidade

Rodar a suíte principal:

```bash
bundle exec rspec
```

Rodar o pipeline local de qualidade:

```bash
bin/ci
```

Ferramentas configuradas:

- RSpec
- SimpleCov
- RuboCop
- Brakeman
- bundler-audit

Cobertura do relatório local atual em [`coverage/index.html`](/home/bene/projects/comuh/coverage/index.html): `73.12%` (`204/279` linhas relevantes cobertas).

## Endpoints da API

### Criar mensagem

`POST /api/v1/messages`

Payload esperado:

```json
{
  "username": "alice",
  "community_id": 1,
  "content": "Nova mensagem na comunidade",
  "user_ip": "127.0.0.1",
  "parent_message_id": 42
}
```

`parent_message_id` é opcional e permite criar replies.

### Criar reação

`POST /api/v1/reactions`

Payload esperado:

```json
{
  "message_id": 42,
  "username": "alice",
  "reaction_type": "like"
}
```

Tipos suportados:

- `like`
- `love`
- `insightful`

### Top mensagens por comunidade

`GET /api/v1/communities/:id/messages/top?limit=10`

### IPs suspeitos

`GET /api/v1/analytics/suspicious_ips?min_users=3`

## Frontend

Rotas principais:

- `/` ou `/communities`
- `/communities/:id`
- `/messages/:id`

A interface é server-rendered com Haml e enriquecida com Turbo/Stimulus para interações sem reload.

## Capturas de tela

### Home de comunidades

Tela inicial com listagem de comunidades, contagem de mensagens e acesso direto para a timeline de cada comunidade.

### Timeline de comunidade

Tela da comunidade com composição de nova thread, listagem de mensagens, indicadores de sentimento e reações sem reload.

## Deploy

- Produção: `https://comuh-production.up.railway.app/`
- Plataforma: Railway
- Banco: PostgreSQL gerenciado no Railway
- CI: GitHub Actions em [`.github/workflows/ci.yml`](/home/bene/projects/comuh/.github/workflows/ci.yml)

## Decisões técnicas

- Rails 8 com renderização no servidor para manter a aplicação simples de operar e rápida de entregar
- Hotwire para interatividade sem introduzir uma SPA separada
- PostgreSQL como banco principal, alinhado ao escopo do projeto
- `solid_cable` para WebSocket persistido em banco
- Estratégia simples de análise de sentimento por palavras-chave, suficiente para o escopo do teste

## ✅ Checklist de Entrega - Lucas Benevides

### Repositório & Código

- [x] Código no GitHub (público): https://github.com/lBenevides/comuh
- [x] README com instruções completas
- [x] `.env.example` ou similar com variáveis de ambiente
- [x] Linter/formatter configurado
- [x] Código limpo e organizado

### Stack Utilizada

- [x] Backend: Ruby on Rails 8
- [x] Frontend: Haml + Hotwire (`Turbo` + `Stimulus`)
- [x] Banco de dados: PostgreSQL
- [x] Testes: RSpec

### Deploy

- [x] URL da aplicação: https://comuh-production.up.railway.app/
- [x] Seeds executados (dados de exemplo visíveis)

### Funcionalidades - API

- [x] POST `/api/v1/messages` (criar mensagem + sentiment)
- [x] POST `/api/v1/reactions` (com proteção de concorrência)
- [x] GET `/api/v1/communities/:id/messages/top`
- [x] GET `/api/v1/analytics/suspicious_ips`
- [x] Tratamento de erros apropriado
- [x] Validações implementadas

### Funcionalidades - Frontend

- [x] Listagem de comunidades
- [x] Timeline de mensagens
- [x] Criar mensagem (sem reload)
- [x] Reagir a mensagens (sem reload)
- [x] Ver thread de comentários
- [x] Responsivo (mobile + desktop)

### Testes

- [x] Cobertura mínima de 70% (cobertura atual: 73.12%)
- [x] Testes passando
- [x] Como rodar: `bundle exec rspec`

### Documentação

- [x] Setup local documentado
- [x] Decisões técnicas explicadas
- [x] Como rodar seeds
- [x] Endpoints da API documentados
