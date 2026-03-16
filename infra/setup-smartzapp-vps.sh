#!/bin/bash
# ============================================================
# SmartZapp — Setup no VPS bilinski.cloud
# Configura container Next.js + reverse proxy no Easypanel
# ============================================================

set -euo pipefail

echo "=== SmartZapp VPS Setup ==="

# 1. Criar diretorio no VPS
echo "1/5 Criando diretorio..."
mkdir -p /opt/smartzapp

# 2. Parar container existente (se houver)
echo "2/5 Parando container existente..."
docker stop smartzapp-app 2>/dev/null || true
docker rm smartzapp-app 2>/dev/null || true

# 3. Build da imagem
echo "3/5 Buildando imagem Docker..."
cd /opt/smartzapp
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL="${NEXT_PUBLIC_SUPABASE_URL}" \
  --build-arg NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="${NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY}" \
  -t smartzapp:latest \
  -f infra/Dockerfile .

# 4. Rodar container
echo "4/5 Iniciando container..."
docker run -d \
  --name smartzapp-app \
  --restart always \
  -p 3090:3000 \
  --env-file .env.production \
  smartzapp:latest

# 5. Verificar
echo "5/5 Verificando..."
sleep 5
if curl -sf http://localhost:3090/api/health > /dev/null; then
  echo "✅ SmartZapp rodando em localhost:3090"
  echo ""
  echo "Proximo passo: Configurar reverse proxy no Easypanel"
  echo "  Dominio: smartzapp.bilinski.cloud"
  echo "  Target:  localhost:3090"
  echo "  SSL:     Auto (Let's Encrypt)"
else
  echo "❌ Falha — checar logs: docker logs smartzapp-app"
  exit 1
fi
