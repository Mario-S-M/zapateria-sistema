import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/services/inventario_service.dart';
import 'package:zapateria_flutter/components/color_circle.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  String? _lastCode;

  Future<void> _scan() async {
    if (_isProcessing) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir escáner: $e')),
        );
      }
      return;
    }

    if (result.type == ResultType.Cancelled) return;
    if (result.type == ResultType.Error || result.rawContent.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo leer el código')));
      return;
    }

    setState(() { _isProcessing = true; _lastCode = result.rawContent; });

    try {
      final zapato = await zapatoService.getByCodigoBarras(result.rawContent);
      final inventario = await inventarioService.getByZapato(zapato.id);
      if (!mounted) return;
      await _showAddToCartDialog(zapato, inventario);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('SocketException') || e.toString().contains('Connection')
            ? 'Error de red: verifica que el servidor esté encendido'
            : 'Zapato no encontrado: ${result.rawContent}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showAddToCartDialog(ZapatoModel zapato, List<InventarioItemModel> inventario) async {
    final cart = context.read<CartProvider>();
    final tipo = cart.tipoPrecio;

    final coloresConStock = <String, String>{};
    for (final item in inventario) {
      if (item.cantidad > 0 && item.colorId != null && item.color != null) {
        coloresConStock[item.colorId!] = item.color!.nombre;
      }
    }

    String? selectedColorId = coloresConStock.isNotEmpty ? coloresConStock.keys.first : null;
    double? selectedTalla;

    List<InventarioItemModel> tallasPara(String? colorId) {
      return inventario
          .where((i) => i.colorId == colorId && i.cantidad > 0)
          .toList()
        ..sort((a, b) => a.talla.compareTo(b.talla));
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final tallasDisp = tallasPara(selectedColorId);
          if (selectedTalla == null && tallasDisp.isNotEmpty) {
            selectedTalla = tallasDisp.first.talla;
          }

          double precio;
          final tallaForPrice = selectedTalla ?? zapato.medidaInicio.toDouble();
          switch (tipo) {
            case TipoPrecio.publico:
              precio = zapato.getPrecioPublicoForTalla(tallaForPrice);
              break;
            case TipoPrecio.mayorista:
              precio = zapato.getPrecioCompraForTalla(tallaForPrice) * 1.3;
              break;
            case TipoPrecio.inversionista:
              precio = zapato.getPrecioCompraForTalla(tallaForPrice) * 1.2;
              break;
          }

          return AlertDialog(
            title: Text(zapato.nombre),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zapato.modelo, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (coloresConStock.isNotEmpty) ...[
                    const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: coloresConStock.entries.map((e) {
                        final zc = zapato.colores.firstWhere(
                          (c) => c.colorId == e.key,
                          orElse: () => zapato.colores.first,
                        );
                        final isSelected = selectedColorId == e.key;
                        return GestureDetector(
                          onTap: () => setModal(() { selectedColorId = e.key; selectedTalla = null; }),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Theme.of(ctx).colorScheme.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: ColorCircle(color: zc.color, size: 36),
                              ),
                              Text(e.value, style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (tallasDisp.isNotEmpty) ...[
                    const Text('Talla:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tallasDisp.map((item) {
                        final t = item.talla;
                        final label = t % 1 == 0 ? t.toInt().toString() : t.toString();
                        return ChoiceChip(
                          label: Text(label),
                          selected: selectedTalla == t,
                          onSelected: (_) => setModal(() => selectedTalla = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (tallasDisp.isEmpty && inventario.isNotEmpty)
                    const Text('Sin stock disponible para este color',
                        style: TextStyle(color: Colors.orange)),
                  Text('\$${formatPrice(precio)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: (selectedTalla == null && inventario.isNotEmpty) ? null : () {
                  final tallaForAdd = selectedTalla ?? zapato.medidaInicio.toDouble();
                  double precioFinal;
                  switch (tipo) {
                    case TipoPrecio.publico:
                      precioFinal = zapato.getPrecioPublicoForTalla(tallaForAdd);
                      break;
                    case TipoPrecio.mayorista:
                      precioFinal = zapato.getPrecioCompraForTalla(tallaForAdd) * 1.3;
                      break;
                    case TipoPrecio.inversionista:
                      precioFinal = zapato.getPrecioCompraForTalla(tallaForAdd) * 1.2;
                      break;
                  }
                  final colorNombre = selectedColorId != null ? coloresConStock[selectedColorId] : null;
                  cart.addItem(zapato, 1, precioFinal,
                      colorId: selectedColorId, colorNombre: colorNombre, talla: selectedTalla);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${zapato.nombre} agregado al carrito')),
                  );
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner de código de barras')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 100, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 24),
            Text(
              _isProcessing
                  ? 'Buscando zapato...'
                  : _lastCode != null
                      ? 'Último código: $_lastCode'
                      : 'Toca el botón para escanear',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _isProcessing
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Escanear código'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
