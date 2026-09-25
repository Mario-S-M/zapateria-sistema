#!/usr/bin/env node
// Agrega una tarjeta nueva a la columna "Por hacer" del Kanban.md cuando se
// abre un issue en GitHub. Es idempotente: si ya existe una tarjeta para ese
// número de issue en cualquier columna, no hace nada.
//
// Variables de entorno esperadas (las pone el workflow):
//   KANBAN_PATH   - ruta al archivo Kanban.md
//   ISSUE_NUMBER  - número del issue
//   ISSUE_TITLE   - título del issue

import { readFileSync, writeFileSync } from "node:fs";

const kanbanPath = process.env.KANBAN_PATH;
const issueNumber = process.env.ISSUE_NUMBER;
const issueTitle = process.env.ISSUE_TITLE || "";

if (!kanbanPath) {
  console.error("Falta KANBAN_PATH");
  process.exit(1);
}
if (!issueNumber) {
  console.error("Falta ISSUE_NUMBER");
  process.exit(1);
}

const content = readFileSync(kanbanPath, "utf8");

const alreadyExists = new RegExp(`^- \\[.\\] #${issueNumber}\\b`, "m").test(content);
if (alreadyExists) {
  console.log(`Ya existe una tarjeta para #${issueNumber} — no se agrega otra.`);
  process.exit(0);
}

const sections = content.split(/(?=^## .+$)/m);
const targetIdx = sections.findIndex((s) => s.startsWith("## Por hacer"));
if (targetIdx === -1) {
  console.error('No existe la columna "Por hacer" en el kanban.');
  process.exit(1);
}

const newLine = `- [ ] #${issueNumber} ${issueTitle}`.trimEnd();
const lines = sections[targetIdx].split("\n");
lines.splice(1, 0, newLine);
sections[targetIdx] = lines.join("\n");

writeFileSync(kanbanPath, sections.join(""));
console.log(`Tarjeta agregada a "Por hacer": ${newLine}`);
