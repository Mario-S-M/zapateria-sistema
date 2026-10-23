#!/usr/bin/env node
// Configura el agente de ElevenLabs del asesor de ventas (SPEC 01).
//
//   node scripts/elevenlabs-agent.mjs setup    # crea secreto, servidor MCP, client tool y agente
//   node scripts/elevenlabs-agent.mjs prompt   # actualiza solo el prompt del agente existente
//
// Lee del .env de la raíz: ELEVENLABS_API_KEY, MCP_SHARED_SECRET y, para `prompt`,
// ELEVENLABS_AGENT_ID. Opcional: MCP_PUBLIC_URL (por defecto el hostname del túnel).
// `setup` escribe ELEVENLABS_AGENT_ID en el .env de la raíz y en zapateria-backend/.env.
// Nunca imprime la llave ni el secreto.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const raiz = join(dirname(fileURLToPath(import.meta.url)), "..");
const envRaiz = join(raiz, ".env");
const envBackend = join(raiz, "zapateria-backend", ".env");
const promptMd = join(raiz, "zapateria-backend", "src", "agente", "agent-prompt.md");

const API = "https://api.elevenlabs.io/v1/convai";

function leerEnv(ruta) {
  const env = {};
  for (const linea of readFileSync(ruta, "utf8").split("\n")) {
    const m = linea.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) env[m[1]] = m[2];
  }
  return env;
}

function guardarVariable(ruta, clave, valor) {
  if (!existsSync(ruta)) return;
  let txt = readFileSync(ruta, "utf8");
  const re = new RegExp(`^${clave}=.*$`, "m");
  if (re.test(txt)) txt = txt.replace(re, `${clave}=${valor}`);
  else txt += `${txt.endsWith("\n") ? "" : "\n"}${clave}=${valor}\n`;
  writeFileSync(ruta, txt);
}

const env = leerEnv(envRaiz);
const apiKey = env.ELEVENLABS_API_KEY;
if (!apiKey) {
  console.error("Falta ELEVENLABS_API_KEY en .env");
  process.exit(1);
}

async function llamar(metodo, ruta, cuerpo) {
  const res = await fetch(`${API}${ruta}`, {
    method: metodo,
    headers: { "xi-api-key": apiKey, "content-type": "application/json" },
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
  });
  const texto = await res.text();
  if (!res.ok) {
    console.error(`${metodo} ${ruta} -> ${res.status}\n${texto.slice(0, 800)}`);
    process.exit(1);
  }
  return texto ? JSON.parse(texto) : {};
}

// El prompt del sistema es el bloque de código del markdown bajo "## Prompt del sistema".
function leerPrompt() {
  const md = readFileSync(promptMd, "utf8");
  const m = md.split("## Prompt del sistema")[1]?.match(/```\n([\s\S]*?)\n```/);
  if (!m) throw new Error("No encontré el prompt en agent-prompt.md");
  return m[1].trim();
}

