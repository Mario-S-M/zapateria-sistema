---
name: Zapatería La Prodigiosa
description: POS de mostrador para zapatería con modelo de consignación
colors:
  tinta-carbon: "rgba(0,0,0,0.87)"
  tinta-carbon-dark: "#FFFFFF"
  azul-trabajo: "#2196F3"
  papel: "#FFFFFF"
  papel-dark: "#212121"
  fondo-neutro: "#F5F5F5"
  fondo-neutro-dark: "#000000"
  contenedor-azul: "#E3F2FD"
  contenedor-azul-dark: "#0D47A1"
  on-contenedor-azul: "#1565C0"
  on-contenedor-azul-dark: "#BBDEFB"
  borde-neutro: "#E0E0E0"
  borde-neutro-dark: "#616161"
typography:
  headline-large:
    fontFamily: "Roboto, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
  headline-medium:
    fontFamily: "Roboto, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.2
  headline-small:
    fontFamily: "Roboto, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.2
  title-large:
    fontFamily: "Roboto, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
  body-large:
    fontFamily: "Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.4
  body-medium:
    fontFamily: "Roboto, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
  body-small:
    fontFamily: "Roboto, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
rounded:
  sm: "8px"
  md: "12px"
  full: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
components:
  button-primary:
    backgroundColor: "{colors.tinta-carbon}"
    textColor: "{colors.papel}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  card:
    backgroundColor: "{colors.papel}"
    rounded: "{rounded.md}"
    padding: "16px"
  input-field:
    backgroundColor: "{colors.fondo-neutro}"
    rounded: "{rounded.sm}"
---

# Design System: Zapatería La Prodigiosa

## Overview

**Creative North Star: "El Cuaderno de Ventas"**

La interfaz se comporta como una libreta de ventas bien llevada: plana, legible
de un vistazo, sin decoración que no ayude a cerrar la venta rápido. El tono es
cálido pero profesional — Material Design estándar de Android, sin capas de
personalidad de marca (todavía no existe una marca visual definida para
Zapatería La Prodigiosa), pero tampoco frío ni corporativo. La prioridad es
que un vendedor pueda escanear, cobrar e imprimir sin fricción visual, con el
dueño usando las mismas pantallas en un momento más pausado para revisar
inventario y cierres.

Esta versión de `DESIGN.md` documenta el sistema tal como existe en el código
(`zapateria_flutter/lib/providers/theme_provider.dart`), con una dirección
confirmada en esta sesión: mover las tarjetas hacia un tratamiento plano (sin
sombra), documentado en Elevation & Depth — el código actual todavía tiene
`elevation: 1` en `CardThemeData`, pendiente de actualizar en una pasada de
implementación.

**Key Characteristics:**
- Material Design 3 estándar en Android, sin adaptación nativa por plataforma
- Acento azul único (`Azul Trabajo`) para interacción y selección, sin
  secundario/terciario adicional
- Tipografía Roboto por roles (headline/title/body), sin variación de marca
- Modo claro y oscuro completamente definidos y simétricos

## Colors

Paleta funcional derivada de Material estándar — sin marca visual propia
todavía, así que los nombres describen el rol, no una identidad de color
inventada.

### Primary
- **Tinta Carbón** (`rgba(0,0,0,0.87)` claro / `#FFFFFF` oscuro): texto
  principal, botones primarios, iconos activos. Es el color de mayor
  contraste en cada tema.

### Secondary
- **Azul Trabajo** (`#2196F3`): único acento de interacción — selección de
  navegación, foco de campos, elementos ligados a una acción. Igual en ambos
  temas.

### Neutral
- **Papel** (`#FFFFFF` claro / `#212121` oscuro): superficie de tarjetas y
  fondo del `Scaffold` en modo claro.
- **Fondo Neutro** (`#F5F5F5` claro / `#000000` oscuro): fondo de página y
  relleno de campos de formulario.
- **Contenedor Azul** (`#E3F2FD` claro / `#0D47A1` oscuro): fondo de chips o
  contenedores ligados al acento (ej. indicador de navegación seleccionada).
- **Borde Neutro** (`#E0E0E0` claro / `#616161` oscuro): bordes de campos de
  formulario en estado normal (no enfocado).

### Named Rules
**La Regla del Acento Único.** Solo existe un color de interacción (Azul
Trabajo). No se introduce un segundo o tercer acento sin una razón funcional
clara — la paleta se mantiene simple a propósito.

## Typography

**Display Font:** Roboto (sistema, sin fallback custom)
**Body Font:** Roboto
**Label/Mono Font:** Roboto (sin distinción tipográfica para labels todavía)

**Character:** Tipografía de sistema Android sin personalización — prioriza
legibilidad rápida bajo presión de mostrador sobre expresión tipográfica.

