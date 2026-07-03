import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zapateria_flutter/config/business_config.dart';
import 'package:zapateria_flutter/models/ticket_data.dart';
import 'package:zapateria_flutter/services/ticket_print_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class TicketScreen extends StatelessWidget {
  final TicketData ticket;

  const TicketScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('Ticket de Venta'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Listo'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: _ReceiptCard(ticket: ticket),
                ),
              ),
            ),
          ),
          _BottomBar(ticket: ticket),
        ],
      ),
    );
  }
}

// ── Receipt card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final TicketData ticket;

  const _ReceiptCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    const receiptFont = TextStyle(fontFamily: 'Courier New', fontSize: 13);
    final boldReceipt = receiptFont.copyWith(fontWeight: FontWeight.bold);
    final smallReceipt = receiptFont.copyWith(fontSize: 11, color: Colors.grey.shade700);
    final dateStr = DateFormat('dd/MM/yyyy  HH:mm', 'es_MX').format(ticket.fecha);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo / Header ────────────────────────────────
          Text('TICKET DE COMPRA',
              style: boldReceipt.copyWith(fontSize: 14, letterSpacing: 1.2),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(kBusinessName,
              style: boldReceipt.copyWith(fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(kBusinessAddr1,
              style: smallReceipt, textAlign: TextAlign.center),
          Text(kBusinessAddr2,
              style: smallReceipt, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('RFC: $kBusinessRFC',
              style: smallReceipt.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          _Separator(dashed: false),

          // ── Folio + Fecha ─────────────────────────────────
          Text('TICKET: ${ticket.folio}', style: receiptFont, textAlign: TextAlign.center),
          Text('Fecha: $dateStr', style: receiptFont, textAlign: TextAlign.center),
          if (ticket.clienteNombre != null && ticket.clienteNombre!.isNotEmpty)
            Text('Cliente: ${ticket.clienteNombre}', style: receiptFont, textAlign: TextAlign.center),
          _Separator(),

          // ── Items ─────────────────────────────────────────
          for (final item in ticket.items) ...[
            const SizedBox(height: 6),
            _ItemRow(item: item, receiptFont: receiptFont, boldFont: boldReceipt),
          ],
          const SizedBox(height: 6),
          _Separator(),

          // ── Total ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL:', style: boldReceipt.copyWith(fontSize: 15)),
              Text('\$${formatPrice(ticket.total)}',
                  style: boldReceipt.copyWith(
                      fontSize: 15, color: Colors.green.shade700)),
            ],
          ),
          _Separator(),

          // ── Pago ──────────────────────────────────────────
          Text('Pago: ${ticket.metodoPago}', style: receiptFont),
          if (ticket.montoTarjeta != null && ticket.montoTarjeta! > 0)
            _PayRow('Tarjeta:', '\$${formatPrice(ticket.montoTarjeta!)}',
                receiptFont),
          if (ticket.montoRecibido != null && ticket.montoRecibido! > 0)
            _PayRow('Recibido:', '\$${formatPrice(ticket.montoRecibido!)}',
                receiptFont),
          if (ticket.cambio != null && ticket.cambio! >= 0)
            _PayRow('Cambio:', '\$${formatPrice(ticket.cambio!)}', boldReceipt,
                color: Colors.green.shade700),
          if (ticket.inversionistaNombre != null) ...[
            const SizedBox(height: 4),
            Text('Cuenta: ${ticket.inversionistaNombre}',
                style: smallReceipt),
          ],
          _Separator(dashed: false),

          // ── Barcode ───────────────────────────────────────
          const SizedBox(height: 8),
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: ticket.folio,
            width: double.infinity,
            height: 56,
            drawText: false,
            color: Colors.black,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(ticket.folio,
              style: smallReceipt, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          _Separator(dashed: false),

          // ── Garantía ──────────────────────────────────────
          const SizedBox(height: 6),
          for (final line in kTicketPolicy)
            Text(line,
                style: smallReceipt.copyWith(fontSize: 10),
                textAlign: TextAlign.center),
          _Separator(dashed: false),

          const SizedBox(height: 6),
          Text('¡Gracias por su compra!',
              style: boldReceipt.copyWith(fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),

          // ── Disclaimer ───────────────────────────────────
          Text(
            '* Este ticket no es un comprobante fiscal\n  ni documento legal.',
            style: smallReceipt.copyWith(fontSize: 9, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  final bool dashed;
  const _Separator({this.dashed = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        dashed
            ? '- - - - - - - - - - - - - - - - - -'
            : '================================',
        style: const TextStyle(
            fontFamily: 'Courier New', fontSize: 11, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final TicketItem item;
  final TextStyle receiptFont;
  final TextStyle boldFont;

  const _ItemRow(
      {required this.item, required this.receiptFont, required this.boldFont});

  @override
  Widget build(BuildContext context) {
    final colorTalla = [
      if (item.color != null) item.color!,
      if (item.talla != null)
        'T.${item.talla! % 1 == 0 ? item.talla!.toInt() : item.talla}',
    ].join('  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${item.nombre.toUpperCase()}${item.modelo.isNotEmpty ? '  ${item.modelo}' : ''}',
          style: boldFont,
          textAlign: TextAlign.center,
        ),
        if (colorTalla.isNotEmpty)
          Text(colorTalla,
              style: receiptFont.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${item.cantidad} × \$${formatPrice(item.precioUnitario)}',
                style: receiptFont),
            Text('\$${formatPrice(item.subtotal)}',
                style: boldFont.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle style;
  final Color? color;

  const _PayRow(this.label, this.value, this.style, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('  $label', style: style),
          Text(value,
              style: color != null ? style.copyWith(color: color) : style),
        ],
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatefulWidget {
  final TicketData ticket;

  const _BottomBar({required this.ticket});

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  String? _clienteNombre;

  Future<void> _onPrint() async {
    final nombre = await showDialog<String?>(
      context: context,
      builder: (ctx) => _CustomerNameDialog(initialValue: _clienteNombre),
    );
    // null = dialog descartado (back/tap fuera) → mantener nombre anterior
    // '' = usuario limpió el campo y confirmó → borrar nombre
    if (nombre != null) {
      setState(() => _clienteNombre = nombre.trim().isEmpty ? null : nombre.trim());
    }
    if (!mounted) return;
    final ticketFinal = widget.ticket.copyWith(clienteNombre: _clienteNombre);
    TicketPrintService.showPrinterPicker(context, ticketFinal);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Listo'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Imprimir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _onPrint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer name dialog ──────────────────────────────────────────────────────

class _CustomerNameDialog extends StatefulWidget {
  final String? initialValue;
  const _CustomerNameDialog({this.initialValue});

  @override
  State<_CustomerNameDialog> createState() => _CustomerNameDialogState();
}

class _CustomerNameDialogState extends State<_CustomerNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nombre del cliente'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Nombre y apellido (opcional)',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Omitir'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
