#!/usr/bin/env node
// Mueve tarjetas en el Kanban.md (formato del plugin "Kanban" de Obsidian)
// según el estado de un Pull Request.
//
// Convención: cada tarjeta debe incluir el número del issue que resuelve,
// ej. "- [ ] #12 Implementar login de administrador". El PR debe referenciar
// el mismo número en el título o la descripción (ej. "Closes #12").
//
// Variables de entorno esperadas (las pone el workflow):
//   KANBAN_PATH  - ruta al archivo Kanban.md
//   PR_TITLE     - título del PR
//   PR_BODY      - descripción del PR
//   PR_MERGED    - "true" | "false"
//   PR_ACTION    - "opened" | "reopened" | "closed"

import { readFileSync, writeFileSync } from "node:fs";

const kanbanPath = process.env.KANBAN_PATH;
const title = process.env.PR_TITLE || "";
const body = process.env.PR_BODY || "";
const merged = process.env.PR_MERGED === "true";
const action = process.env.PR_ACTION;

if (!kanbanPath) {
  console.error("Falta KANBAN_PATH");
  process.exit(1);
}

const text = `${title}\n${body}`;
const issueNumbers = [...new Set([...text.matchAll(/#(\d+)/g)].map((m) => m[1]))];

if (issueNumbers.length === 0) {
  console.log("No se encontraron referencias a issues (#N) en el PR. Nada que mover.");
  process.exit(0);
}

let targetColumn;
if (action === "closed" && merged) {
  targetColumn = "Hecho";
} else if (action === "opened" || action === "reopened") {
  targetColumn = "En progreso";
} else {
  console.log(`Acción "${action}" (merged=${merged}) no requiere mover tarjetas.`);
  process.exit(0);
}

let content = readFileSync(kanbanPath, "utf8");

// Divide el archivo en secciones por encabezado de columna (## Nombre)
const sections = content.split(/(?=^## .+$)/m);

function findLineForIssue(num) {
  for (const section of sections) {
    const lines = section.split("\n");
    const match = lines.find(
      (l) => l.trim().startsWith("- [") && new RegExp(`#${num}\\b`).test(l)
    );
    if (match) return match;
  }
  return null;
}

for (const num of issueNumbers) {
  const line = findLineForIssue(num);
  if (!line) {
    console.log(`No se encontró tarjeta para #${num} en el kanban — se omite.`);
    continue;
  }

  const targetIdx = sections.findIndex((s) => s.startsWith(`## ${targetColumn}`));
  if (targetIdx === -1) {
    console.log(`No existe la columna "${targetColumn}" en el kanban.`);
    continue;
  }

  // Ya está en la columna destino: no hacer nada
  if (sections[targetIdx].includes(line)) {
    console.log(`La tarjeta de #${num} ya está en "${targetColumn}".`);
    continue;
  }

  // Quita la línea de su columna actual
  for (let i = 0; i < sections.length; i++) {
    if (sections[i].includes(line)) {
      sections[i] = sections[i]
        .split("\n")
        .filter((l) => l !== line)
        .join("\n");
      break;
    }
  }

  // La inserta justo después del encabezado de la columna destino
  const targetLines = sections[targetIdx].split("\n");
  targetLines.splice(1, 0, line);
  sections[targetIdx] = targetLines.join("\n");

  console.log(`Tarjeta de #${num} movida a "${targetColumn}".`);
}

content = sections.join("");
writeFileSync(kanbanPath, content);