### Hierarchy
- **Headline Large** (700, 28px, 1.2): títulos de pantalla principales.
- **Headline Medium** (600, 24px, 1.2): subtítulos de sección.
- **Headline Small** (600, 20px, 1.2): encabezados de tarjeta o diálogo.
- **Title Large** (600, 18px, 1.3): títulos de lista/ítem destacado.
- **Body Large** (400, 16px, 1.4): texto de contenido principal.
- **Body Medium** (400, 14px, 1.4): texto secundario, descripciones.
- **Body Small** (400, 12px, 1.4): metadatos, texto auxiliar (opacidad
  reducida: `black38`/`white54`).

Los roles `Display` y `Label` de Material no están personalizados en el
código — usan el default de la plataforma; no se documentan valores
inventados aquí.

## Layout

No hay un sistema de espaciado formalmente tokenizado en el código todavía
(gap observado más consistente: 8px, ej. `ColorPickerGrid`). Navegación
adaptativa por ancho: `BottomNavigationBar` de 7 destinos en compacto
(teléfono), `NavigationRail` extendido (ancho mínimo 180px) en ancho amplio
(web/tablet) — ver `MainShell`. El contenido de cada pantalla vive en un
`IndexedStack`, sin transición entre pestañas.

## Elevation & Depth

**Dirección objetivo (confirmada en esta sesión): plano.** Las tarjetas se
separan del fondo por color/borde, no por sombra. El código actual todavía
define `elevation: 1` en `CardThemeData` (sombra sutil, radio 12px) — es
deuda de implementación pendiente, no el estado deseado.

### Named Rules
**La Regla de lo Plano.** Ninguna superficie usa sombra para transmitir
jerarquía. La separación viene de `Papel` contra `Fondo Neutro`, o de un
borde de 1px cuando el contraste de color no basta.

## Shapes

Dos radios en uso: `8px` (botones, campos de formulario, indicador de
navegación) y `12px` (tarjetas). Sin bordes decorativos ni recortes
distintivos más allá de círculos para el color del zapato (ver
`ColorCircle`).

## Components

### Buttons
- **Shape:** radio 8px (`{rounded.sm}`)
- **Primary:** fondo `Tinta Carbón`, texto `Papel` — usado como acción
  principal (guardar, cobrar).
- **Hover/Focus:** sin tratamiento custom más allá del ripple de Material
  por defecto.

### Cards / Containers
- **Corner Style:** 12px (`{rounded.md}`)
- **Background:** `Papel`
- **Shadow Strategy:** ver Elevation & Depth — dirección objetivo es plano,
  implementación actual todavía tiene `elevation: 1`.
- **Border:** ninguno hoy; considerar borde de 1px en `Borde Neutro` al
  quitar la sombra, para mantener separación visual.

### Inputs / Fields
- **Style:** relleno `Fondo Neutro`, borde 1px `Borde Neutro`, radio 8px.
- **Focus:** borde cambia a `Azul Trabajo`, grosor 2px.

### Navigation
- **Mobile:** `BottomNavigationBar` fijo, 7 destinos, ítem seleccionado en
  `Tinta Carbón` (color primario del tema), inactivos en color deshabilitado
  del tema.
- **Web/tablet:** `NavigationRail` extendido (180px mínimo), indicador
  `Contenedor Azul`, ícono/label seleccionado en `Azul Trabajo`, semibold.

### ColorCircle / ColorPickerGrid (componente de dominio)
Representa el color de un zapato como un círculo — sólido, o partido en dos
mitades cuando el color es una combinación (`isCombo`). Es el único
componente verdaderamente distintivo del sistema: traduce un concepto del
negocio (colores de zapato, incluyendo combinaciones) directamente a forma
visual, sin pasar por texto. El estado seleccionado en `ColorPickerGrid` se
marca con borde de 3px en `Azul Trabajo` (vs. 1px `Borde Neutro` en reposo).

## Do's and Don'ts

### Do:
- **Do** mantener el acento azul único para toda interacción/selección — no
  introducir un segundo acento sin razón funcional.
- **Do** priorizar botones y campos grandes, fáciles de tocar rápido en el
  mostrador — velocidad sobre expresividad.
- **Do** mover las tarjetas a plano (sin sombra) en la próxima pasada de
  implementación, reemplazando `elevation: 1` por separación de color/borde.
- **Do** mantener paridad completa entre modo claro y oscuro para cualquier
  componente nuevo.

### Don't:
- **Don't** agregar sombras, glassmorphism, o efectos decorativos — no
  encajan con la dirección plana confirmada ni con el principio de
  confiabilidad sobre novedad de `PRODUCT.md`.
- **Don't** animar de forma llamativa transiciones de uso frecuente (ej. al
  guardar una venta) — cada fricción extra cuesta tiempo real en el
  mostrador con un cliente esperando.
- **Don't** inventar una identidad de marca (logo, paleta custom) sin que el
  negocio la defina — hoy no existe, y no se debe fabricar una.
