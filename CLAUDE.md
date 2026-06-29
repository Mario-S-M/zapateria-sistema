# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

POS system for "Zapatería La Prodigiosa" (shoe store). Two sub-projects:

- `zapateria-backend/` — NestJS 11 REST API with TypeORM + PostgreSQL
- `zapateria_flutter/` — Flutter app targeting Android, iOS, and web

## Commands

### Full stack (Docker)

```bash
# Start everything (from repo root)
docker compose up -d --build

# On Linux/Raspberry Pi, set the LAN IP so the phone can reach the backend:
EXPO_PUBLIC_API_URL=http://<LAN_IP>:3000 docker compose up -d --build
```

Services: `postgres` on 5432, `backend` on 3000, `web` (Flutter web via nginx) on 8090.

### Backend (NestJS)

```bash
cd zapateria-backend
npm run start:dev      # watch mode
npm run build          # compile to dist/
npm run lint           # eslint --fix
npm run test           # jest unit tests
npm run test:e2e       # e2e tests
```

### Flutter

```bash
cd zapateria_flutter
flutter run                  # mobile (Android/iOS)
flutter run -d chrome        # web
flutter build apk            # release APK
flutter build web            # release web build
```

## Architecture

### Backend

Standard NestJS feature-module layout. Each domain has its own folder with `module / controller / service`:

- `zapato/` — shoe catalog CRUD; handles multi-image upload references and price ranges
- `inventario/` — stock per (zapato, color, talla); separate from zapato for fine-grained control
- `venta/` — sales + items; `create` decrements inventory and computes `total` server-side
- `inversionista/` — consignment partners (investors); each zapato and venta can be tied to one
- `categoria/` — shoe categories
- `color/` — colors (solid or combo with `primaryColor`/`secondaryColor`)
- `upload/` — Multer file upload, saves to `uploads/zapatos/`; static assets served at `/uploads/`

**Database**: TypeORM with `synchronize: true` — schema auto-migrates on startup. No migration files.

**Env vars** (see `.env.example`): `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`.

### Flutter

**State management**: Provider. Two providers registered at root:
- `CartProvider` — cart items, `TipoPrecio`, `MetodoPago`, `montoTarjeta`
- `ThemeProvider` — light/dark mode

**Navigation**: `MainShell` uses `IndexedStack` — `BottomNavigationBar` on mobile, `NavigationRail` on web. Screens (indices 0–6): Zapatos, Ventas, Carrito, Escanear, Cierre, Inversionistas, Categorías.

**HTTP**: `ApiClient` (singleton `apiClient`) wraps Dio. Base URL:
- Web: `/api` (nginx proxy in Docker)
- Mobile: `http://192.168.0.102:3000` default — change in `lib/services/api_client.dart` or pass `--dart-define=API_URL=<url>` at build time

**Services** (`lib/services/`): one service file per backend resource, plus `TicketPrintService` (Bluetooth ESC/POS printing via `bluetooth_print` package).

**Models** (`lib/models/models.dart`): all domain models in one file with `fromJson`/`toJson`. Key enums: `Horma` (NORMAL/REDUCIDO/AMPLIO), `TipoPrecio` (publico/mayorista/inversionista), `MetodoPago` (efectivo/tarjeta/mixto).

### Key domain concepts

- **PrecioRango**: a zapato can have price ranges by size range (`medidaInicio`–`medidaFin`). `ZapatoModel.getPrecioPublicoForTalla(talla)` resolves the correct price; falls back to flat `precioPublico`.
- **Inventario**: stock tracked per `(zapatoId, colorId, talla)` tuple.
- **Inversionista**: consignment partner. Each inversionista can have a card terminal (`tieneTerminal`). The `CierreCaja` screen breaks down daily sales by inversionista to show how much cash is owed to each.
- **CartItem key**: `'${zapatoId}-${colorId}-${talla}'` — same shoe with different color or size is a separate line.
- **Folio**: sale invoice number, also printed as barcode on the ESC/POS ticket.

### Business config

Static constants in `lib/config/business_config.dart`: business name, RFC, address, and warranty policy text printed on every ticket. Edit here to change receipt header/footer.
