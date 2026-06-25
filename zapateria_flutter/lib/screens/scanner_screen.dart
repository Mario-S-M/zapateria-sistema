import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
      BarcodeFormat.pdf417,
    ],
  );

  bool _isProcessing = false;
  MobileScannerState? _scannerState;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() => _scannerState = controller.value);
  }

  @override
  void dispose() {
    controller.removeListener(_onStateChange);
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final zapato = await zapatoService.getByCodigoBarras(code);
      final inventario = await inventarioService.getByZapato(zapato.id);

      if (!mounted) return;

      await _showAddToCartDialog(zapato, inventario);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zapato no encontrado')),
        );
      }
    }

    if (mounted) setState(() => _isProcessing = false);
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
                          onTap: () => setModal(() {
                            selectedColorId = e.key;
                            selectedTalla = null;
                          }),
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
                        final isSelected = selectedTalla == t;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
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
                  cart.addItem(
                    zapato,
                    1,
                    precioFinal,
                    colorId: selectedColorId,
                    colorNombre: colorNombre,
                    talla: selectedTalla,
                  );
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
    final state = _scannerState;
    if (state != null && state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Escáner')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudo acceder a la cámara.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => controller.start(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Escáner de código de barras')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!_isProcessing) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null) _handleScan(code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _isProcessing ? 'Procesando...' : 'Escanea el código de barras',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async => controller.toggleTorch(),
        icon: const Icon(Icons.flash_on),
        label: const Text('Torch'),
      ),
    );
  }
}
