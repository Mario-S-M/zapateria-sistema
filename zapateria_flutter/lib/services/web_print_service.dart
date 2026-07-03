import 'dart:js_interop';
import 'package:intl/intl.dart';
import 'package:zapateria_flutter/config/business_config.dart';
import 'package:zapateria_flutter/models/ticket_data.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

@JS('flutterPrintTicket')
external void _flutterPrintTicket(String htmlContent);

class WebPrintService {
  static void printTicketWeb(TicketData ticket) {
    _flutterPrintTicket(_buildFullHtml(ticket));
  }

  static String _buildFullHtml(TicketData ticket) {
    final dateStr =
        DateFormat('dd/MM/yyyy  HH:mm', 'es_MX').format(ticket.fecha);
    final sb = StringBuffer();

    sb.write('''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  @page { size: 80mm auto; margin: 3mm; }
  * { box-sizing: border-box; }
  body {
    font-family: 'Courier New', Courier, monospace;
    font-size: 9pt;
    width: 72mm;
    margin: 0;
    padding: 0;
    color: #000;
  }
  p { margin: 1px 0; padding: 0; }
  .center { text-align: center; }
  .bold { font-weight: bold; }
  .small { font-size: 8pt; }
  .indent { padding-left: 8px; }
  .row { display: flex; justify-content: space-between; }
  hr { border: none; border-top: 1px dashed #000; margin: 3px 0; }
  .folio-code { text-align: center; letter-spacing: 3px; font-size: 13pt; margin: 4px 0; }
</style>
</head>
<body>
''');

    // Header
    sb.write('<p class="center bold">${_e(kBusinessName)}</p>\n');
    sb.write('<p class="center">${_e(kBusinessAddr1)}</p>\n');
    sb.write('<p class="center">${_e(kBusinessAddr2)}</p>\n');
    sb.write('<p class="center">RFC: ${_e(kBusinessRFC)}</p>\n');
    sb.write('<hr>\n');

    // Folio + fecha
    sb.write('<p>TICKET: ${_e(ticket.folio)}</p>\n');
    sb.write('<p>Fecha: ${_e(dateStr)}</p>\n');
    sb.write('<hr>\n');

    // Items
    for (final item in ticket.items) {
      final name = item.nombre.toUpperCase();
      final modelo = item.modelo.isNotEmpty ? '  mod. ${item.modelo}' : '';
      sb.write('<p class="bold">${_e(name)}${_e(modelo)}</p>\n');

      final parts = <String>[];
      if (item.color != null) parts.add(item.color!);
      if (item.talla != null) {
        final t = item.talla! % 1 == 0
            ? item.talla!.toInt().toString()
            : item.talla.toString();
        parts.add('T.$t');
      }
      if (parts.isNotEmpty) {
        sb.write('<p class="indent">${_e(parts.join("  "))}</p>\n');
      }
      sb.write(
        '<p class="indent row">'
        '<span>${item.cantidad} x \$${_e(formatPrice(item.precioUnitario))}</span>'
        '<span>\$${_e(formatPrice(item.subtotal))}</span>'
        '</p>\n',
      );
    }

    // Total
    sb.write('<hr>\n');
    sb.write(
      '<p class="bold row">'
      '<span>TOTAL:</span>'
      '<span>\$${_e(formatPrice(ticket.total))}</span>'
      '</p>\n',
    );

    // Pago
    sb.write('<hr>\n');
    sb.write('<p>Pago: ${_e(ticket.metodoPago)}</p>\n');
    if (ticket.montoTarjeta != null && ticket.montoTarjeta! > 0) {
      sb.write(
          '<p class="indent">Tarjeta: \$${_e(formatPrice(ticket.montoTarjeta!))}</p>\n');
    }
    if (ticket.montoRecibido != null && ticket.montoRecibido! > 0) {
      sb.write(
          '<p class="indent">Recibido: \$${_e(formatPrice(ticket.montoRecibido!))}</p>\n');
    }
    if (ticket.cambio != null && ticket.cambio! >= 0) {
      sb.write(
          '<p class="indent">Cambio: \$${_e(formatPrice(ticket.cambio!))}</p>\n');
    }
    if (ticket.inversionistaNombre != null) {
      sb.write('<p>Cuenta: ${_e(ticket.inversionistaNombre!)}</p>\n');
    }

    // Folio as text display
    sb.write('<hr>\n');
    sb.write('<p class="folio-code">${_e(ticket.folio)}</p>\n');

    // Policy
    sb.write('<hr>\n');
    for (final line in kTicketPolicy) {
      sb.write('<p class="center small">${_e(line)}</p>\n');
    }
    sb.write('<hr>\n');
    sb.write('<p class="center bold">¡Gracias por su compra!</p>\n');

    sb.write('</body></html>');
    return sb.toString();
  }

  static String _e(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
