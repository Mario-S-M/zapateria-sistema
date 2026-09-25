---
name: Zapatería La Prodigiosa
description: POS de mostrador para zapatería con modelo de consignación
colors:
  tinta-clara: "#181818"
  tinta-oscura: "#F5F0E6"
  papel-claro: "#FFFFFF"
  papel-oscuro: "#232323"
  fondo-claro: "#FBF3E4"
  fondo-oscuro: "#121212"
  acento: "#FFC800"
typography:
  headline-large:
    fontFamily: "Roboto, sans-serif"
    fontSize: "28px"
    fontWeight: 900
    lineHeight: 1.2
  headline-medium:
    fontFamily: "Roboto, sans-serif"
    fontSize: "24px"
    fontWeight: 800
    lineHeight: 1.2
  headline-small:
    fontFamily: "Roboto, sans-serif"
    fontSize: "20px"
    fontWeight: 800
    lineHeight: 1.2
  title-large:
    fontFamily: "Roboto, sans-serif"
    fontSize: "18px"
    fontWeight: 800
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
  sm: "10px"
  md: "16px"
  lg: "20px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
components:
  button-primary:
    backgroundColor: "{colors.acento}"
    textColor: "{colors.tinta-clara}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  card:
    backgroundColor: "{colors.papel-claro}"
    rounded: "{rounded.lg}"
    padding: "12px"
  input-field:
    backgroundColor: "{colors.papel-claro}"
    rounded: "{rounded.sm}"
---

# Design System: Zapatería La Prodigiosa

## Overview

**Creative North Star: "El Puesto de Feria"**

*(Reemplaza al norte anterior, "El Cuaderno de Ventas" — sobrio y
profesional. El negocio pidió explícitamente un giro hacia algo más bold y
juguetón, con una referencia visual concreta: tarjetas tipo "sticker" con
borde negro grueso y sombra dura, un acento amarillo saturado, tipografía
chunky. Se preserva toda la función, datos y principios de producto de
`PRODUCT.md` — solo cambia el lenguaje visual.)*

La interfaz se siente como el puesto de una feria bien organizada: cada
producto vive en su propia tarjeta recortada, con borde negro grueso y una
sombra dura que la hace sentir física, como una calcomanía pegada sobre un
fondo cálido. Es bold sin perder función — los botones siguen siendo
grandes, el contraste sigue siendo alto, y nada se sacrifica de la
velocidad de venta en mostrador. El tono es divertido y memorable, no
corporativo, pero sigue siendo una herramienta de trabajo diario: la
energía vive en la forma (bordes, sombras, peso tipográfico), no en
animación excesiva ni en desorden de color.

**Key Characteristics:**
- Neobrutalista: borde negro de 2px + sombra dura (offset 4px, sin blur) en
  cada tarjeta — nunca sombra suave ni blur.
- Un solo acento saturado (`Acento`, amarillo) para toda acción primaria —
  sin segundo o tercer acento.
- Fondo cálido (`Fondo`, crema en claro) en vez de blanco/gris neutro.
- Tipografía Roboto con pesos elevados (800-900) en títulos — chunky,
  sin ligereza.
- Radios generosos (16-20px en tarjetas) — más redondeado que Material
  estándar.
- Paridad completa entre modo claro y oscuro, con la sombra recalibrada en
  oscuro (ver Elevation & Depth).

## Colors

### Primary (tinta)
- **Tinta** (`#181818` claro / `#F5F0E6` oscuro): texto, bordes, iconos —
  el color de mayor contraste en cada tema. Es también el color de la
  sombra dura en modo claro.

### Secondary (acento)
- **Acento** (`#FFC800`): único color saturado del sistema — FAB, botones
  primarios, foco de campos, indicador de navegación seleccionada. Igual en
  ambos temas.

### Neutral
- **Papel** (`#FFFFFF` claro / `#232323` oscuro): superficie de tarjetas.
- **Fondo** (`#FBF3E4` claro / `#121212` oscuro): fondo de página —
  cálido en claro, casi negro en oscuro (no un simple invertido del
  papel).

### Named Rules
**La Regla del Acento Único.** Solo existe un color saturado (`Acento`).
Los colores semánticos preexistentes (verde=efectivo, azul=tarjeta,
naranja=mixto, morado=inversionista, rojo=eliminar) se conservan tal cual
— son información de estado, no expresión de marca, y no cuentan contra
esta regla.

**La Regla de la Sombra Dura.** Toda sombra es un offset sólido de 4px sin
blur (`BoxShadow(blurRadius: 0)`), nunca una sombra suave de Material. Es
lo que hace que una tarjeta se sienta como una calcomanía recortada, no
como una superficie flotando.

## Typography

**Display/Body Font:** Roboto (sistema, sin fuente custom todavía — ver
Do's and Don'ts).

**Character:** Pesos elevados (800-900) en títulos para lograr una
sensación "chunky"/bold sin necesitar una tipografía distinta; cuerpo de
texto se mantiene regular (400) para no sacrificar legibilidad en listas
largas.

### Hierarchy
- **Headline Large** (900, 28px): títulos de pantalla principales.
- **Headline Medium** (800, 24px): subtítulos de sección.
- **Headline Small** (800, 20px): encabezados de tarjeta o diálogo,
  título de AppBar.
- **Title Large** (800, 18px): títulos de lista/ítem destacado.
- **Body Large/Medium/Small** (400, 16/14/12px): sin cambio de peso —
  el contraste chunky vive en los títulos, no en el cuerpo.

