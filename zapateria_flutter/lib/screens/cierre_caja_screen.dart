import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
              if (kIsWeb)
                _buildWebDesglose(theme)
              else
                ...dia.inversionistas.map((inv) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        title: Text(inv.nombre, style: theme.textTheme.titleMedium),
                        subtitle: Text('${inv.totalItems} artículo${inv.totalItems == 1 ? '' : 's'}'),
                        trailing: Text('\$${formatPrice(inv.total)}',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.green.shade700)),
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWebDesglose(ThemeData theme) {
    final invs = _diaSeleccionado?.inversionistas ?? [];
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Inversionista', style: theme.textTheme.labelLarge)),
                Expanded(child: Text('Artículos', style: theme.textTheme.labelLarge, textAlign: TextAlign.center)),
                Expanded(child: Text('Total', style: theme.textTheme.labelLarge, textAlign: TextAlign.end)),
              ],
            ),
          ),
          ...invs.map((inv) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(inv.nombre, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                Expanded(child: Text('${inv.totalItems}', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)),
                Expanded(child: Text('\$${formatPrice(inv.total)}', textAlign: TextAlign.end, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }

String _formatDate(DateTime d) {
    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}