function leerPrimerMensaje() {
  const md = readFileSync(promptMd, "utf8");
  const m = md.match(/## Primer mensaje\s+([^\n#][^\n]*)/);
  if (!m) throw new Error("No encontré el primer mensaje en agent-prompt.md");
  return m[1].trim();
}

async function setup() {
  if (env.ELEVENLABS_AGENT_ID) {
    console.error(`Ya hay ELEVENLABS_AGENT_ID en .env (${env.ELEVENLABS_AGENT_ID}). Usa "prompt" para actualizar.`);
    process.exit(1);
  }
  if (!env.MCP_SHARED_SECRET) {
    console.error("Falta MCP_SHARED_SECRET en .env");
    process.exit(1);
  }
  const urlMcp = env.MCP_PUBLIC_URL || "https://zapateria-mcp.aragorn-system.com/mcp";

  // Reanudable: si un intento anterior falló después de crear el secreto, se reutiliza.
  let secretId = env.ELEVENLABS_MCP_SECRET_ID;
  if (secretId) {
    console.log("secreto del workspace reutilizado:", secretId);
  } else {
    const secreto = await llamar("POST", "/secrets", {
      type: "new",
      name: "zapateria_mcp_secret",
      value: env.MCP_SHARED_SECRET,
    });
    secretId = secreto.secret_id;
    guardarVariable(envRaiz, "ELEVENLABS_MCP_SECRET_ID", secretId);
    console.log("secreto del workspace creado:", secretId);
  }

  // Si ya se creó desde el dashboard (con el mismo nombre), se reutiliza en vez de duplicarlo.
  const existentes = await llamar("GET", "/mcp-servers");
  const lista = existentes.mcp_servers ?? existentes.servers ?? [];
  const previo = lista.find((m) => (m.config?.name ?? m.name) === "zapateria-inventario");
  let mcpId = previo?.id;
  if (mcpId) {
    console.log("servidor MCP reutilizado:", mcpId);
  } else {
    const mcp = await llamar("POST", "/mcp-servers", {
      config: {
        name: "zapateria-inventario",
        description: "Inventario de La Prodigiosa (solo lectura)",
        url: urlMcp,
        transport: "STREAMABLE_HTTP",
        approval_policy: "auto_approve_all",
        request_headers: { "X-MCP-Secret": { secret_id: secretId } },
      },
    });
    mcpId = mcp.id;
    console.log("servidor MCP creado:", mcpId);
  }

  const tool = await llamar("POST", "/tools", {
    tool_config: {
      type: "client",
      name: "mostrar_recomendaciones",
      description:
        "Abre en la pantalla del vendedor la lista final de calzado recomendado para la talla del cliente. " +
        "Llámala cuando ya tengas pocas opciones, ya hayas preguntado color y estilo, o el vendedor lo pida.",
      expects_response: true,
      response_timeout_secs: 10,
      parameters: {
        type: "object",
        properties: {
          talla: { type: "number", description: "Talla exacta que pidió el cliente, ej. 23 o 23.5." },
          zapato_ids: {
            type: "string",
            description:
              "Ids de los zapatos recomendados separados por comas, del más al menos recomendado.",
          },
          categoria_id: {
            type: "string",
            description: "Id de la categoría, SOLO si el cliente la pidió explícitamente (ej. escolar).",
          },
          color_id: { type: "string", description: "Id del color si el cliente ya eligió uno." },
        },
        required: ["talla", "zapato_ids"],
      },
    },
  });
  const toolId = tool.id;
  console.log("client tool creado:", toolId);

  const agente = await llamar("POST", "/agents/create", {
    name: "Asesor La Prodigiosa",
    conversation_config: {
      agent: {
        first_message: leerPrimerMensaje(),
        language: "es",
        prompt: {
          prompt: leerPrompt(),
          llm: "gemini-2.5-flash",
          tool_ids: [toolId],
          mcp_server_ids: [mcpId],
        },
      },
      tts: { model_id: "eleven_flash_v2_5" },
    },
    platform_settings: {
      auth: { enable_auth: true },
      // Permite que la app abra sesiones solo de texto (sin audio) desde el cliente.
      overrides: { conversation_config_override: { conversation: { text_only: true } } },
    },
  });
  const agentId = agente.agent_id;
  console.log("agente creado:", agentId);

  guardarVariable(envRaiz, "ELEVENLABS_AGENT_ID", agentId);
  guardarVariable(envBackend, "ELEVENLABS_AGENT_ID", agentId);
  console.log("ELEVENLABS_AGENT_ID guardado en .env (raíz y backend)");
}

async function actualizarPrompt() {
  const agentId = env.ELEVENLABS_AGENT_ID;
  if (!agentId) {
    console.error("Falta ELEVENLABS_AGENT_ID en .env; corre primero `setup`.");
    process.exit(1);
  }
  await llamar("PATCH", `/agents/${agentId}`, {
    conversation_config: {
      agent: { first_message: leerPrimerMensaje(), prompt: { prompt: leerPrompt() } },
    },
  });
  console.log("prompt actualizado");
}

const modo = process.argv[2];
if (modo === "setup") await setup();
else if (modo === "prompt") await actualizarPrompt();
else {
  console.error("Uso: node scripts/elevenlabs-agent.mjs setup|prompt");
  process.exit(1);
}
