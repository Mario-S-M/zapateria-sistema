import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes([DateTime? date]) async {
    setState(() => _loading = true);
    try {
      _reportes = await ventaService.getReporte();
      if (date != null) {
        final fechaStr = '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
        _diaSeleccionado = _reportes.firstWhere(
          (r) => r.fecha == fechaStr,
          orElse: () => CierreCajaDia(fecha: '', inversionistas: [], totalDia: 0),
        );
        if (_diaSeleccionado?.fecha.isEmpty == true) _diaSeleccionado = null;
      } else {
        _diaSeleccionado = null;
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de Caja')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _diaSeleccionado != null
              ? _buildDiaSelected(theme)
              : _buildNoSelection(theme),
    );
  }

  Widget _buildDiaSelected(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _loadReportes(_fechaSeleccionada),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(_diaSeleccionado!.fecha), style: theme.textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                    const Divider(),
                    Text('Total del día', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                    Text('\$${formatPrice(_diaSeleccionado!.totalDia)}', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.green.shade700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Desglose por inversionista', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._diaSeleccionado!.inversionistas.map((inv) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    title: Text(inv.nombre, style: theme.textTheme.titleMedium),
                    subtitle: Text('${inv.totalItems} artículo${inv.totalItems == 1 ? '' : 's'}'),
                    trailing: Text('\$${formatPrice(inv.total)}', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green.shade700)),
                  ),
                )),
            TextButton(
              onPressed: () => setState(() => _diaSeleccionado = null),
              child: const Text('Limpiar selección'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelection(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('Selecciona un día para ver el reporte', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Seleccionar un día'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_MX').format(d);
    } catch (_) {
      return fecha;
    }
  }
}