## Layout

Sin cambios respecto a la versión anterior: navegación adaptativa por
ancho (`BottomNavigationBar` compacto / `NavigationRail` extendido en
web), contenido en `IndexedStack`. Gap más consistente ahora: 8px entre
elementos pequeños, 16-20px de margen entre tarjetas (antes 8px — se
agrandó para que la sombra dura de cada tarjeta tenga espacio para leerse
sin solaparse con la siguiente).

## Elevation & Depth

**Sombra dura, no Material.** Cada `NeoCard` (`lib/components/neo_style.dart`)
lleva borde de 2px en `Tinta` + `BoxShadow(offset: (4,4), blurRadius: 0)`.
En modo oscuro la sombra no puede ser negra pura sobre un fondo ya casi
negro — usa un tono que sigue leyéndose contra `Fondo` oscuro (ver
`NeoTheme.shadow` en el código).

Los `Card` de Material que no migraron a `NeoCard` (pantallas fuera de
`zapatos_screen.dart`) heredan `CardThemeData`: plano (`elevation: 0`) +
borde de 2px — mismo lenguaje de borde, sin la sombra dura extra. Es una
versión "quieta" del mismo sistema, no una inconsistencia: ver Components.

### Named Rules
**La Regla de la Sombra Dura.** (repetida de Colors — aplica aquí
literalmente al valor de `boxShadow`.)

## Shapes

Radios más generosos que la versión Material anterior: `10px` (botones,
campos, chips), `16px` (tarjetas vía `CardThemeData` global), `20px`
(`NeoCard` en `zapatos_screen.dart`, el tratamiento más completo).

## Components

### Buttons
- **Shape:** radio 10-12px, borde de 2px en `Tinta` en todos los botones
  (elevated, filled, outlined).
- **Primary:** fondo `Acento`, texto `Tinta`, peso 800.
- **FAB:** mismo tratamiento — fondo `Acento`, borde `Tinta`.

### Cards / Containers
Dos niveles de tratamiento, ambos parte del mismo sistema:
- **`NeoCard`** (`zapatos_screen.dart`): borde 2px + sombra dura offset —
  el tratamiento completo, "sticker".
- **`CardThemeData` global** (resto de pantallas): borde 2px, radio 16px,
  `elevation: 0`, sin sombra dura — versión plana del mismo lenguaje.
  Migrar una pantalla a `NeoCard` es una mejora válida, no un requisito.

### Inputs / Fields
- **Style:** relleno `Papel`, borde 2px `Tinta`, radio 14px.
- **Focus:** borde `Acento`, grosor 3px.

### Navigation
- **Mobile:** `BottomNavigationBar`, ítem seleccionado en `Tinta`, peso
  800.
- **Web/tablet:** `NavigationRail`, indicador `Acento` sólido (antes era
  un contenedor pastel — ahora es el acento saturado completo).

### Chips / Badges
- Chips genéricos (filtros, categorías): borde 1.5px `Tinta`, fondo
  `Acento` cuando están seleccionados.
- Badges de estado semántico (`_TipoBadge`, método de pago en Ventas):
  **sin cambios** — mantienen sus colores pastel propios
  (verde/azul/naranja/morado), no se tocaron.

### NeoIconButton (`lib/components/neo_style.dart`)
Reemplaza al `IconButton` plano en filas de acciones de tarjeta (editar,
carrito, inventario, eliminar): caja de 40×40 con borde 2px `Tinta`,
esquinas de 10px. Úsalo en vez de `IconButton` desnudo dentro de una
`NeoCard` o cualquier fila de acciones nueva.

### ColorCircle / ColorPickerGrid (componente de dominio)
Sin cambios — sigue representando el color de un zapato como círculo
sólido o partido en dos mitades para combinaciones. No se tocó porque ya
funcionaba bien y no es parte del lenguaje "chrome" (botones/tarjetas/nav)
que cambió.

## Do's and Don'ts

### Do:
- **Do** usar `NeoCard` y `NeoIconButton` (`lib/components/neo_style.dart`)
  para cualquier tarjeta o botón de ícono nuevo — no dupliques el patrón
  con estilos inline.
- **Do** mantener el acento amarillo único para toda acción primaria.
- **Do** conservar los colores semánticos de estado (verde/azul/naranja/
  morado/rojo) tal como están — no son parte de la regla del acento único.
- **Do** priorizar botones y campos grandes, fáciles de tocar rápido en el
  mostrador — la energía visual nunca debe costar velocidad de venta.
- **Do** verificar overflow al agregar texto largo junto a un badge/chip:
  el peso tipográfico más alto ocupa más espacio que antes (ver el fix de
  `_MobileTitle` en `ventas_screen.dart`, envuelto en `Flexible`).

### Don't:
- **Don't** usar sombras suaves de Material (`elevation` > 0 sin borde) —
  todo es plano + borde, o borde + sombra dura. Nunca sombra difuminada.
- **Don't** introducir un segundo color saturado — la regla del acento
  único se mantiene, solo cambió de azul a amarillo.
- **Don't** sacrificar contraste o tamaño de toque por el look bold — sigue
  siendo una herramienta de trabajo real, no una app infantil de verdad.
- **Don't** inventar una fuente custom sin evaluarlo — hoy sigue siendo
  Roboto con pesos altos; una fuente redondeada tipo "Fredoka" sería un
  paso natural si se quiere ir más lejos, pero implica agregar una
  dependencia (`google_fonts`) y no se hizo en esta pasada.
