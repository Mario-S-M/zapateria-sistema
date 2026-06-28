import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapateria_flutter/config/business_config.dart';
import 'package:zapateria_flutter/models/ticket_data.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class TicketPrintService {
  TicketPrintService._();

  static final BluetoothPrint _bt = BluetoothPrint.instance;

  static Future<void> showPrinterPicker(
      BuildContext context, TicketData ticket) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impresión Bluetooth no disponible en web')),
      );
      return;
    }

    final granted = await _requestPermissions();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permisos Bluetooth requeridos para imprimir')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _PrinterPickerSheet(ticket: ticket),
    );
  }

  static Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values
          .every((s) => s.isGranted || s.isLimited || s.isPermanentlyDenied == false);
    }

    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted || status.isLimited;
    }

    return false;
  }

  static List<LineText> _buildLines(TicketData ticket) {
    final lines = <LineText>[];
    final dateStr =
        DateFormat('dd/MM/yyyy  HH:mm', 'es_MX').format(ticket.fecha);
    const sep = '================================';
    const dashedSep = '--------------------------------';

    // weight: 0 = normal, 1 = bold (no named constants in v4.3.0)
    void addText(String content,
        {int align = LineText.ALIGN_LEFT, int weight = 0, int feed = 1}) {
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: content,
        align: align,
        weight: weight,
        linefeed: feed,
      ));
    }

    // ── Header ─────────────────────────────────────────────
    addText(sep, align: LineText.ALIGN_CENTER);
    addText(kBusinessName, align: LineText.ALIGN_CENTER, weight: 1);
    addText(kBusinessAddr1, align: LineText.ALIGN_CENTER);
    addText(kBusinessAddr2, align: LineText.ALIGN_CENTER);
    addText('RFC: $kBusinessRFC', align: LineText.ALIGN_CENTER);
    addText(sep, align: LineText.ALIGN_CENTER);

    // ── Folio + Fecha ───────────────────────────────────────
    addText('TICKET: ${ticket.folio}');
    addText('Fecha:  $dateStr');
    addText(dashedSep);

    // ── Items ───────────────────────────────────────────────
    for (final item in ticket.items) {
      final title = item.nombre.toUpperCase();
      final modelo = item.modelo.isNotEmpty ? '  mod. ${item.modelo}' : '';
      addText('$title$modelo', weight: 1);

      final colorTalla = [
        if (item.color != null) item.color!,
        if (item.talla != null)
          'T.${item.talla! % 1 == 0 ? item.talla!.toInt() : item.talla}',
      ].join('  ');
      if (colorTalla.isNotEmpty) addText('  $colorTalla');

      final cantPrecio =
          '  ${item.cantidad} x \$${formatPrice(item.precioUnitario)}';
      final sub = '\$${formatPrice(item.subtotal)}';
      final spaces = 32 - cantPrecio.length - sub.length;
      addText('$cantPrecio${' ' * (spaces > 0 ? spaces : 1)}$sub');
    }

    // ── Total ───────────────────────────────────────────────
    addText(dashedSep);
    final totalStr = '\$${formatPrice(ticket.total)}';
    const totalLabel = 'TOTAL:';
    final totalSpaces = 32 - totalLabel.length - totalStr.length;
    addText(
      '$totalLabel${' ' * (totalSpaces > 0 ? totalSpaces : 1)}$totalStr',
      weight: 1,
    );

    // ── Pago ────────────────────────────────────────────────
    addText(dashedSep);
    addText('Pago: ${ticket.metodoPago}');
    if (ticket.montoTarjeta != null && ticket.montoTarjeta! > 0) {
      addText('  Tarjeta:   \$${formatPrice(ticket.montoTarjeta!)}');
    }
    if (ticket.montoRecibido != null && ticket.montoRecibido! > 0) {
      addText('  Recibido:  \$${formatPrice(ticket.montoRecibido!)}');
    }
    if (ticket.cambio != null && ticket.cambio! >= 0) {
      addText('  Cambio:    \$${formatPrice(ticket.cambio!)}');
    }
    if (ticket.inversionistaNombre != null) {
      addText('Cuenta: ${ticket.inversionistaNombre}');
    }

    // ── Barcode ─────────────────────────────────────────────
    addText(sep, align: LineText.ALIGN_CENTER);
    lines.add(LineText(
      type: LineText.TYPE_BARCODE,
      content: ticket.folio,
      size: 10,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    addText(ticket.folio, align: LineText.ALIGN_CENTER);

    // ── Garantía ────────────────────────────────────────────
    addText(sep, align: LineText.ALIGN_CENTER);
    for (final line in kTicketPolicy) {
      addText(line, align: LineText.ALIGN_CENTER);
    }
    addText(sep, align: LineText.ALIGN_CENTER);
    addText('  Gracias por su compra!  ',
        align: LineText.ALIGN_CENTER, weight: 1);
    // Feed and cut
    addText('', feed: 1);
    addText('', feed: 1);
    addText('', feed: 1);

    return lines;
  }

  static Future<void> _print(BluetoothDevice device, TicketData ticket) async {
    await _bt.connect(device);
    await Future.delayed(const Duration(milliseconds: 600));
    await _bt.printReceipt({}, _buildLines(ticket));
    // Wait for data to be sent to printer before disconnecting
    await Future.delayed(const Duration(seconds: 2));
    await _bt.disconnect();
  }
}

// ── Device picker sheet ───────────────────────────────────────────────────────

class _PrinterPickerSheet extends StatefulWidget {
  final TicketData ticket;
  const _PrinterPickerSheet({required this.ticket});

  @override
  State<_PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends State<_PrinterPickerSheet> {
  final BluetoothPrint _bt = BluetoothPrint.instance;
  String? _printingId;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _bt.startScan(timeout: const Duration(seconds: 6)).then((_) {
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  void dispose() {
    _bt.stopScan();
    super.dispose();
  }

  Future<void> _selectDevice(BluetoothDevice device) async {
    setState(() => _printingId = device.address);
    try {
      await TicketPrintService._print(device, widget.ticket);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ticket impreso correctamente'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _printingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al imprimir: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Icon(Icons.print, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Selecciona impresora',
                        style: theme.textTheme.titleMedium),
                  ),
                  if (_scanning)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<BluetoothDevice>>(
                stream: _bt.scanResults,
                initialData: const [],
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? [];
                  if (devices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_searching,
                              size: 48, color: theme.disabledColor),
                          const SizedBox(height: 12),
                          Text(
                            _scanning
                                ? 'Buscando impresoras...'
                                : 'No se encontraron dispositivos',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (ctx, i) {
                      final dev = devices[i];
                      final isPrinting = _printingId == dev.address;
                      return ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(dev.name ?? 'Dispositivo desconocido'),
                        subtitle: Text(dev.address ?? '',
                            style: theme.textTheme.bodySmall),
                        trailing: isPrinting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _printingId != null ? null : () => _selectDevice(dev),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
