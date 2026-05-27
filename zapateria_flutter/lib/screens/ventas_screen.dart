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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ventas.isEmpty
              ? Center(child: Text('No hay ventas registradas', style: theme.textTheme.bodyLarge))
              : RefreshIndicator(
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

  void _editVenta(BuildContext context, VentaModel venta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VentaEditScreen(venta: venta)),
    ).then((_) => _loadVentas());
  }
}

extension on VentaModel {
  String get tipoPrecioString {
    switch (tipoPrecio) {
      case TipoPrecio.publico:
        return 'PÚBLICO';
      case TipoPrecio.mayorista:
        return 'MAYORISTA';
      case TipoPrecio.inversionista:
        return 'INVERSIONISTA';
    }
  }
}
