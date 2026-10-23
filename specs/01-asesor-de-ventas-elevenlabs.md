# SPEC 01 — Asesor de ventas con agente de ElevenLabs

> **Status:** Aprobado
> **Depends on:** Ninguno
> **Date:** 2026-10-22
> **Objective:** Conectar un agente de ElevenLabs a la app (web y móvil) para que guíe al vendedor con preguntas cortas al cliente y abra una pantalla con recomendaciones basadas en el inventario real de la talla pedida.

---

## Por qué existe este spec

Hoy el vendedor decide de memoria qué ofrecer. El cliente rara vez sabe decir "categoría" (¿para escuela, para baño?), pero sí sabe su talla y suele tener preferencia de color. El agente conoce qué calzado existe en cada talla (en talla 23 puede ser tenis, sandalia o Croc) y va descartando con preguntas concretas hasta recomendar.

Dos reglas guían el diseño:

- El agente **nunca inventa zapatos**: el inventario sale del backend; el agente solo conversa y ordena.
- La llave de ElevenLabs **nunca llega a la app**: la sesión se abre con un token que genera el backend.

---

## Scope

**In:**

- Servidor MCP dentro del backend NestJS (`POST /mcp`, transporte HTTP streamable) que expone al agente herramientas de solo lectura sobre inventario, categorías y colores.
- Endpoint `POST /agente/sesion` que devuelve credenciales efímeras de ElevenLabs según la plataforma (móvil: token de conversación; web: signed URL).
- Endpoint `GET /agente/inventario?talla=` que devuelve todo el stock de una talla (`cantidad > 0`) agrupado por zapato y color.
- Pantalla de chat "Asesor" (nuevo índice 8 de `MainShell`) con voz y texto tanto en móvil como en web.
- Client tool `mostrar_recomendaciones` que el agente invoca para abrir la pantalla de recomendaciones, más un botón manual "Ver recomendaciones".
- Pantalla de recomendaciones **solo de la talla pedida** (y de la categoría, si el cliente la mencionó, ej. "23 escolar"): zapatos recomendados primero, luego el resto del stock de esa talla (y categoría); nunca se muestran otras tallas. Cada tarjeta con foto, precio público (resuelto por rango de talla) y botón "Agregar al carrito", que agrega siempre en la talla pedida.
- Prompt del agente versionado en el repo como fuente de verdad.
- Exposición del backend con Cloudflare Tunnel (URL HTTPS fija) protegida con secreto compartido.

**Out of scope (para otros specs):**

- Recomendaciones de reabasto ("qué comprar para surtir inventario").
- Una línea de "motivo" por zapato en las tarjetas.
- Que el cliente use el agente directo (modo kiosco).
- Historial o analítica de conversaciones; guardar transcripciones en la base de datos.
- Herramientas de escritura del agente (crear ventas, mover inventario).
- Aprendizaje a partir de ventas pasadas.

---

## Data model

No se agregan tablas. `synchronize: true` no tiene nada que migrar.

Contratos nuevos (JSON):

```ts
// GET /agente/inventario?talla=23&categoriaId=<opcional>
type InventarioTallaResponse = {
  talla: number;
  items: Array<{
    zapatoId: string;
    nombre: string;
    modelo: string;
    foto: string;
    categoriaId: string | null;
    categoria: string | null;
    precioPublico: number;         // ya resuelto para la talla (PrecioRango o plano)
    variantes: Array<{ colorId: string | null; color: string | null; cantidad: number }>;
  }>;
};

// POST /agente/sesion  body: { plataforma: 'web' | 'movil' }
type SesionResponse =
  | { plataforma: 'movil'; conversationToken: string }
  | { plataforma: 'web'; conversationToken: string; signedUrl: string }; // token: voz (WebRTC); signedUrl: texto (WebSocket)

// Client tool "mostrar_recomendaciones" (la invoca el agente en la app)
type MostrarRecomendacionesParams = {
  talla: number;
  zapato_ids: string;     // ids separados por comas, orden de preferencia (ElevenLabs no admite arreglos)
  categoria_id?: string;  // solo si el cliente la dijo (ej. escolar)
  color_id?: string;
};
```

Herramientas MCP (solo lectura), todas devuelven solo filas con `cantidad > 0`:

