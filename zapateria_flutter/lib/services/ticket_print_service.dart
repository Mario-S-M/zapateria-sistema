import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapateria_flutter/config/business_config.dart';
import 'package:zapateria_flutter/models/ticket_data.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'esc_pos.dart';
import 'web_print_service.dart' if (dart.library.io) 'web_print_service_stub.dart';

class TicketPrintService {
  TicketPrintService._();

  static const _prefAddress = 'lastPrinterAddress';
  static const _prefName = 'lastPrinterName';

  static Future<void> _savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefAddress, device.address);
    await prefs.setString(_prefName, device.name ?? '');
  }

  static Future<({String address, String name})?> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_prefAddress);
    final name = prefs.getString(_prefName);
    if (address == null || address.isEmpty) return null;
    return (address: address, name: name ?? address);
  }

  static Future<void> showPrinterPicker(
      BuildContext context, TicketData ticket) async {
    if (kIsWeb) {
      WebPrintService.printTicketWeb(ticket);
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

    final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (isEnabled != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa Bluetooth para imprimir')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (Platform.isAndroid) {
      final loc = await Permission.locationWhenInUse.status;
      final locSv = await Permission.location.status;
      if (!loc.isGranted && !locSv.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Activa Ubicación en ajustes para encontrar impresoras Bluetooth')),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    final saved = await _loadSavedPrinter();
    if (!context.mounted) return;

    if (saved != null) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => _QuickPrintSheet(
          ticket: ticket,
          printerAddress: saved.address,
          printerName: saved.name,
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => _PrinterPickerSheet(ticket: ticket),
      );
    }
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
        Permission.location,
      ].request();
      return statuses.values
          .every((s) => s.isGranted || s.isLimited);
    }

    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted || status.isLimited;
    }

    return false;
  }

  static List<int> _buildBytes(TicketData ticket) {
    final buf = <int>[];
    final dateStr =
        DateFormat('dd/MM/yyyy  HH:mm', 'es_MX').format(ticket.fecha);
    const sep = '================================';
    const dash = '--------------------------------';

    void addLine(String s, {int align = EscPos.alignLeft, bool bold = false}) {
      buf.addAll(EscPos.setAlign(align));
      buf.addAll(EscPos.setBold(bold));
      buf.addAll(EscPos.textLine(s));
    }

    // Header
    buf.addAll(EscPos.init80());
    addLine(sep, align: EscPos.alignCenter);
    addLine('TICKET DE COMPRA', align: EscPos.alignCenter, bold: true);
    addLine(sep, align: EscPos.alignCenter);
    addLine(kBusinessName, align: EscPos.alignCenter, bold: true);
    addLine(kBusinessAddr1, align: EscPos.alignCenter);
    addLine(kBusinessAddr2, align: EscPos.alignCenter);
    addLine('RFC: $kBusinessRFC', align: EscPos.alignCenter);
    addLine(sep, align: EscPos.alignCenter);

    // Folio + Fecha
    addLine('TICKET: ${ticket.folio}', align: EscPos.alignCenter);
    addLine('Fecha:  $dateStr', align: EscPos.alignCenter);
    if (ticket.clienteNombre != null && ticket.clienteNombre!.isNotEmpty) {
      addLine('Cliente: ${ticket.clienteNombre}', align: EscPos.alignCenter);
    }
    addLine(dash);

    // Items
    for (final item in ticket.items) {
      final title = item.nombre.toUpperCase();
      final modelo = item.modelo.isNotEmpty ? '  mod. ${item.modelo}' : '';
      addLine('$title$modelo', bold: true);

      final colorTalla = [
        if (item.color != null) item.color!,
        if (item.talla != null)
          'T.${item.talla! % 1 == 0 ? item.talla!.toInt() : item.talla}',
      ].join('  ');
      if (colorTalla.isNotEmpty) addLine('  $colorTalla');

      final cantPrecio =
          '  ${item.cantidad} x \$${formatPrice(item.precioUnitario)}';
      final sub = '\$${formatPrice(item.subtotal)}';
      final spaces = 32 - cantPrecio.length - sub.length;
      addLine('$cantPrecio${' ' * (spaces > 0 ? spaces : 1)}$sub');
    }

    // Total
    addLine(dash);
    final totalStr = '\$${formatPrice(ticket.total)}';
    const totalLabel = 'TOTAL:';
    final totalSpaces = 32 - totalLabel.length - totalStr.length;
    addLine(
      '$totalLabel${' ' * (totalSpaces > 0 ? totalSpaces : 1)}$totalStr',
      bold: true,
    );

    // Pago
    addLine(dash);
    addLine('Pago: ${ticket.metodoPago}');
    if (ticket.montoTarjeta != null && ticket.montoTarjeta! > 0) {
      addLine('  Tarjeta:   \$${formatPrice(ticket.montoTarjeta!)}');
    }
    if (ticket.montoRecibido != null && ticket.montoRecibido! > 0) {
      addLine('  Recibido:  \$${formatPrice(ticket.montoRecibido!)}');
    }
    if (ticket.cambio != null && ticket.cambio! >= 0) {
      addLine('  Cambio:    \$${formatPrice(ticket.cambio!)}');
    }
    if (ticket.inversionistaNombre != null) {
      addLine('Cuenta: ${ticket.inversionistaNombre}');
    }

    // Barcode
    addLine(sep, align: EscPos.alignCenter);
    buf.addAll(EscPos.setAlign(EscPos.alignCenter));
    buf.addAll(EscPos.barcode(ticket.folio));

    // Garantía
    addLine(sep, align: EscPos.alignCenter);
    for (final line in kTicketPolicy) {
      addLine(line, align: EscPos.alignCenter);
    }
    addLine(sep, align: EscPos.alignCenter);
    addLine('  Gracias por su compra!  ',
        align: EscPos.alignCenter, bold: true);
    addLine(sep, align: EscPos.alignCenter);
    addLine('* No es comprobante fiscal', align: EscPos.alignCenter);
    addLine('  ni documento legal.', align: EscPos.alignCenter);

    // Feed and cut
    buf.addAll(EscPos.feed(4));
    buf.addAll(EscPos.cut());

    return buf;
  }

  static Future<void> _printTicketBytes(
      BluetoothDevice device, TicketData ticket) async {
    final connection =
        await BluetoothConnection.toAddress(device.address);
    try {
      final bytes = Uint8List.fromList(_buildBytes(ticket));
      connection.output.add(bytes);
      await connection.output.allSent.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } finally {
      try {
        await connection.close().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }
}

class _PrinterPickerSheet extends StatefulWidget {
  final TicketData ticket;
  const _PrinterPickerSheet({required this.ticket});

  @override
  State<_PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends State<_PrinterPickerSheet> {
  final List<BluetoothDevice> _devices = [];
  String? _printingId;
  bool _scanning = true;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() async {
    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      if (mounted) {
        setState(() {
          for (final d in bonded) {
            if (d.name != null &&
                !_devices.any((x) => x.address == d.address)) {
              _devices.add(d);
            }
          }
        });
      }
    } catch (_) {
      // Ignore errors loading bonded devices
    }

    _discoverySub = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((r) {
      if (!mounted) return;
      final d = r.device;
      if (d.name != null &&
          !_devices.any((x) => x.address == d.address)) {
        setState(() => _devices.add(d));
      }
    }, onError: (e) {
      if (mounted) setState(() => _scanning = false);
    }, onDone: () {
      if (mounted) setState(() => _scanning = false);
    });

    Future.delayed(const Duration(seconds: 6), () {
      FlutterBluetoothSerial.instance.cancelDiscovery();
    });
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    FlutterBluetoothSerial.instance.cancelDiscovery();
    super.dispose();
  }

  Future<void> _selectDevice(BluetoothDevice device) async {
    setState(() => _printingId = device.address);
    try {
      await TicketPrintService._printTicketBytes(device, widget.ticket);
      await TicketPrintService._savePrinter(device);
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
              child: _devices.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (ctx, i) {
                        final dev = _devices[i];
                        final isPrinting = _printingId == dev.address;
                        return ListTile(
                          leading: const Icon(Icons.print),
                          title: Text(dev.name ?? 'Dispositivo desconocido'),
                          subtitle: Text(dev.address,
                              style: theme.textTheme.bodySmall),
                          trailing: isPrinting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _printingId != null
                              ? null
                              : () => _selectDevice(dev),
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

// ── Quick print sheet (impresora favorita guardada) ───────────────────────────

class _QuickPrintSheet extends StatefulWidget {
  final TicketData ticket;
  final String printerAddress;
  final String printerName;

  const _QuickPrintSheet({
    required this.ticket,
    required this.printerAddress,
    required this.printerName,
  });

  @override
  State<_QuickPrintSheet> createState() => _QuickPrintSheetState();
}

class _QuickPrintSheetState extends State<_QuickPrintSheet> {
  bool _printing = false;

  Future<void> _printNow() async {
    setState(() => _printing = true);
    final device = BluetoothDevice(
      address: widget.printerAddress,
      name: widget.printerName,
    );
    try {
      await TicketPrintService._printTicketBytes(device, widget.ticket);
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
        setState(() => _printing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo conectar: $e')),
        );
        // Si falla, abre el picker completo para que elija otra
        Navigator.pop(context);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (ctx) => _PrinterPickerSheet(ticket: widget.ticket),
        );
      }
    }
  }

  Future<void> _changePrinter() async {
    Navigator.pop(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _PrinterPickerSheet(ticket: widget.ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.print, size: 22),
                const SizedBox(width: 8),
                Text('Imprimir ticket', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _printing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print),
                label: Text(
                  _printing ? 'Imprimiendo...' : 'Imprimir con ${widget.printerName}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _printing ? null : _printNow,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Cambiar impresora'),
              onPressed: _printing ? null : _changePrinter,
            ),
          ],
        ),
      ),
    );
  }
}
