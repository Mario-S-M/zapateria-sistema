import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/services/inversionista_service.dart';
import 'package:zapateria_flutter/components/inversionista_form.dart';

class InversionistasScreen extends StatefulWidget {
  const InversionistasScreen({super.key});

  @override
  State<InversionistasScreen> createState() => _InversionistasScreenState();
}

class _InversionistasScreenState extends State<InversionistasScreen> {
  List<InversionistaModel> _inversionistas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _inversionistas = await inversionistaService.getAll();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm(InversionistaModel? existing) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: InversionistaForm(
              initialInversionista: existing != null
                  ? {
                      'id': existing.id,
                      'nombre': existing.nombre,
                      'telefono': existing.telefono,
                      'email': existing.email,
                    }
                  : null,
              onSave: (data) async {
                Navigator.pop(ctx);
                try {
                  if (existing != null) {
                    await inversionistaService.update(
                      existing.id,
                      nombre: data['nombre'],
                      telefono: data['telefono'],
                      email: data['email'],
                    );
                  } else {
                    await inversionistaService.create(
                      nombre: data['nombre'],
                      telefono: data['telefono'],
                      email: data['email'],
                    );
                  }
                  if (mounted) _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              onCancel: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(InversionistaModel inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Inversionista'),
        content: Text('¿Eliminar a ${inv.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await inversionistaService.delete(inv.id);
        if (mounted) _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
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
    } else if (_inversionistas.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No hay inversionistas registrados', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showForm(null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar inversionista'),
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
      appBar: AppBar(title: const Text('Inversionistas')),
      body: kIsWeb
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: body,
              ),
            )
          : body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
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
              Expanded(flex: 3, child: Text('Nombre', style: theme.textTheme.labelLarge)),
              Expanded(flex: 2, child: Text('Teléfono', style: theme.textTheme.labelLarge)),
              Expanded(flex: 3, child: Text('Email', style: theme.textTheme.labelLarge)),
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
              itemCount: _inversionistas.length,
              itemBuilder: (context, index) {
                final inv = _inversionistas[index];
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
                          flex: 3,
                          child: Text(inv.nombre,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(inv.telefono ?? '—', style: theme.textTheme.bodyMedium),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(inv.email ?? '—', style: theme.textTheme.bodyMedium),
                        ),
                        Expanded(
                          child: Center(
                            child: _ActiveBadge(activo: inv.activo),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Editar',
                                onPressed: () => _showForm(inv),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                tooltip: 'Eliminar',
                                onPressed: () => _delete(inv),
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
        itemCount: _inversionistas.length,
        itemBuilder: (context, index) {
          final inv = _inversionistas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(inv.nombre[0].toUpperCase())),
              title: Text(inv.nombre, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (inv.telefono != null) Text(inv.telefono!),
                  if (inv.email != null) Text(inv.email!),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActiveBadge(activo: inv.activo),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showForm(inv),
                  ),
                ],
              ),
              onLongPress: () => _delete(inv),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (activo ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (activo ? Colors.green : Colors.grey).withOpacity(0.4)),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
            fontSize: 11,
            color: activo ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
