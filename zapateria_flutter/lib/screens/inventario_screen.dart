import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/inventario_service.dart';
import 'package:zapateria_flutter/components/color_circle.dart';
import 'package:zapateria_flutter/screens/scan_inventario_screen.dart';
import 'package:zapateria_flutter/utils/talla_converter.dart';

class InventarioScreen extends StatefulWidget {
  final ZapatoModel zapato;

  const InventarioScreen({super.key, required this.zapato});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  // controllers[colorId][talla] = TextEditingController
  final Map<String, Map<double, TextEditingController>> _controllers = {};
  bool _loading = true;
  bool _saving = false;

  List<ZapatoColorModel> get _colores => widget.zapato.colores;

  // Generates full and half sizes: 23.0, 23.5, 24.0, 24.5, ...
  List<double> get _tallas {
    final start = widget.zapato.medidaInicio;
    final end = widget.zapato.medidaFin;
    final result = <double>[];
    for (var t = start; t <= end; t++) {
      result.add(t.toDouble());
      if (t < end) result.add(t + 0.5);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadInventario();
  }

  void _initControllers() {
    final tallas = _tallas;
    for (final zc in _colores) {
      _controllers[zc.colorId] = {};
      for (final t in tallas) {
        _controllers[zc.colorId]![t] = TextEditingController(text: '1');
      }
    }
    if (_colores.isEmpty) {
      _controllers['__none__'] = {};
      for (final t in tallas) {
        _controllers['__none__']![t] = TextEditingController(text: '1');
      }
    }
  }

  Future<void> _loadInventario() async {
    try {
      final items = await inventarioService.getByZapato(widget.zapato.id);
      for (final item in items) {
        final key = item.colorId ?? '__none__';
        if (_controllers[key] != null && _controllers[key]![item.talla] != null) {
          _controllers[key]![item.talla]!.text = '${item.cantidad}';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar inventario: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final colorMap in _controllers.values) {
      for (final ctrl in colorMap.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final items = <Map<String, dynamic>>[];

      for (final entry in _controllers.entries) {
        final colorId = entry.key == '__none__' ? null : entry.key;
        for (final tallaEntry in entry.value.entries) {
          final cantidad = int.tryParse(tallaEntry.value.text) ?? 0;
          items.add({
            'zapatoId': widget.zapato.id,
            if (colorId != null) 'colorId': colorId,
            'talla': tallaEntry.key,
            'cantidad': cantidad,
          });
        }
      }

      await inventarioService.bulkUpsert(items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventario guardado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openScanLoop() async {
    String? colorId;
    String? colorNombre;
    if (_colores.isNotEmpty) {
      final picked = await _pickColorForScan();
      if (picked == null || !mounted) return;
      colorId = picked.colorId;
      colorNombre = picked.color.nombre;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanInventarioScreen(
          zapato: widget.zapato,
          colorId: colorId,
          colorNombre: colorNombre,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadInventario();
    }
  }

  Future<ZapatoColorModel?> _pickColorForScan() {
    return showDialog<ZapatoColorModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué color vas a registrar?'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colores.map((zc) {
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, zc),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorCircle(color: zc.color, size: 40),
                    const SizedBox(height: 4),
                    Text(zc.color.nombre, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventario', style: TextStyle(fontSize: 18)),
            Text(
              '${widget.zapato.nombre} — ${widget.zapato.modelo}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          if (widget.zapato.marcaId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                onPressed: _openScanLoop,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Escanear para registrar stock',
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tallas.isEmpty
              ? _buildEmptyRange(theme)
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    if (isMobile) return _buildMobileAccordion(theme);
                    return _colores.isEmpty
                        ? _buildNoColorsTable(theme)
                        : _buildMatrix(theme);
                  },
                ),
    );
  }

  Widget _buildEmptyRange(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.straighten, size: 48, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text('Este zapato no tiene rango de tallas definido.',
              style: theme.textTheme.bodyLarge),
          Text('Edita el zapato para configurar medida inicio y fin.',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildMobileAccordion(ThemeData theme) {
    final rows = _colores.isNotEmpty
        ? _colores.map((zc) => _InventarioRow(
              label: zc.color.nombre,
              colorWidget: ColorCircle(color: zc.color, size: 20),
              controllers: _controllers[zc.colorId]!,
              tallas: _tallas,
            )).toList()
        : [
            _InventarioRow(
              label: 'Sin color',
              colorWidget: Icon(Icons.circle_outlined, color: theme.hintColor, size: 20),
              controllers: _controllers['__none__']!,
              tallas: _tallas,
            )
          ];

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _MobileColorAccordion(row: rows[i]),
    );
  }

  Widget _buildNoColorsTable(ThemeData theme) {
    return _InventarioTable(
      tallas: _tallas,
      rows: [
        _InventarioRow(
          label: 'Sin color',
          colorWidget: Icon(Icons.circle_outlined, color: theme.hintColor, size: 20),
          controllers: _controllers['__none__']!,
          tallas: _tallas,
        ),
      ],
    );
  }

  Widget _buildMatrix(ThemeData theme) {
    final rows = _colores.map((zc) => _InventarioRow(
      label: zc.color.nombre,
      colorWidget: ColorCircle(color: zc.color, size: 20),
      controllers: _controllers[zc.colorId]!,
      tallas: _tallas,
    )).toList();

    return _InventarioTable(tallas: _tallas, rows: rows);
  }
}


// ── Table widget ──────────────────────────────────────────────────────────────

class _InventarioRow {
  final String label;
  final Widget colorWidget;
  final Map<double, TextEditingController> controllers;
  final List<double> tallas;

  const _InventarioRow({
    required this.label,
    required this.colorWidget,
    required this.controllers,
    required this.tallas,
  });
}

class _InventarioTable extends StatelessWidget {
  final List<double> tallas;
  final List<_InventarioRow> rows;

  const _InventarioTable({required this.tallas, required this.rows});

  static const double _colWidth = 100.0;
  static const double _labelWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerBg = theme.colorScheme.surfaceContainerHighest;
    final rowAlt = theme.colorScheme.surfaceContainerLow;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text('Color', style: theme.textTheme.labelLarge),
                    ),
                  ),
                  ...tallas.map((t) {
                    final eq = equivalencias(t);
                    return SizedBox(
                      width: _colWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MX ${formatTalla(eq.mx)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('EU ${formatTalla(eq.eu)}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                            Text('US ${formatTalla(eq.us)}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                            Text('CN ${formatTalla(eq.cn)}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: _colWidth,
                    child: Center(
                      child: Text('Total', style: theme.textTheme.labelLarge),
                    ),
                  ),
                ],
              ),
            ),
            // Data rows
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return _DataRow(
                row: row,
                tallas: tallas,
                colWidth: _colWidth,
                labelWidth: _labelWidth,
                background: i.isOdd ? rowAlt : null,
              );
            }),
            // Totals row
            _TotalsRow(rows: rows, tallas: tallas, colWidth: _colWidth, labelWidth: _labelWidth),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final _InventarioRow row;
  final List<double> tallas;
  final double colWidth;
  final double labelWidth;
  final Color? background;

  const _DataRow({
    required this.row,
    required this.tallas,
    required this.colWidth,
    required this.labelWidth,
    this.background,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  int get _total => widget.tallas.fold(0, (sum, t) {
    return sum + (int.tryParse(widget.row.controllers[t]?.text ?? '0') ?? 0);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: widget.background,
      child: Row(
        children: [
          SizedBox(
            width: widget.labelWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  widget.row.colorWidget,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.row.label,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...widget.tallas.map((t) {
            final ctrl = widget.row.controllers[t]!;
            return SizedBox(
              width: widget.colWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: _StockCell(
                  controller: ctrl,
                  onChanged: () => setState(() {}),
                ),
              ),
            );
          }),
          SizedBox(
            width: widget.colWidth,
            child: Center(
              child: Text(
                '$_total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _total > 0 ? theme.colorScheme.primary : theme.hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCell extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _StockCell({required this.controller, required this.onChanged});

  @override
  State<_StockCell> createState() => _StockCellState();
}

class _StockCellState extends State<_StockCell> {
  int get _value => int.tryParse(widget.controller.text) ?? 0;

  void _increment() {
    widget.controller.text = '${_value + 1}';
    widget.onChanged();
    setState(() {});
  }

  void _decrement() {
    final v = _value;
    if (v <= 0) return;
    widget.controller.text = '${v - 1}';
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _value;
    final hasStock = value > 0;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: hasStock ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasStock
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _CounterButton(
            icon: Icons.remove,
            onPressed: hasStock ? _decrement : null,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: hasStock ? theme.colorScheme.onSurface : theme.hintColor,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add,
            onPressed: _increment,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 28,
        height: 36,
        child: Icon(
          icon,
          size: 14,
          color: onPressed != null ? theme.colorScheme.primary : theme.disabledColor,
        ),
      ),
    );
  }
}

// ── Mobile accordion (vertical per color) ────────────────────────────────────

class _MobileColorAccordion extends StatefulWidget {
  final _InventarioRow row;

  const _MobileColorAccordion({required this.row});

  @override
  State<_MobileColorAccordion> createState() => _MobileColorAccordionState();
}

class _MobileColorAccordionState extends State<_MobileColorAccordion> {
  int get _total => widget.row.tallas.fold(
      0, (s, t) => s + (int.tryParse(widget.row.controllers[t]?.text ?? '0') ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: widget.row.colorWidget,
        title: Text(widget.row.label, style: theme.textTheme.bodyMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_total',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more),
          ],
        ),
        initiallyExpanded: true,
        children: [
          ...widget.row.tallas.map((t) {
            final ctrl = widget.row.controllers[t]!;
            final eq = equivalencias(t);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MX ${formatTalla(eq.mx)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text('EU ${formatTalla(eq.eu)} / US ${formatTalla(eq.us)}',
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StockCell(
                      controller: ctrl,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Totals row ────────────────────────────────────────────────────────────────

class _TotalsRow extends StatefulWidget {
  final List<_InventarioRow> rows;
  final List<double> tallas;
  final double colWidth;
  final double labelWidth;

  const _TotalsRow({
    required this.rows,
    required this.tallas,
    required this.colWidth,
    required this.labelWidth,
  });

  @override
  State<_TotalsRow> createState() => _TotalsRowState();
}

class _TotalsRowState extends State<_TotalsRow> {
  @override
  void initState() {
    super.initState();
    for (final row in widget.rows) {
      for (final ctrl in row.controllers.values) {
        ctrl.addListener(() => setState(() {}));
      }
    }
  }

  int _totalForTalla(double t) => widget.rows.fold(0, (sum, row) {
    return sum + (int.tryParse(row.controllers[t]?.text ?? '0') ?? 0);
  });

  int get _grandTotal => widget.tallas.fold(0, (sum, t) => sum + _totalForTalla(t));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: widget.labelWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text('Total', style: theme.textTheme.labelLarge),
            ),
          ),
          ...widget.tallas.map((t) => SizedBox(
            width: widget.colWidth,
            child: Center(
              child: Text(
                '${_totalForTalla(t)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          )),
          SizedBox(
            width: widget.colWidth,
            child: Center(
              child: Text(
                '$_grandTotal',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
