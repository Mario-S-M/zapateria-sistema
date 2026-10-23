# zapateria-sistema

## Levantar todo con Docker

Con Docker Desktop encendido, ejecuta desde la raíz del proyecto:

```bash
docker compose up -d --build
```

Esto levanta:

- `postgres` (base de datos, puerto 5432)
- `backend` (NestJS en `http://localhost:3000`)
- `web` (build web de Flutter servido por nginx en `http://localhost:8090`,
  con `/api` proxeado internamente al backend — no necesita configuración
  adicional de IP)

## Abrir la app web

Abre `http://localhost:8090` en el navegador. Para acceder desde otro
dispositivo en la misma red (ej. un teléfono), usa la IP LAN de la máquina
que corre Docker en vez de `localhost`, con el mismo puerto 8090 — no hace
falta ninguna variable de entorno adicional, nginx ya resuelve `/api` contra
el backend dentro de la red de Docker.

## App móvil (Android/iOS)

El uso diario en tienda es la app nativa, no el build web. No corre dentro
de Docker — se ejecuta con `flutter run` desde `zapateria_flutter/`. Ver
`CLAUDE.md` (sección Flutter) para los comandos y cómo apuntar la app a la
IP del backend en tu red.

## Asesor de ventas (agente de ElevenLabs)

Spec: `specs/01-asesor-de-ventas-elevenlabs.md`. El agente consulta el inventario
a través del servidor MCP del backend (`POST /mcp`), que ElevenLabs llama desde
su nube. Para eso necesita una URL HTTPS pública.

El backend **no tiene autenticación** en el resto de la API, así que el túnel
nunca apunta al backend directo: apunta a `mcp_gateway` (nginx), que solo
reenvía `POST /mcp` y responde 404 a todo lo demás. `/mcp` además exige el
header `X-MCP-Secret` (`MCP_SHARED_SECRET`).

### Variables (archivo `.env` en la raíz, lo lee `docker compose`)

- `ELEVENLABS_API_KEY`, `ELEVENLABS_AGENT_ID`: credenciales del agente.
- `MCP_SHARED_SECRET`: secreto compartido con ElevenLabs para `/mcp`
  (ej. `openssl rand -hex 32`).
- `CLOUDFLARE_TUNNEL_TOKEN`: token del túnel (solo con el profile `tunel`).

### Configurar el túnel de Cloudflare

1. Cloudflare Zero Trust → Networks → Tunnels → crear un túnel de tipo
   *Cloudflared* y copiar su token a `CLOUDFLARE_TUNNEL_TOKEN`.
2. En *Public Hostname* del túnel: hostname `mcp.<tu-dominio>`, servicio
   `HTTP` → `mcp_gateway:80`.
3. Levantar con el profile del túnel:

   ```bash
   docker compose --profile tunel up -d --build
   ```

4. Verificar: sin secreto debe responder 401, y cualquier otra ruta 404.

   ```bash
   curl -i -X POST https://mcp.<tu-dominio>/mcp
   curl -i https://mcp.<tu-dominio>/ventas
   ```

Túnel actual: `zapateria-mcp` (Cloudflare), hostname
`zapateria-mcp.aragorn-system.com`, ruta `^/mcp$` → `http://mcp_gateway:80`.
Es independiente del túnel `zapateria` que ya existía. El token vive solo en
`.env` (`CLOUDFLARE_TUNNEL_TOKEN`); el conector corre en la máquina donde se
levante el profile, así que en producción hay que levantarlo en la Raspberry.

Sin `--profile tunel` el stack arranca igual que antes, sin túnel.
