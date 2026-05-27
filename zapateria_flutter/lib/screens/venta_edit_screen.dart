import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class VentaEditScreen extends StatelessWidget {
  final VentaModel venta;

  const VentaEditScreen({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Venta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Venta: ${venta.folio}', style: theme.textTheme.headlineSmall),
                  const Divider(),
                  _detailRow(theme, 'Fecha', _formatDate(venta.fecha)),
                  _detailRow(theme, 'Tipo', venta.tipoPrecioString),
                  if (venta.inversionista != null) _detailRow(theme, 'Inversionista', venta.inversionista!.nombre),
                  _detailRow(theme, 'Total', '\$${formatPrice(venta.total)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...venta.items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  title: Text(item.zapato?.nombre ?? 'Sin zapato'),
                  subtitle: Text('${item.cantidad} x \$${formatPrice(item.precioUnitario)}'),
                  trailing: Text('\$${formatPrice(item.subtotal)}'),
                ),
              )),
        ],
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

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
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