| Tool                        | Parámetros                          | Devuelve                                           |
| --------------------------- | ----------------------------------- | -------------------------------------------------- |
| `buscar_inventario_por_talla` | `talla`, `colorId?`, `categoriaId?` | Mismo `items` que `/agente/inventario`.            |
| `listar_categorias`         | —                                   | `{ id, nombre }[]`                                 |
| `listar_colores`            | —                                   | `{ id, nombre }[]` (sólidos y combinados)          |

Variables de entorno nuevas (`.env.example`): `ELEVENLABS_API_KEY`, `ELEVENLABS_AGENT_ID`, `MCP_SHARED_SECRET`.

Convenciones:

- `talla` usa la misma escala decimal que `inventario.talla` (ej. `23`, `23.5`).
- Las tarjetas no tienen selector de talla: la talla viene de la conversación y es fija en la pantalla.
- Si hay `categoriaId`, la pantalla muestra un chip "Escolar ✕"; al quitarlo se ve todo el stock de esa talla.
- La app descarta de `zapatoIdsRecomendados` cualquier id que no esté en la respuesta de `/agente/inventario`.

---

## Implementation plan

1. **Spike de validación.** Anotar en la sección Decisiones de este spec lo verificado contra la documentación de ElevenLabs: si el SDK `elevenlabs_agents` funciona en iOS/Android con token de conversación, y qué opción da voz en web (SDK JS `@elevenlabs/client` cargado en `web/index.html` con `dart:js_interop`, o WebSocket con audio manual). Prueba: sesión de voz y de texto mínimas contra el agente de prueba, en un navegador y en un Android.
2. **Backend: módulo `agente/` con inventario por talla.** Crear `zapateria-backend/src/agente/{agente.module,agente.service,agente.controller}.ts` y `GET /agente/inventario`. Prueba: `curl` con talla 23 devuelve solo stock > 0 y precio resuelto por rango.
3. **Backend: sesión.** `POST /agente/sesion` llama a ElevenLabs con `ELEVENLABS_API_KEY` y devuelve token o signed URL según `plataforma`. Prueba: `curl` devuelve credencial; sin llave configurada responde 503 con mensaje claro.
4. **Backend: servidor MCP.** Agregar `@modelcontextprotocol/sdk`, `agente/mcp.controller.ts` en `POST /mcp` con las tres tools y guard por header `X-MCP-Secret`. Prueba: MCP Inspector lista las tools; sin secreto responde 401.
5. **Infra: túnel.** Servicio `cloudflared` en `docker-compose.yml` hacia `backend:3000`, documentado en el README. Prueba: la URL pública responde 401 en `/mcp` sin secreto.
6. **Agente en ElevenLabs.** Escribir `zapateria-backend/src/agente/agent-prompt.md`, crear el agente, registrar el servidor MCP (secreto como workspace secret) y el client tool `mostrar_recomendaciones`. Prueba: en el probador del dashboard, "Hola, necesito un calzado para niños" produce una pregunta de talla.
7. **Flutter: modelos y servicio.** Agregar `InventarioTallaModel` en `lib/models/models.dart` y `lib/services/agente_service.dart` (sesión + inventario por talla). Prueba: llamada desde un test de widget o `flutter run` imprime los items.
8. **Flutter: pantalla de recomendaciones.** `lib/screens/recomendaciones_screen.dart` recibiendo talla, color y ids; tarjetas con foto, precio y "Agregar al carrito" (`CartProvider.addItem`). Prueba: abrir con parámetros fijos y agregar al carrito.
9. **Flutter: cliente web con voz y texto.** `lib/services/agente_client.dart` (interfaz), `agente_client_web.dart` (opción validada en el spike, con signed URL) y `agente_client_stub.dart` con import condicional, igual que `web_print_service`. Prueba: `flutter run -d chrome`, el agente responde por texto y por voz con permiso de micrófono.
10. **Flutter: cliente móvil con SDK.** Agregar `elevenlabs_agents` a `pubspec.yaml`, `agente_client_mobile.dart` con voz y texto, permiso de micrófono en `AndroidManifest.xml` e `Info.plist`. Prueba: conversación hablada en un Android.
11. **Flutter: pantalla Asesor y navegación.** `lib/screens/asesor_screen.dart`, entrada "Asesor" en `MainShell` (índice 8), registro del client tool para abrir `RecomendacionesScreen` y botón manual "Ver recomendaciones" (pide la talla si el agente aún no la tiene). Prueba: flujo completo del caso "calzado para niños".

---

## Acceptance criteria

