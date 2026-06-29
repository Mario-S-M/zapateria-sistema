import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/models/ticket_data.dart';
import 'package:zapateria_flutter/screens/ticket_screen.dart';
import 'package:zapateria_flutter/screens/venta_edit_screen.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

// ── Payment method helpers ────────────────────────────────────────────────────

String _metodoPagoLabel(MetodoPago mp) {
  switch (mp) {
    case MetodoPago.efectivo: return 'EFECTIVO';
    case MetodoPago.tarjeta:  return 'TARJETA';
    case MetodoPago.mixto:    return 'MIXTO';
  }
}

MaterialColor _metodoPagoColor(MetodoPago mp) {
  switch (mp) {
    case MetodoPago.efectivo: return Colors.green;
    case MetodoPago.tarjeta:  return Colors.blue;
    case MetodoPago.mixto:    return Colors.orange;
  }
}

IconData _metodoPagoIcon(MetodoPago mp) {
  switch (mp) {
    case MetodoPago.efectivo: return Icons.payments_outlined;
    case MetodoPago.tarjeta:  return Icons.credit_card;
    case MetodoPago.mixto:    return Icons.swap_horiz;
  }
}

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

  void _editVenta(BuildContext context, VentaModel venta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VentaEditScreen(venta: venta)),
    ).then((_) => _loadVentas());
  }

  void _printVenta(BuildContext context, VentaModel venta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketScreen(ticket: _ticketFromVenta(venta))),
    );
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
      body = _buildWebList(theme);
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

  Widget _buildWebList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadVentas,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: _ventas.length,
        itemBuilder: (context, index) {
          final venta = _ventas[index];
          return _VentaAccordion(
            venta: venta,
            isWeb: true,
            onEdit: () => _editVenta(context, venta),
            onPrint: () => _printVenta(context, venta),
          );
        },
      ),
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadVentas,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _ventas.length,
        itemBuilder: (context, index) {
          final venta = _ventas[index];
          return _VentaAccordion(
            venta: venta,
            isWeb: false,
            onEdit: () => _editVenta(context, venta),
            onPrint: () => _printVenta(context, venta),
          );
        },
      ),
    );
  }
}

// ── Acordeón principal ────────────────────────────────────────────────────────

class _VentaAccordion extends StatelessWidget {
  final VentaModel venta;
  final bool isWeb;
  final VoidCallback onEdit;
  final VoidCallback onPrint;

  const _VentaAccordion({
    required this.venta,
    required this.isWeb,
    required this.onEdit,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMultipleItems = venta.items.length > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ],
        ),
        title: isWeb ? _WebTitle(venta: venta) : _MobileTitle(venta: venta),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMultipleItems)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${venta.items.length} art.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 18),
              onPressed: onPrint,
              tooltip: 'Reimprimir ticket',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              tooltip: 'Editar',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
        children: [
          const Divider(height: 1),
          _ItemsExpandedList(venta: venta, isWeb: isWeb),
        ],
      ),
    );
  }
}

// ── Título web ────────────────────────────────────────────────────────────────

