import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/services/inventario_service.dart';
import 'package:zapateria_flutter/utils/talla_converter.dart';

class _ScanEvent {
  final double talla;
  final int deltaApplied;
  final int cantidadResultante;

  _ScanEvent({
    required this.talla,
    required this.deltaApplied,
    required this.cantidadResultante,
  });
}

class ScanInventarioScreen extends StatefulWidget {
  final ZapatoModel zapato;
  final String? colorId;
  final String? colorNombre;

  const ScanInventarioScreen({
    super.key,
    required this.zapato,
    this.colorId,
    this.colorNombre,
  });

  @override
  State<ScanInventarioScreen> createState() => _ScanInventarioScreenState();
}

class _ScanInventarioScreenState extends State<ScanInventarioScreen> {
  bool _scanning = false;
  bool _dirty = false;
  final Map<double, int> _tally = {};
  final List<_ScanEvent> _history = [];

  void _toast(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _scanOnce() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    ScanResult result;
    try {
      result = await BarcodeScanner.scan(
        options: const ScanOptions(
          restrictFormat: [],
          useCamera: -1,
          autoEnableFlash: false,
          android: AndroidOptions(aspectTolerance: 0.00, useAutoFocus: true),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _scanning = false);
      _toast('Error al abrir escáner: $e');
      return;
    }

    if (result.type == ResultType.Cancelled) {
      if (mounted) setState(() => _scanning = false);
      return;
    }
    if (result.type == ResultType.Error || result.rawContent.isEmpty) {
      if (mounted) setState(() => _scanning = false);
      _toast('No se pudo leer el código');
      return;
    }

    final huboExito = await _handleScannedCode(result.rawContent);
    if (mounted) setState(() => _scanning = false);

    if (huboExito) {
      // Solo en el camino exitoso reabrimos la cámara automáticamente para
      // el siguiente par. En cualquier otro caso el vendedor debe leer el
      // aviso y tocar "Escanear" de nuevo.
      _scanOnce();
    }
  }

  Future<bool> _handleScannedCode(String codigo) async {
    ZapatoEscaneoResult resultado;
    try {
      resultado = await zapatoService.escanear(codigo);
    } catch (e) {
      final notFound = e.toString().contains('404');
      _toast(notFound
          ? 'Código no reconocido: $codigo'
          : 'Error de red al buscar el código — no se registró. Intenta de nuevo.');
      return false;
    }

    if (resultado.zapato.id != widget.zapato.id) {
      _toast('Este código pertenece a "${resultado.zapato.nombre}", '
          'no a "${widget.zapato.nombre}". Escaneo ignorado.');
      return false;
    }

    if (resultado.tallaDetectada == null) {
      _toast('No se detectó una talla en este código. Escaneo ignorado.');
      return false;
    }

    final talla = resultado.tallaDetectada!;
    try {
      final item = await inventarioService.increment(
        zapatoId: widget.zapato.id,
        colorId: widget.colorId,
        talla: talla,
        delta: 1,
      );
      setState(() {
        _tally[talla] = (_tally[talla] ?? 0) + 1;
        _history.add(_ScanEvent(
          talla: talla,
          deltaApplied: 1,
          cantidadResultante: item.cantidad,
        ));
        _dirty = true;
      });
      _toast('Talla ${formatTalla(talla)}: +1 (total ${item.cantidad})', success: true);
      return true;
    } catch (e) {
      _toast('No se pudo registrar el escaneo (error de red). Intenta de nuevo.');
      return false;
    }
  }

  Future<void> _undoLast() async {
    if (_history.isEmpty) return;
    final last = _history.last;
    try {
      await inventarioService.increment(
        zapatoId: widget.zapato.id,
        colorId: widget.colorId,
        talla: last.talla,
        delta: -last.deltaApplied,
      );
      setState(() {
        _tally[last.talla] = (_tally[last.talla] ?? 1) - 1;
        _history.removeLast();
      });
      _toast('Último escaneo deshecho (talla ${formatTalla(last.talla)})');
    } catch (e) {
      _toast('No se pudo deshacer: error de red. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tallasEscaneadas = _tally.keys.where((t) => _tally[t]! > 0).toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escaneando', style: TextStyle(fontSize: 18)),
            Text(
              widget.colorNombre != null
                  ? '${widget.zapato.nombre} — ${widget.colorNombre}'
                  : widget.zapato.nombre,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _dirty),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.qr_code_scanner, size: 72,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text(
                  _scanning ? 'Escaneando...' : 'Toca para escanear la siguiente caja',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _scanning
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: _scanOnce,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Escanear'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                      ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _history.isEmpty ? null : _undoLast,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Deshacer último escaneo'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tallasEscaneadas.isEmpty
                ? Center(
                    child: Text('Aún no has escaneado nada en esta sesión',
                        style: theme.textTheme.bodySmall),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tallasEscaneadas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (ctx, i) {
                      final t = tallasEscaneadas[i];
                      final eq = equivalencias(t);
                      final ultimo = _history.lastWhere((h) => h.talla == t);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text('+${_tally[t]}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('MX ${formatTalla(eq.mx)}'),
                        subtitle: Text('EU ${formatTalla(eq.eu)} · US ${formatTalla(eq.us)}'),
                        trailing: Text('Total: ${ultimo.cantidadResultante}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