- [ ] `GET /agente/inventario?talla=23` no incluye ninguna variante con `cantidad` 0.
- [ ] `GET /agente/inventario?talla=23` devuelve `precioPublico` igual a `getPrecioPublicoForTalla(23)` del zapato.
- [ ] `POST /mcp` sin header `X-MCP-Secret` o con secreto incorrecto responde 401.
- [ ] `POST /mcp` con secreto correcto lista exactamente `buscar_inventario_por_talla`, `listar_categorias` y `listar_colores`.
- [ ] Ninguna tool MCP modifica filas (no hay `save`, `update` ni `delete` en `mcp.controller.ts`).
- [ ] `POST /agente/sesion` con `plataforma: 'movil'` devuelve `conversationToken`; con `'web'` devuelve `conversationToken` y `signedUrl`.
- [ ] `ELEVENLABS_API_KEY` no aparece en el bundle web (`build/web`) ni en el APK (búsqueda de texto).
- [ ] La URL pública del túnel responde 401 en `/mcp` sin secreto.
- [ ] En web, el vendedor escribe "Hola, necesito un calzado para niños" y recibe respuesta del agente por texto.
- [ ] En web (Chrome), el vendedor habla y el agente responde con voz.
- [ ] En un Android físico, el vendedor habla y el agente responde con voz; el texto también funciona en la misma pantalla.
- [ ] La primera pregunta del agente en ese caso es por la talla; el agente no pregunta "¿qué categoría?" en ningún turno (revisión manual de 3 conversaciones de prueba).
- [ ] Con talla 23 el agente propone opciones concretas que existen en inventario (ej. "tengo tenis, sandalias y crocs en 23") y no menciona tipos sin stock en esa talla.
- [ ] Cuando el agente llama `mostrar_recomendaciones`, la app abre `RecomendacionesScreen` sin acción del vendedor.
- [ ] Un id en `zapatoIdsRecomendados` que no existe en el inventario de esa talla no se muestra.
- [ ] `RecomendacionesScreen` muestra primero los zapatos recomendados y debajo todo el resto del stock de esa talla.
- [ ] Con talla 23 y categoría Escolar, la pantalla no muestra ninguna variante de otra talla ni de otra categoría.
- [ ] "Agregar al carrito" crea la línea con la talla pedida (23), sin posibilidad de cambiarla en la tarjeta.
- [ ] "Agregar al carrito" crea una línea con clave `'${zapatoId}-${colorId}-${talla}'` y no excede la cantidad en stock.
- [ ] El botón "Ver recomendaciones" abre la pantalla en cualquier momento de la conversación.
- [ ] Sin conexión a ElevenLabs, la pantalla Asesor muestra un mensaje de error y el resto de la app sigue funcionando.
- [ ] `npm run build` y `flutter analyze` pasan sin errores.

---

## Decisiones

