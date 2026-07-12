import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/barcode_pattern_builder.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/marca_service.dart';

class MarcasScreen extends StatefulWidget {
  const MarcasScreen({super.key});

  @override
  State<MarcasScreen> createState() => _MarcasScreenState();
}

class _MarcasScreenState extends State<MarcasScreen> {
  List<MarcaModel> _marcas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _marcas = await marcaService.getAll();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm(MarcaModel? existing) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _MarcaFormScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(MarcaModel marca) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar marca'),
        content: Text('¿Eliminar la marca "${marca.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await marcaService.delete(marca.id);
        if (mounted) _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_marcas.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.branding_watermark, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No hay marcas registradas', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar marca'),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _marcas.length,
          itemBuilder: (context, index) {
            final marca = _marcas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.branding_watermark, color: theme.colorScheme.primary),
                ),
                title: Text(marca.nombre, style: theme.textTheme.titleMedium),
                subtitle: Text(marca.tienePatron
                    ? 'Patrón definido (${marca.patronLongitud} caracteres)'
                    : 'Sin patrón de código de barras'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PatronBadge(tienePatron: marca.tienePatron),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(marca),
                    ),
                  ],
                ),
                onLongPress: () => _delete(marca),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Marcas')),
      body: kIsWeb
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: body),
            )
          : body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}

class _PatronBadge extends StatelessWidget {
  final bool tienePatron;
  const _PatronBadge({required this.tienePatron});

  @override
  Widget build(BuildContext context) {
    final color = tienePatron ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        tienePatron ? 'Con patrón' : 'Sin patrón',
        style: TextStyle(
          fontSize: 11,
          color: tienePatron ? Colors.green.shade700 : Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MarcaFormScreen extends StatefulWidget {
  final MarcaModel? existing;
  const _MarcaFormScreen({this.existing});

  @override
  State<_MarcaFormScreen> createState() => _MarcaFormScreenState();
}

class _MarcaFormScreenState extends State<_MarcaFormScreen> {
  late final TextEditingController _nombreCtrl;
  final _formKey = GlobalKey<FormState>();

  String _codigoEjemplo = '';
  List<BarcodeSegmentoModel> _segmentos = [];
  bool _patronValido = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.existing?.nombre ?? '');
    _codigoEjemplo = widget.existing?.codigoEjemplo ?? '';
    _segmentos = List.of(widget.existing?.patronSegmentos ?? const []);
    _patronValido = _segmentos.isNotEmpty;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final nombre = _nombreCtrl.text.trim();
      final codigoEjemplo = _codigoEjemplo.isEmpty ? null : _codigoEjemplo;
      final segmentos = _patronValido ? _segmentos : null;
      if (widget.existing != null) {
        await marcaService.update(
          widget.existing!.id,
          nombre: nombre,
          codigoEjemplo: codigoEjemplo,
          patronSegmentos: segmentos,
        );
      } else {
        await marcaService.create(
          nombre: nombre,
          codigoEjemplo: codigoEjemplo,
          patronSegmentos: segmentos,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Editar marca' : 'Nueva marca'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(widget.existing != null ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la marca *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Patrón de código de barras (opcional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define esto solo si esta marca imprime códigos de barras que '
                    'varían por lote. Pega un ejemplo y toca hasta dónde llega cada '
                    'parte: fijo, modelo, lote (se ignora) y talla (siempre al final).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  BarcodePatternBuilder(
                    initialCodigoEjemplo: _codigoEjemplo,
                    initialSegmentos: _segmentos,
                    onChanged: (codigo, segmentos, esValido) {
                      _codigoEjemplo = codigo;
                      _segmentos = segmentos;
                      _patronValido = esValido;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
