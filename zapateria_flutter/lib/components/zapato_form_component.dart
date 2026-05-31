import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/services/color_service.dart';
import 'package:zapateria_flutter/services/categoria_service.dart';
import 'package:zapateria_flutter/services/inversionista_service.dart';
import 'package:zapateria_flutter/utils/barcode_utils.dart';
import 'package:zapateria_flutter/components/color_circle.dart';
import 'package:zapateria_flutter/components/image_picker_component.dart';
import 'package:zapateria_flutter/components/inversionista_form.dart';
import 'package:zapateria_flutter/components/barcode_scanner_widget.dart';

const _uuid = Uuid();

class ZapatoFormComponent extends StatefulWidget {
  final ZapatoModel? zapato;
  final Function(ZapatoCreateDto) onSave;
  final VoidCallback onCancel;

  const ZapatoFormComponent({
    super.key,
    this.zapato,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ZapatoFormComponent> createState() => _ZapatoFormComponentState();
}

class _ZapatoFormComponentState extends State<ZapatoFormComponent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoBarrasController;
  late TextEditingController _nombreController;
  late TextEditingController _modeloController;
  late TextEditingController _precioCompraController;
  late TextEditingController _precioPublicoController;
  late TextEditingController _medidaInicioController;
  late TextEditingController _medidaFinController;
  late TextEditingController _categoriaSearchController;
  late TextEditingController _inversionistaSearchController;

  List<ColorModel> _colores = [];
  List<CategoriaModel> _categorias = [];
  List<InversionistaModel> _inversionistas = [];
  List<String> _selectedColorIds = [];
  String? _selectedCategoriaId;
  String? _selectedInversionistaId;
  String? _fotoUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _codigoBarrasController = TextEditingController(text: widget.zapato?.codigoBarras ?? generateBarcode());
    _nombreController = TextEditingController(text: widget.zapato?.nombre ?? '');
    _modeloController = TextEditingController(text: widget.zapato?.modelo ?? '');
    _precioCompraController = TextEditingController(text: widget.zapato?.precioCompra.toInt().toString() ?? '');
    _precioPublicoController = TextEditingController(text: widget.zapato?.precioPublico.toInt().toString() ?? '');
    _medidaInicioController = TextEditingController(text: widget.zapato?.medidaInicio.toString() ?? '');
    _medidaFinController = TextEditingController(text: widget.zapato?.medidaFin.toString() ?? '');
    _categoriaSearchController = TextEditingController();
    _inversionistaSearchController = TextEditingController();
    _selectedColorIds = widget.zapato?.colores.map((c) => c.colorId).toList() ?? [];
    _selectedCategoriaId = widget.zapato?.categoriaId;
    _selectedInversionistaId = widget.zapato?.inversionistaId;
    _fotoUrl = widget.zapato?.foto;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        colorService.getAll(),
        categoriaService.getAll(),
        inversionistaService.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _colores = results[0] as List<ColorModel>;
          _categorias = results[1] as List<CategoriaModel>;
          _inversionistas = results[2] as List<InversionistaModel>;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _nombreController.dispose();
    _modeloController.dispose();
    _precioCompraController.dispose();
    _precioPublicoController.dispose();
    _medidaInicioController.dispose();
    _medidaFinController.dispose();
    _categoriaSearchController.dispose();
    _inversionistaSearchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInversionistaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un inversionista')));
      return;
    }
    if (_selectedColorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un color')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.zapato != null) {
        await zapatoService.update(
          widget.zapato!.id,
          ZapatoUpdateDto(
            codigoBarras: _codigoBarrasController.text.trim(),
            nombre: _nombreController.text.trim(),
            modelo: _modeloController.text.trim(),
            foto: _fotoUrl,
            precioCompra: double.tryParse(_precioCompraController.text.trim()),
            precioPublico: double.tryParse(_precioPublicoController.text.trim()),
            medidaInicio: int.tryParse(_medidaInicioController.text.trim()),
            medidaFin: int.tryParse(_medidaFinController.text.trim()),
            colorIds: _selectedColorIds,
            categoriaId: _selectedCategoriaId,
            inversionistaId: _selectedInversionistaId,
          ),
        );
      } else {
        final dto = ZapatoCreateDto(
          codigoBarras: _codigoBarrasController.text.trim(),
          nombre: _nombreController.text.trim(),
          modelo: _modeloController.text.trim(),
          foto: _fotoUrl ?? '',
          precioCompra: double.tryParse(_precioCompraController.text.trim()) ?? 0,
          precioPublico: double.tryParse(_precioPublicoController.text.trim()) ?? 0,
          medidaInicio: int.tryParse(_medidaInicioController.text.trim()) ?? 0,
          medidaFin: int.tryParse(_medidaFinController.text.trim()) ?? 0,
          colorIds: _selectedColorIds,
          categoriaId: _selectedCategoriaId,
          inversionistaId: _selectedInversionistaId,
        );
        await zapatoService.create(dto);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zapato guardado')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget form = kIsWeb ? _buildWebForm(context) : _buildMobileForm(context);

    if (kIsWeb) {
      form = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: form,
        ),
      );
    }

    return Form(key: _formKey, child: form);
  }

  // ── WEB LAYOUT ──────────────────────────────────────────────────────────────

  Widget _buildWebForm(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.zapato != null ? 'Editar Zapato' : 'Nuevo Zapato', style: theme.textTheme.headlineMedium),
              IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => _showScanner(context), tooltip: 'Escanear código'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLeftColumn(context, theme)),
              const SizedBox(width: 28),
              Expanded(child: _buildRightColumn(theme)),
            ],
          ),
          const SizedBox(height: 24),
          _buildColorsSection(theme, crossAxisCount: 6),
          const SizedBox(height: 24),
          _buildSummaryCard(theme),
          const SizedBox(height: 24),
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImagePickerComponent(
          currentImage: _fotoUrl,
          onImageUploaded: (url) => setState(() => _fotoUrl = url),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codigoBarrasController,
          decoration: const InputDecoration(labelText: 'Código de barras *', border: OutlineInputBorder()),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            if (!validateBarcode(v.trim())) return 'Debe tener 12 o 13 dígitos';
            return null;
          },
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => setState(() => _codigoBarrasController.text = generateBarcode()),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Generar código'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modeloController,
          decoration: const InputDecoration(labelText: 'Modelo *', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildRightColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _precioCompraController,
                decoration: const InputDecoration(labelText: 'Precio compra', border: OutlineInputBorder(), prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _precioPublicoController,
                decoration: const InputDecoration(labelText: 'Precio público *', border: OutlineInputBorder(), prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _medidaInicioController,
                decoration: const InputDecoration(labelText: 'Talla inicio', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _medidaFinController,
                decoration: const InputDecoration(labelText: 'Talla fin', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCategoriaId,
          decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin categoría')),
            ..._categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))),
          ],
          onChanged: (v) => setState(() => _selectedCategoriaId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedInversionistaId,
          decoration: const InputDecoration(labelText: 'Inversionista *', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: null, child: Text('Seleccionar...')),
            ..._inversionistas.map((inv) => DropdownMenuItem(
                  value: inv.id,
                  child: Text('${inv.nombre}${inv.activo ? " ✓" : ""}'),
                )),
          ],
          onChanged: (v) => setState(() => _selectedInversionistaId = v),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showCreateInversionistaDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Crear inversionista'),
          ),
        ),
      ],
    );
  }

  // ── MOBILE LAYOUT ────────────────────────────────────────────────────────────

  Widget _buildMobileForm(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.zapato != null ? 'Editar Zapato' : 'Nuevo Zapato', style: theme.textTheme.headlineMedium),
              IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => _showScanner(context)),
            ],
          ),
          const SizedBox(height: 16),
          ImagePickerComponent(
            currentImage: _fotoUrl,
            onImageUploaded: (url) => setState(() => _fotoUrl = url),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codigoBarrasController,
            decoration: const InputDecoration(labelText: 'Código de barras *'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              if (!validateBarcode(v.trim())) return 'Debe tener 12 o 13 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() => _codigoBarrasController.text = generateBarcode()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Generar código'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _modeloController,
            decoration: const InputDecoration(labelText: 'Modelo *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _precioCompraController, decoration: const InputDecoration(labelText: 'Precio compra'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _precioPublicoController, decoration: const InputDecoration(labelText: 'Precio público *'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _medidaInicioController, decoration: const InputDecoration(labelText: 'Medida inicio'), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _medidaFinController, decoration: const InputDecoration(labelText: 'Medida fin'), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategoriaId,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin categoría')),
              ..._categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))),
            ],
            onChanged: (v) => setState(() => _selectedCategoriaId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedInversionistaId,
            decoration: const InputDecoration(labelText: 'Inversionista *'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Seleccionar...')),
              ..._inversionistas.map((inv) => DropdownMenuItem(value: inv.id, child: Text('${inv.nombre}${inv.activo ? " ✓" : ""}'))),
            ],
            onChanged: (v) => setState(() => _selectedInversionistaId = v),
          ),
          TextButton(onPressed: () => _showCreateInversionistaDialog(context), child: const Text('+ Crear inversionista')),
          const SizedBox(height: 16),
          _buildColorsSection(theme, crossAxisCount: 3),
          const SizedBox(height: 24),
          _buildSummaryCard(theme),
          const SizedBox(height: 24),
          _buildSaveButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── SHARED SECTIONS ──────────────────────────────────────────────────────────

  Widget _buildColorsSection(ThemeData theme, {required int crossAxisCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Colores *', style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showCreateColorDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo color'),
            ),
            Text('${_selectedColorIds.length} sel.', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ColorPickerGrid(
          colors: _colores,
          selectedColorIds: _selectedColorIds,
          onColorSelect: (id) => setState(() {
            _selectedColorIds.contains(id) ? _selectedColorIds.remove(id) : _selectedColorIds.add(id);
          }),
          crossAxisCount: crossAxisCount,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: theme.textTheme.titleMedium),
            const Divider(),
            _summaryRow('Código', _codigoBarrasController.text),
            _summaryRow('Nombre', _nombreController.text),
            _summaryRow('Medidas', '${_medidaInicioController.text} - ${_medidaFinController.text}'),
            _summaryRow('Precio', '\$${_precioPublicoController.text}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _save,
        icon: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save),
        label: Text(_loading ? 'Guardando...' : (widget.zapato != null ? 'Guardar cambios' : 'Crear zapato')),
        style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value.isNotEmpty ? value : 'Sin especificar', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── DIALOGS ──────────────────────────────────────────────────────────────────

  void _showCreateInversionistaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: InversionistaForm(
            onSave: (inv) async {
              await _loadData();
              setState(() => _selectedInversionistaId = inv['id']);
              if (context.mounted) Navigator.pop(ctx);
            },
            onCancel: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  void _showCreateColorDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    String hexColor = '#000000';
    bool isCombo = false;
    String primaryColor = '#000000';
    String secondaryColor = '#FFFFFF';
    bool saving = false;

    final colorOptions = [
      '#1A1A1A', '#FFFFFF', '#C62828', '#1A237E', '#2E7D32',
      '#795548', '#757575', '#E91E63', '#F9A825', '#D7CCC8',
      '#FF6F00', '#4A148C', '#006064', '#BF360C', '#37474F',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AlertDialog(
              title: const Text('Nuevo color'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del color *'), autofocus: true),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('¿Es combinación?'),
                        const Spacer(),
                        Switch(value: isCombo, onChanged: (v) => setModalState(() => isCombo = v)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isCombo) ...[
                      const Text('Color:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: colorOptions.map((c) => GestureDetector(
                          onTap: () => setModalState(() => hexColor = c),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16)),
                              shape: BoxShape.circle,
                              border: Border.all(color: hexColor == c ? Colors.blue : Colors.grey.shade300, width: hexColor == c ? 3 : 1),
                            ),
                          ),
                        )).toList(),
                      ),
                    ] else ...[
                      const Text('Color primario:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: colorOptions.map((c) => GestureDetector(
                          onTap: () => setModalState(() => primaryColor = c),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16)),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor == c ? Colors.blue : Colors.grey.shade300, width: primaryColor == c ? 3 : 1),
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text('Color secundario:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: colorOptions.map((c) => GestureDetector(
                          onTap: () => setModalState(() => secondaryColor = c),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16)),
                              shape: BoxShape.circle,
                              border: Border.all(color: secondaryColor == c ? Colors.blue : Colors.grey.shade300, width: secondaryColor == c ? 3 : 1),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (nombreCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido')));
                      return;
                    }
                    setModalState(() => saving = true);
                    try {
                      final newColor = await colorService.create(
                        nombre: nombreCtrl.text.trim(),
                        hexadecimal: isCombo ? null : hexColor,
                        isCombo: isCombo,
                        primaryColor: isCombo ? primaryColor : null,
                        secondaryColor: isCombo ? secondaryColor : null,
                      );
                      if (mounted) {
                        setState(() {
                          _colores.add(newColor);
                          _selectedColorIds.add(newColor.id);
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Color "${newColor.nombre}" creado')));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      if (mounted) setModalState(() => saving = false);
                    }
                  },
                  child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.width * 0.7,
          child: BarcodeScannerWidget(
            onScan: (code) {
              if (mounted) {
                setState(() => _codigoBarrasController.text = code);
                Navigator.of(ctx).pop();
              }
            },
            onCancel: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }
}
