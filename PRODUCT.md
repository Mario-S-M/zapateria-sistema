# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Vendedores/cajeros de Zapatería La Prodigiosa, en el mostrador de la tienda
física, durante el proceso de venta con el cliente presente — necesitan
velocidad y bajo fricción (buscar zapato, cobrar, imprimir ticket).
Secundariamente, el dueño del negocio usa las mismas pantallas para revisar
inventario, cierre de caja e inversionistas, en un contexto más pausado, sin
presión de cliente esperando.

## Product Purpose

Sistema de punto de venta e inventario para una zapatería física con modelo
de consignación (inversionistas). Permite catalogar zapatos con
colores/tallas, controlar stock por combinación color-talla, registrar
ventas con métodos de pago mixtos, imprimir tickets ESC/POS por Bluetooth, y
dar seguimiento a cuánto efectivo se debe a cada inversionista al cierre de
caja.

## Positioning

A diferencia de un POS genérico, está construido específicamente alrededor
del modelo de consignación de la tienda: cada zapato y cada venta puede
ligarse a un inversionista, y el cierre de caja desglosa automáticamente
cuánto efectivo corresponde a cada uno. También maneja precios variables por
rango de talla (`PrecioRango`) y por tipo de cliente
(público/mayorista/inversionista).

## Operating Context

Mostrador de tienda física, con el cliente presente durante la venta — el
flujo de venta necesita ser rápido y con poca fricción. Uso principal en
dispositivos Android (teléfono o tablet). Incluye escaneo de código de
barras por cámara con reconocimiento de marca por patrón, e impresión de
tickets vía impresora Bluetooth ESC/POS. Existe también un build web
(nginx, vía Docker) para uso administrativo, pero el uso diario principal es
Android en tienda.

## Capabilities and Constraints

- Backend NestJS + PostgreSQL corriendo en una Raspberry Pi 4 local,
  expuesto por Cloudflare Tunnel.
- Inventario se controla por tupla (zapato, color, talla), independiente del
  catálogo de zapatos.
- Ventas decrementan inventario y calculan el total server-side.
- Métodos de pago: efectivo, tarjeta, mixto.
- Impresión de tickets por Bluetooth: `pubspec.yaml` declara
  `flutter_bluetooth_serial`; `CLAUDE.md` documenta el servicio como
  `TicketPrintService` sin especificar el mismo paquete de forma consistente
  en todo el repo — desalineación detectada por el grafo de conocimiento del
  proyecto, pendiente de confirmar cuál es la fuente de verdad.
- Sin restricciones de hardware confirmadas (no se reportaron dispositivos
  de gama baja ni impresora específica con limitaciones conocidas).

## Brand Commitments

No existe marca visual definida (sin logo ni paleta de colores
establecida). Los tickets impresos sí incluyen nombre del negocio, RFC,
dirección y política de garantía (configurado en
`lib/config/business_config.dart`), pero eso es contenido textual, no
identidad visual.

## Evidence on Hand

Sin evidencia visual (capturas, mockups, sistema de diseño) registrada
todavía. El código fuente en `zapateria_flutter/lib/` es la única fuente de
verdad visual actual.

## Product Principles

- Velocidad en el mostrador: cada pantalla usada durante la venta activa
  (buscar, cobrar, imprimir) debe minimizar fricción y pasos, porque hay un
  cliente esperando.
- El modelo de consignación es central, no un caso especial: inversionista,
  precios por rango de talla, y desglose de cierre de caja deben sentirse
  como parte natural del flujo, no como una función escondida.
- Confiabilidad sobre novedad: es una herramienta de trabajo diario para un
  negocio real; prioriza claridad y consistencia sobre efectos visuales
  llamativos.
- Un solo lenguaje visual entre Android/iOS/web: no hay adaptación nativa
  por plataforma, así que la coherencia visual entre plataformas importa más
  que imitar convenciones específicas de cada SO.

## Accessibility & Inclusion

No se estableció ningún requerimiento de accesibilidad específico para este
proyecto.
