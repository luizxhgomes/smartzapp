# SmartZapp — Guia de Deploy no VPS bilinski.cloud

## Arquitetura no VPS

```
VPS 76.13.171.91 (Easypanel)
├── brabissimo-app (nginx:alpine)  → porta 3080 → brabissimo.bilinski.cloud
├── smartzapp-app  (node:20-alpine) → porta 3090 → smartzapp.bilinski.cloud
├── supabase       (postgres)       → porta 5432
├── supabase-studio                 → porta 3000 → supabase.bilinski.cloud
└── supabase-api   (postgrest)      → porta 8000 → api.bilinski.cloud
```

## Passo 1: Configurar DNS

No painel do provedor de dominio (onde gerencia bilinski.cloud), adicione:

```
Tipo: A
Nome: smartzapp
Valor: 76.13.171.91
TTL: 300
```

Isso cria o subdominio `smartzapp.bilinski.cloud` apontando para o VPS.

## Passo 2: Configurar Easypanel

No Easypanel do VPS, crie um novo servico:

1. **Nome**: smartzapp
2. **Tipo**: Custom (reverse proxy)
3. **Dominio**: `smartzapp.bilinski.cloud`
4. **Target**: `http://localhost:3090`
5. **SSL**: Ativar (Let's Encrypt automatico)
6. **WebSocket**: Ativar (necessario para Supabase Realtime)

## Passo 3: Configurar Secrets no GitHub

No repositorio do SmartZapp no GitHub, va em Settings → Secrets → Actions e adicione:

| Secret | Valor |
|--------|-------|
| `VPS_HOST` | 76.13.171.91 |
| `VPS_SSH_KEY` | (mesma chave SSH do brabissimo) |
| `SMARTZAPP_SUPABASE_URL` | https://ikyqbcnqrpvbcaovystr.supabase.co |
| `SMARTZAPP_SUPABASE_PUBLISHABLE_KEY` | (anon key JWT) |
| `SMARTZAPP_SUPABASE_SECRET_KEY` | (service role key JWT) |
| `SMARTZAPP_MASTER_PASSWORD` | (senha do dashboard) |
| `SMARTZAPP_API_KEY` | (API key) |
| `SMARTZAPP_ADMIN_KEY` | (admin key) |
| `SMARTZAPP_QSTASH_TOKEN` | (token Upstash) |
| `SMARTZAPP_OPENROUTER_API_KEY` | (OpenRouter key) |
| `SMARTZAPP_MEM0_API_KEY` | (Mem0 key) |
| `SMARTZAPP_N8N_API_KEY` | (N8N key) |

## Passo 4: Primeiro Deploy

Opcao A — Via GitHub Actions (automatico):
```bash
git push origin main
```

Opcao B — Manual no VPS:
```bash
# SSH no VPS
ssh root@76.13.171.91

# Clonar e buildar
cd /opt
git clone https://github.com/luizxhgomes/smartzapp.git smartzapp-repo
cd smartzapp-repo
npm ci && npm run build

# Copiar standalone
mkdir -p /opt/smartzapp/app
cp -r .next/standalone/* /opt/smartzapp/app/
cp -r .next/static /opt/smartzapp/app/.next/static
cp -r public /opt/smartzapp/app/public

# Rodar container
docker run -d \
  --name smartzapp-app \
  --restart always \
  -p 3090:3000 \
  --env-file /opt/smartzapp/.env.production \
  -v /opt/smartzapp/app:/app:ro \
  -w /app \
  node:20-alpine \
  node server.js
```

## Passo 5: Verificar

```bash
# No VPS
curl -sf http://localhost:3090/api/health

# No browser
https://smartzapp.bilinski.cloud
```

## Troubleshooting

### Container nao inicia
```bash
docker logs smartzapp-app
```

### Porta 3090 em uso
```bash
lsof -i :3090
docker ps -a | grep 3090
```

### SSL nao funciona
- Verificar DNS propagou: `dig smartzapp.bilinski.cloud`
- Verificar Easypanel: certificado Let's Encrypt pode levar 1-2 min
