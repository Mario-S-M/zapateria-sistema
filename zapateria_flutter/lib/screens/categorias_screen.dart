import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/categoria_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<CategoriaModel> _categorias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _categorias = await categoriaService.getAll();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm(CategoriaModel? existing) {
    final nombreCtrl = TextEditingController(text: existing?.nombre ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing != null ? 'Editar Categoría' : 'Nueva Categoría',
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nombreCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
                    onFieldSubmitted: (_) => _save(ctx, formKey, nombreCtrl, existing),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _save(ctx, formKey, nombreCtrl, existing),
                          child: Text(existing != null ? 'Guardar' : 'Crear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext ctx,
    GlobalKey<FormState> formKey,
    TextEditingController nombreCtrl,
    CategoriaModel? existing,
  ) async {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(ctx);
    try {
      if (existing != null) {
        await categoriaService.update(existing.id, nombre: nombreCtrl.text.trim());
      } else {
        await categoriaService.create(nombre: nombreCtrl.text.trim());
      }
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _delete(CategoriaModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Eliminar la categoría "${cat.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
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
        await categoriaService.delete(cat.id);
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
    } else if (_categorias.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No hay categorías registradas', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showForm(null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar categoría'),
            ),
          ],
        ),
      );
    } else if (kIsWeb) {
      body = _buildWebTable(theme);
    } else {
      body = _buildMobileList(theme);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: kIsWeb
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: body,
              ),
            )
          : body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }

  Widget _buildWebTable(ThemeData theme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text('Nombre', style: theme.textTheme.labelLarge)),
              Expanded(child: Text('Estado', style: theme.textTheme.labelLarge, textAlign: TextAlign.center)),
              const SizedBox(width: 96),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                return Container(
                  decoration: BoxDecoration(
                    color: index.isEven ? theme.cardColor : theme.colorScheme.surface,
                    border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(cat.nombre,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          child: Center(child: _ActiveBadge(activo: cat.activo)),
                        ),
                        SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Editar',
                                onPressed: () => _showForm(cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 18),
                                tooltip: 'Eliminar',
                                onPressed: () => _delete(cat),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final cat = _categorias[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.category, color: theme.colorScheme.primary),
              ),
              title: Text(cat.nombre, style: theme.textTheme.titleMedium),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActiveBadge(activo: cat.activo),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showForm(cat),
                  ),
                ],
              ),
              onLongPress: () => _delete(cat),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool activo;
  const _ActiveBadge({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        activo ? 'Activa' : 'Inactiva',
        style: TextStyle(
            fontSize: 11,
            color: activo ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
