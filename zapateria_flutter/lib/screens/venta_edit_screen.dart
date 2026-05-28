import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class VentaEditScreen extends StatelessWidget {
  final VentaModel venta;

  const VentaEditScreen({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venta: ${venta.folio}', style: theme.textTheme.headlineSmall),
                const Divider(height: 24),
                _detailRow(theme, 'Fecha', _formatDate(venta.fecha)),
                _detailRow(theme, 'Tipo', venta.tipoPrecioString),
                if (venta.inversionista != null)
                  _detailRow(theme, 'Inversionista', venta.inversionista!.nombre),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleLarge),
                    Text(
                      '\$${formatPrice(venta.total)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Items (${venta.items.length})', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (kIsWeb)
          _buildWebItemsTable(theme)
        else
          ..._buildMobileItems(theme),
      ],
    );

    if (kIsWeb) {
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Venta')),
      body: body,
    );
  }

  Widget _buildWebItemsTable(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Producto', style: theme.textTheme.labelLarge)),
                Expanded(child: Text('Cant.', style: theme.textTheme.labelLarge, textAlign: TextAlign.center)),
                Expanded(child: Text('Precio unit.', style: theme.textTheme.labelLarge, textAlign: TextAlign.end)),
                Expanded(child: Text('Subtotal', style: theme.textTheme.labelLarge, textAlign: TextAlign.end)),
              ],
            ),
          ),
          ...venta.items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(item.zapato?.nombre ?? 'Sin zapato', style: theme.textTheme.bodyMedium)),
                Expanded(child: Text('${item.cantidad}', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                Expanded(child: Text('\$${formatPrice(item.precioUnitario)}', textAlign: TextAlign.end, style: theme.textTheme.bodyMedium)),
                Expanded(child: Text('\$${formatPrice(item.subtotal)}', textAlign: TextAlign.end, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Widget> _buildMobileItems(ThemeData theme) {
    return venta.items.map((item) => Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        title: Text(item.zapato?.nombre ?? 'Sin zapato'),
        subtitle: Text('${item.cantidad} x \$${formatPrice(item.precioUnitario)}'),
        trailing: Text('\$${formatPrice(item.subtotal)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
    )).toList();
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
      case TipoPrecio.publico: return 'PÚBLICO';
      case TipoPrecio.mayorista: return 'MAYORISTA';
      case TipoPrecio.inversionista: return 'INVERSIONISTA';
    }
  }
}