- **Sí:** el backend NestJS actúa como servidor MCP. Pedido explícito; evita que el agente tenga acceso a otra cosa que no sean estas tools.
- **Sí:** el backend filtra el inventario y el agente solo conversa y ordena. Un zapato sin stock nunca aparece, y la app valida los ids que devuelve el agente.
- **Sí:** el vendedor es quien usa el agente. El cliente no toca el dispositivo.
- **Sí:** "qué agregar" significa qué ofrecer y agregar al carrito del cliente, no reabasto.
- **Sí:** token de conversación o signed URL generados por el backend. La llave de ElevenLabs no sale del servidor.
- **Sí:** SDK `elevenlabs_agents` en móvil y API/WebSocket en web, como se pidió.
- **Sí:** voz y texto también en web (corrección posterior tuya). La opción técnica se decide en el spike (paso 1).
- **Sí:** la pantalla de recomendaciones muestra únicamente la talla pedida (y categoría si el cliente la dijo) y el carrito agrega en esa talla. Corrección posterior tuya; evita ofrecer 22 o 26 cuando piden 23.
- **Sí:** el agente descarta con preguntas concretas basadas en lo que existe en esa talla ("¿cerrado o abierto?", "¿de qué color?"), no preguntando categoría.
- **Sí:** la pantalla muestra todo el stock de la talla debajo de las recomendaciones. Salió de tu petición original ("de preferencia ... todo lo que tenga en inventario en ese número"), aunque no la marcaste en la lista de acciones; quítala si no la quieres.
- **Sí:** Cloudflare Tunnel para exponer `/mcp`. No abre puertos en la red de la tienda y da URL HTTPS fija.
- **Spike (paso 1), resultado de la documentación — 2026-10-22:**
  - `elevenlabs_agents` 0.6.1 (Flutter) usa LiveKit/WebRTC. Plataformas documentadas: Android API 21+ e iOS 13+. pub.dev lo etiqueta también para web, pero no documenta configuración ni limitaciones web.
  - Sesión en el SDK: `agentId` (agente público) o `conversationToken` (agente privado); `signedUrl` no aparece. Soporta `sendUserMessage` (texto) y client tools con `ConversationClient(clientTools: {...})`; el nombre debe coincidir con el configurado en el agente.
  - Permisos móvil: `RECORD_AUDIO`, `INTERNET`, `MODIFY_AUDIO_SETTINGS` (Android); `NSMicrophoneUsageDescription` (iOS).
  - Endpoints del backend: `GET /v1/convai/conversation/token?agent_id=` (WebRTC, voz) y `GET /v1/convai/conversation/get-signed-url?agent_id=` (WebSocket, texto), ambos con `xi-api-key`.
  - SDK JS (`@elevenlabs/client`): `Conversation.startSession({ conversationToken | signedUrl, clientTools })`; voz usa WebRTC, texto usa WebSocket por defecto.
  - **Implicación:** la voz en web también usa `conversationToken` (WebRTC), no `signedUrl`. El contrato `SesionResponse` del Data model (web → `signedUrl`) probablemente deba devolver `conversationToken` para voz y opcionalmente `signedUrl` para texto.
  - **Verificado el 2026-10-22 (paso 6):** una sesión de texto por `signedUrl` (WebSocket) contra el agente real funciona con `conversation_config_override.conversation.text_only = true` (el agente lo permite en `platform_settings.overrides`). El agente pregunta primero la talla, consulta `buscar_inventario_por_talla` por el túnel MCP, no pregunta categoría y dispara el client tool `mostrar_recomendaciones` con ids reales.
  - MCP en ElevenLabs viene desactivado por defecto por workspace y se habilita aceptando los términos al añadir el primer servidor. No requirió plan de pago.
  - **Sigue sin verificar** (se cierra en los pasos 9 y 10): la voz real en Chrome y en Android, y si el SDK de Flutter corre en web. Las sesiones de voz usan `conversationToken`.
- **No:** tools de escritura para el agente. Riesgo de que una conversación mal interpretada modifique stock o ventas.
- **No:** línea de "motivo" por zapato. No se eligió; entra en otro spec si hace falta.
- **No:** guardar transcripciones en la base de datos. Ya quedan en ElevenLabs.
- **No:** reabasto. Es otra funcionalidad con otra fuente de datos (pedidos sin stock).

---

## Riesgos

| Riesgo                                                                                  | Mitigación                                                                                               |
| --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| El backend corre en Raspberry Pi/LAN; si el túnel cae, el agente pierde el inventario.  | El agente no recomienda sin tool: el prompt le indica avisar al vendedor y sugerir "Ver recomendaciones". |
| El agente alucina un zapato o un id.                                                    | La app solo muestra ids presentes en `/agente/inventario`; el resto se descarta.                          |
| `/mcp` expuesto a internet.                                                             | Secreto en header, solo lectura, el secreto se guarda como workspace secret y se rota si se filtra.       |
| El SDK `elevenlabs_agents` no cubre iOS/Android como se espera o cambia de API.         | El paso 1 (spike) lo valida antes de escribir código; el cliente va detrás de la interfaz `agente_client`.|
| Voz en web no funciona con Flutter web como se espera (permisos de micrófono, HTTPS obligatorio). | Spike antes de codificar; el navegador requiere HTTPS o `localhost`, y el despliegue en LAN por HTTP no daría micrófono (revisar con el túnel/HTTPS). |
| Ruido en tienda degrada el reconocimiento de voz.                                       | Texto siempre disponible en la misma pantalla.                                                           |
| Costo por minutos de conversación.                                                      | Sesión se cierra al salir de la pantalla Asesor y tras inactividad; revisar consumo la primera semana.   |
| Zapatos sin `colorId` (inventario con color nulo).                                      | `variantes[].colorId` acepta `null` y la tarjeta muestra "Sin color".                                    |

---

## Qué **no** está en este spec

- Recomendaciones de qué comprar para surtir inventario.
- Línea de "motivo" por zapato.
- Modo kiosco (cliente usando el agente solo).
- Guardar o analizar conversaciones.
- Tools de escritura del agente.

Cada uno, si se hace, va en su propio spec.
