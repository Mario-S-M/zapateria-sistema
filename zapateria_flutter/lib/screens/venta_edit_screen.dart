import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/inversionista_service.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';

class VentaEditScreen extends StatefulWidget {
  final VentaModel venta;

  const VentaEditScreen({super.key, required this.venta});

  @override
  State<VentaEditScreen> createState() => _VentaEditScreenState();
}

class _VentaEditScreenState extends State<VentaEditScreen> {
  late TipoPrecio _tipoPrecio;
  late MetodoPago _metodoPago;
  late String? _inversionistaId;
  late List<_EditableItem> _items;
  final TextEditingController _montoTarjetaCtrl = TextEditingController();

  List<InversionistaModel> _inversionistas = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tipoPrecio = widget.venta.tipoPrecio;
    _metodoPago = widget.venta.metodoPago;
    _inversionistaId = widget.venta.inversionistaId;
    _items = widget.venta.items
        .map((i) => _EditableItem(
              zapatoId: i.zapatoId ?? '',
              zapato: i.zapato,
              cantidad: i.cantidad,
              precioUnitario: i.precioUnitario,
            ))
        .toList();

    if (widget.venta.montoTarjeta > 0 && widget.venta.metodoPago == MetodoPago.mixto) {
      _montoTarjetaCtrl.text = widget.venta.montoTarjeta.toStringAsFixed(2);
    }

    _loadInversionistas();
  }

  @override
  void dispose() {
    _montoTarjetaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInversionistas() async {
    try {
      final list = await inversionistaService.getActivos();
      if (mounted) setState(() => _inversionistas = list);
    } catch (_) {}
  }

  double get _total => _items.fold(0, (s, i) => s + i.precioUnitario * i.cantidad);

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe haber al menos un artículo')));
      return;
    }

    double montoTarjeta = 0;
    if (_metodoPago == MetodoPago.tarjeta) {
      montoTarjeta = _total;
    } else if (_metodoPago == MetodoPago.mixto) {
      montoTarjeta = double.tryParse(_montoTarjetaCtrl.text.replaceAll(',', '.')) ?? 0;
      if (montoTarjeta <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el monto con tarjeta')));
        return;
      }
      if (montoTarjeta >= _total) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para pago total con tarjeta selecciona "Tarjeta"')));
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await ventaService.update(
        widget.venta.id,
        VentaUpdateDto(
          tipoPrecio: _tipoPrecio,
          inversionistaId: _tipoPrecio == TipoPrecio.inversionista ? _inversionistaId : null,
          metodoPago: _metodoPago,
          montoTarjeta: montoTarjeta,
          items: _items
              .map((i) => VentaItemDto(
                    zapatoId: i.zapatoId,
                    cantidad: i.cantidad,
                    precioUnitario: i.precioUnitario,
                  ))
              .toList(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta actualizada')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venta: ${widget.venta.folio}', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(_formatDate(widget.venta.fecha),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tipo precio
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de precio', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<TipoPrecio>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: TipoPrecio.publico, label: Text('Público')),
                    ButtonSegment(value: TipoPrecio.mayorista, label: Text('Mayorista')),
                    ButtonSegment(value: TipoPrecio.inversionista, label: Text('Inversionista')),
                  ],
                  selected: {_tipoPrecio},
                  onSelectionChanged: (s) => setState(() {
                    _tipoPrecio = s.first;
                    if (_tipoPrecio != TipoPrecio.inversionista) _inversionistaId = null;
                  }),
                ),
                if (_tipoPrecio == TipoPrecio.inversionista && _inversionistas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _inversionistaId,
                    decoration: const InputDecoration(
                      labelText: 'Inversionista',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _inversionistas
                        .map((inv) => DropdownMenuItem(value: inv.id, child: Text(inv.nombre)))
                        .toList(),
                    onChanged: (id) => setState(() => _inversionistaId = id),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Método de pago
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Método de pago', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<MetodoPago>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: MetodoPago.efectivo,
                      icon: Icon(Icons.payments_outlined, size: 16),
                      label: Text('Efectivo'),
                    ),
                    ButtonSegment(
                      value: MetodoPago.tarjeta,
                      icon: Icon(Icons.credit_card, size: 16),
                      label: Text('Tarjeta'),
                    ),
                    ButtonSegment(
                      value: MetodoPago.mixto,
                      icon: Icon(Icons.swap_horiz, size: 16),
                      label: Text('Mixto'),
                    ),
                  ],
                  selected: {_metodoPago},
                  onSelectionChanged: (s) => setState(() {
                    _metodoPago = s.first;
                    if (_metodoPago != MetodoPago.mixto) _montoTarjetaCtrl.clear();
                  }),
                ),
                if (_metodoPago == MetodoPago.mixto) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _montoTarjetaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Monto con tarjeta',
                      prefixText: '\$',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: 'Resto en efectivo: \$${formatPrice(_total - (double.tryParse(_montoTarjetaCtrl.text.replaceAll(",", ".")) ?? 0))}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Items
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Artículos (${_items.length})', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((e) => _buildItemCard(e.key, e.value, theme)),
        const SizedBox(height: 16),
        // Total
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleLarge),
                Text('\$${formatPrice(_total)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    if (kIsWeb) {
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Venta')),
      body: body,
    );
  }

  Widget _buildItemCard(int index, _EditableItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ZapatoImage(imageUrl: item.zapato?.foto, height: 44, width: 44, borderRadius: 6),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.zapato?.nombre ?? 'Artículo',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text('\$${formatPrice(item.precioUnitario)} c/u',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      if (item.cantidad > 1) {
                        _items[index] = item.copyWith(cantidad: item.cantidad - 1);
                      } else {
                        _items.removeAt(index);
                      }
                    });
                  },
                ),
                SizedBox(
                  width: 28,
                  child: Text('${item.cantidad}',
                      textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => setState(() {
                    _items[index] = item.copyWith(cantidad: item.cantidad + 1);
                  }),
                ),
              ],
            ),
            Text('\$${formatPrice(item.precioUnitario * item.cantidad)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () => setState(() => _items.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String fecha) {
    try {
      final d = DateTime.parse(fecha).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}

class _EditableItem {
  final String zapatoId;
  final ZapatoModel? zapato;
  final int cantidad;
  final double precioUnitario;

  _EditableItem({
    required this.zapatoId,
    this.zapato,
    required this.cantidad,
    required this.precioUnitario,
  });

  _EditableItem copyWith({int? cantidad, double? precioUnitario}) {
    return _EditableItem(
      zapatoId: zapatoId,
      zapato: zapato,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }
}
