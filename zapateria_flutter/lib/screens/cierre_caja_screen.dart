import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class CierreCajaScreen extends StatefulWidget {
  const CierreCajaScreen({super.key});

  @override
  State<CierreCajaScreen> createState() => _CierreCajaScreenState();
}

class _CierreCajaScreenState extends State<CierreCajaScreen> {
  List<CierreCajaDia> _reportes = [];
  CierreCajaDia? _diaSeleccionado;
  bool _loading = true;
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();
    _loadReportes(_fechaSeleccionada);
  }

  Future<void> _loadReportes([DateTime? date]) async {
    final target = date ?? _fechaSeleccionada;
    setState(() => _loading = true);
    try {
      _reportes = await ventaService.getReporte();
      final fechaStr = '${target.year}-${_pad(target.month)}-${_pad(target.day)}';
      final match = _reportes.where((r) => r.fecha == fechaStr).toList();
      _diaSeleccionado = match.isNotEmpty
          ? match.first
          : CierreCajaDia(fecha: fechaStr, inversionistas: [], totalDia: 0);
    } catch (e) {
      debugPrint('Error: $e');
      _diaSeleccionado = CierreCajaDia(fecha: '', inversionistas: [], totalDia: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _fechaSeleccionada = date);
      _loadReportes(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _buildDiaSelected(theme);

    if (kIsWeb) {
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: body,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de Caja')),
      body: body,
    );
  }

  Widget _buildDiaSelected(ThemeData theme) {
    final dia = _diaSeleccionado!;
    final sinVentas = dia.inversionistas.isEmpty;
    return RefreshIndicator(
      onRefresh: () => _loadReportes(_fechaSeleccionada),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(_fechaSeleccionada),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Cambiar día'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Total del día', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                    Text(
                      '\$${formatPrice(dia.totalDia)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: sinVentas ? theme.disabledColor : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (sinVentas)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text('Sin ventas registradas este día', style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                ),
              )
            else ...[
              Text('Desglose por inversionista', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...dia.inversionistas.map((inv) => _buildInversionistaAcordeon(inv, theme)),
              if (dia.deudasTarjeta.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDeudasTarjeta(dia, theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInversionistaAcordeon(CierreCajaInversionista inv, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        title: kIsWeb ? _buildInvWebHeader(inv, theme) : _buildInvMobileHeader(inv, theme),
        children: [
          const Divider(height: 1),
          _buildArticulosHeader(theme),
          ...inv.articulos.map((art) => _buildArticuloRow(art, theme)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInvWebHeader(CierreCajaInversionista inv, ThemeData theme) {
    final isNegative = inv.total < 0;
    final totalColor = isNegative ? Colors.red.shade700 : Colors.green.shade700;
    final totalStr = isNegative
        ? '(\$${formatPrice(inv.total.abs())})'
        : '\$${formatPrice(inv.total)}';
    return Row(
      children: [
        Expanded(flex: 3, child: Text(inv.nombre, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
        Expanded(child: Text('${inv.totalItems} art.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
        Expanded(child: Text(totalStr, textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(color: totalColor, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildInvMobileHeader(CierreCajaInversionista inv, ThemeData theme) {
    final isNegative = inv.total < 0;
    final totalColor = isNegative ? Colors.red.shade700 : Colors.green.shade700;
    final totalStr = isNegative
        ? '(\$${formatPrice(inv.total.abs())})'
        : '\$${formatPrice(inv.total)}';
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(inv.nombre, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Text('${inv.totalItems} artículo${inv.totalItems == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ],
        )),
        Text(totalStr,
            style: theme.textTheme.bodyMedium?.copyWith(color: totalColor, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDeudasTarjeta(CierreCajaDia dia, ThemeData theme) {
    final nombre = dia.terminalNombre ?? 'Terminal';
    return Card(
      color: Colors.orange.shade50,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, size: 18, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text(
                  'Deudas de tarjeta — $nombre debe a:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...dia.deudasTarjeta.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(d.acreedorNombre, style: theme.textTheme.bodyMedium),
                  Text('\$${formatPrice(d.monto)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total a pagar', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '\$${formatPrice(dia.deudasTarjeta.fold(0.0, (s, d) => s + d.monto))}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticulosHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 16, vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: kIsWeb ? 44 : 38),
          Expanded(flex: 4, child: Text('Artículo', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor))),
          SizedBox(width: 44, child: Text('Cant.', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor), textAlign: TextAlign.center)),
          SizedBox(width: kIsWeb ? 90 : 72, child: Text('Precio', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor), textAlign: TextAlign.end)),
          SizedBox(width: kIsWeb ? 90 : 72, child: Text('Subtotal', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildArticuloRow(CierreCajaArticulo art, ThemeData theme) {
    final imgSize = kIsWeb ? 36.0 : 32.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 20 : 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          ZapatoImage(imageUrl: art.foto, height: imgSize, width: imgSize, borderRadius: 6),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(art.nombre, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                if (art.modelo != null)
                  Text(art.modelo!, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11), overflow: TextOverflow.ellipsis),
                if (art.hora != null)
                  Text(_formatHora(art.hora!), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(width: 44, child: Text('${art.cantidad}', textAlign: TextAlign.center, style: theme.textTheme.bodySmall)),
          SizedBox(width: kIsWeb ? 90 : 72, child: Text('\$${formatPrice(art.precioUnitario)}', textAlign: TextAlign.end, style: theme.textTheme.bodySmall)),
          SizedBox(width: kIsWeb ? 90 : 72, child: Text('\$${formatPrice(art.subtotal)}', textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _formatHora(String hora) {
    try {
      final d = DateTime.parse(hora).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

String _formatDate(DateTime d) {
    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}
