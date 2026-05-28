import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:zapateria_flutter/screens/venta_edit_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List<VentaModel> _ventas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  Future<void> _loadVentas() async {
    setState(() => _loading = true);
    try {
      _ventas = await ventaService.getAll();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteVenta(VentaModel venta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Venta'),
        content: Text('¿Eliminar la venta ${venta.folio}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ventaService.delete(venta.id);
        if (mounted) _loadVentas();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _editVenta(BuildContext context, VentaModel venta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VentaEditScreen(venta: venta)),
    ).then((_) => _loadVentas());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_ventas.isEmpty) {
      body = Center(child: Text('No hay ventas registradas', style: theme.textTheme.bodyLarge));
    } else if (kIsWeb) {
      body = _buildWebTable(theme);
    } else {
      body = _buildMobileList(theme);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: kIsWeb
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: body,
              ),
            )
          : body,
    );
  }

  Widget _buildWebTable(ThemeData theme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Folio', style: theme.textTheme.labelLarge)),
              Expanded(flex: 2, child: Text('Fecha', style: theme.textTheme.labelLarge)),
              Expanded(flex: 2, child: Text('Tipo', style: theme.textTheme.labelLarge)),
              Expanded(flex: 2, child: Text('Inversionista', style: theme.textTheme.labelLarge)),
              Expanded(child: Text('Items', style: theme.textTheme.labelLarge, textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Total', style: theme.textTheme.labelLarge, textAlign: TextAlign.end)),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadVentas,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: _ventas.length,
              itemBuilder: (context, index) {
                final venta = _ventas[index];
                return Container(
                  decoration: BoxDecoration(
                    color: index.isEven ? theme.cardColor : theme.colorScheme.surface,
                    border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
                  ),
                  child: InkWell(
                    onTap: () => _editVenta(context, venta),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(venta.folio, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                          Expanded(flex: 2, child: Text(_formatDate(venta.fecha), style: theme.textTheme.bodyMedium)),
                          Expanded(flex: 2, child: _TipoBadge(tipo: venta.tipoPrecioString)),
                          Expanded(flex: 2, child: Text(venta.inversionista?.nombre ?? '—', style: theme.textTheme.bodyMedium)),
                          Expanded(child: Text('${venta.items.length}', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                          Expanded(flex: 2, child: Text('\$${formatPrice(venta.total)}', textAlign: TextAlign.end, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold))),
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => _deleteVenta(venta),
                              tooltip: 'Eliminar',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadVentas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ventas.length,
        itemBuilder: (context, index) {
          final venta = _ventas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(venta.folio, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  Text('Fecha: ${_formatDate(venta.fecha)}', style: theme.textTheme.bodySmall),
                  Text('Tipo: ${venta.tipoPrecioString}', style: theme.textTheme.bodySmall),
                  if (venta.inversionista != null)
                    Text('Inversionista: ${venta.inversionista!.nombre}', style: theme.textTheme.bodySmall),
                  Text('Items: ${venta.items.length}', style: theme.textTheme.bodySmall),
                ],
              ),
              trailing: Text('\$${formatPrice(venta.total)}', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              onTap: () => _editVenta(context, venta),
              onLongPress: () => _deleteVenta(venta),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return fecha;
    }
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'PÚBLICO': Colors.blue,
      'MAYORISTA': Colors.orange,
      'INVERSIONISTA': Colors.purple,
    };
    final color = colors[tipo] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(tipo, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

extension on VentaModel {
  String get tipoPrecioString {
    switch (tipoPrecio) {
      case TipoPrecio.publico: return 'PÚBLICO';
      case TipoPrecio.mayorista: return 'MAYORISTA';
      case TipoPrecio.inversionista: return 'INVERSIONISTA';
    }
  }
}
