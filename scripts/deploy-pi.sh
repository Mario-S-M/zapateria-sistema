#!/usr/bin/env bash
# Build en la Mac (linux/arm64) y despliegue a la Raspberry sin compilar allá.
#
#   ./scripts/deploy-pi.sh            # build + respaldo de BD + deploy
#   ./scripts/deploy-pi.sh --build    # solo build local (no toca la Pi)
#
# Requiere: Docker Desktop encendido, Flutter, acceso SSH a la Pi.
set -euo pipefail

PI="${PI:-rasp@raspberrypi.local}"
PI_DIR="${PI_DIR:-zapateria-sistema}"      # relativo al home en la Pi (tiene el .env con DB_PASSWORD)
PROJECT="${PROJECT:-zapateria-deploy}"     # mismo proyecto compose que usa Jenkins → conserva volúmenes
PLATFORM="linux/arm64"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ Flutter web (build nativo, es independiente de la arquitectura)"
(cd zapateria_flutter && flutter build web --release)

echo "▶ Imagen backend ($PLATFORM)"
docker buildx build --platform "$PLATFORM" --load \
  -t "${PROJECT}-backend" zapateria-backend

echo "▶ Imagen web ($PLATFORM)"
docker buildx build --platform "$PLATFORM" --load \
  -t "${PROJECT}-web" -f - zapateria_flutter <<'EOF'
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EOF

if [[ "${1:-}" == "--build" ]]; then
  echo "✔ Build local listo (sin desplegar)"
  exit 0
fi

echo "▶ Respaldo de la BD en la Pi"
ssh "$PI" 'mkdir -p ~/respaldos && docker exec zapateria_postgres pg_dump -U postgres zapateria | gzip > ~/respaldos/zapateria-$(date +%Y%m%d-%H%M%S).sql.gz && ls -t ~/respaldos | head -1'

echo "▶ Enviando imágenes a la Pi"
docker save "${PROJECT}-backend" "${PROJECT}-web" | gzip | ssh "$PI" 'gunzip | docker load'

echo "▶ Reiniciando servicios (sin build en la Pi)"
ssh "$PI" "cd ~/$PI_DIR && docker compose -p $PROJECT up -d --no-build --force-recreate backend web && sleep 10 && docker compose -p $PROJECT ps && docker compose -p $PROJECT logs --tail=15 backend"

echo "✔ Deploy completo"