class _WebTitle extends StatelessWidget {
  final VentaModel venta;
  const _WebTitle({required this.venta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            venta.folio,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(_formatDate(venta.fecha), style: theme.textTheme.bodySmall),
        ),
        Expanded(
          flex: 2,
          child: _TipoBadge(tipo: venta.tipoPrecioString),
        ),
        Expanded(
          flex: 3,
          child: _MetodoPagoBadge(venta: venta),
        ),
        if (venta.inversionista != null)
          Expanded(
            flex: 2,
            child: Text(
              venta.inversionista!.nombre,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Expanded(flex: 2, child: SizedBox()),
        Expanded(
          flex: 2,
          child: Text(
            '\$${formatPrice(venta.total)}',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Título móvil ──────────────────────────────────────────────────────────────

class _MobileTitle extends StatelessWidget {
  final VentaModel venta;
  const _MobileTitle({required this.venta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(venta.folio, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(_formatDate(venta.fecha), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(width: 6),
            _TipoBadge(tipo: venta.tipoPrecioString),
          ],
        ),
        const SizedBox(height: 3),
        _MetodoPagoBadge(venta: venta),
      ],
    );
  }
}

// ── Lista de ítems expandida ──────────────────────────────────────────────────

class _ItemsExpandedList extends StatelessWidget {
  final VentaModel venta;
  final bool isWeb;

  const _ItemsExpandedList({required this.venta, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = venta.items;

    return Container(
      color: theme.colorScheme.surfaceContainerLowest ?? theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(width: isWeb ? 48 : 40),
                Expanded(
                  flex: 4,
                  child: Text('Artículo', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                ),
                SizedBox(
                  width: 48,
                  child: Text('Cant.', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor), textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: isWeb ? 90 : 72,
                  child: Text('Precio', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor), textAlign: TextAlign.end),
                ),
                SizedBox(
                  width: isWeb ? 90 : 72,
                  child: Text('Subtotal', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor), textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...items.map((item) => _ItemRow(item: item, isWeb: isWeb)),
          // Payment breakdown footer
          _PaymentBreakdown(venta: venta),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final VentaItemModel item;
  final bool isWeb;

  const _ItemRow({required this.item, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imgSize = isWeb ? 40.0 : 34.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          ZapatoImage(
            imageUrl: item.zapato?.foto,
            height: imgSize,
            width: imgSize,
            borderRadius: 6,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.zapato?.nombre ?? 'Artículo',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.zapato?.modelo != null)
                  Text(
                    item.zapato!.modelo,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${item.cantidad}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: isWeb ? 90 : 72,
            child: Text(
              '\$${formatPrice(item.precioUnitario)}',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: isWeb ? 90 : 72,
            child: Text(
              '\$${formatPrice(item.subtotal)}',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Método de pago badge ──────────────────────────────────────────────────────

class _MetodoPagoBadge extends StatelessWidget {
  final VentaModel venta;
  const _MetodoPagoBadge({required this.venta});

  @override
  Widget build(BuildContext context) {
    final mp = venta.metodoPago;
    final color = _metodoPagoColor(mp);
    final icon = _metodoPagoIcon(mp);
    final label = _metodoPagoLabel(mp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color.shade700),
              const SizedBox(width: 3),
              Text(label,
                  style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (mp == MetodoPago.mixto) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card, size: 10, color: Colors.blue.shade600),
              const SizedBox(width: 2),
              Text('\$${formatPrice(venta.montoTarjeta)}',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
              const SizedBox(width: 5),
              Icon(Icons.payments_outlined, size: 10, color: Colors.green.shade600),
              const SizedBox(width: 2),
              Text('\$${formatPrice(venta.total - venta.montoTarjeta)}',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade600)),
            ],
          ),
        ] else if (mp == MetodoPago.tarjeta) ...[
          const SizedBox(height: 2),
          Text('\$${formatPrice(venta.montoTarjeta)}',
              style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
        ],
      ],
    );
  }
}

// ── Payment breakdown footer (inside expanded accordion) ──────────────────────

class _PaymentBreakdown extends StatelessWidget {
  final VentaModel venta;
  const _PaymentBreakdown({required this.venta});

  @override
  Widget build(BuildContext context) {
    final mp = venta.metodoPago;
    final color = _metodoPagoColor(mp);
    final theme = Theme.of(context);

    String text;
    if (mp == MetodoPago.efectivo) {
      text = 'Pago en efectivo';
    } else if (mp == MetodoPago.tarjeta) {
      text = 'Pago con tarjeta: \$${formatPrice(venta.montoTarjeta)}';
    } else {
      final efectivo = venta.total - venta.montoTarjeta;
      text = 'Tarjeta: \$${formatPrice(venta.montoTarjeta)}   Efectivo: \$${formatPrice(efectivo)}';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        children: [
          Icon(_metodoPagoIcon(mp), size: 14, color: color.shade700),
          const SizedBox(width: 6),
          Text(text,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: color.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatDate(String fecha) {
  try {
    final d = DateTime.parse(fecha).toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  } catch (_) {
    return fecha;
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(tipo, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
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

TicketData _ticketFromVenta(VentaModel venta) {
  return TicketData(
    folio: venta.folio,
    fecha: DateTime.parse(venta.fecha).toLocal(),
    items: venta.items.map((item) => TicketItem(
      nombre: item.zapato?.nombre ?? 'Artículo',
      modelo: item.zapato?.modelo ?? '',
      cantidad: item.cantidad,
      precioUnitario: item.precioUnitario,
    )).toList(),
    total: venta.total,
    metodoPago: _metodoPagoLabel(venta.metodoPago),
    montoTarjeta: venta.montoTarjeta > 0 ? venta.montoTarjeta : null,
    tipoPrecio: venta.tipoPrecioString,
    inversionistaNombre: venta.inversionista?.nombre,
  );
}
