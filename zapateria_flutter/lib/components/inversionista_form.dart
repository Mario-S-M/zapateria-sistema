import 'package:flutter/material.dart';

class InversionistaForm extends StatefulWidget {
  final Map<String, dynamic>? initialInversionista;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const InversionistaForm({
    super.key,
    this.initialInversionista,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<InversionistaForm> createState() => _InversionistaFormState();
}

class _InversionistaFormState extends State<InversionistaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late bool _tieneTerminal;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.initialInversionista?['nombre'] ?? '');
    _telefonoController = TextEditingController(text: widget.initialInversionista?['telefono'] ?? '');
    _emailController = TextEditingController(text: widget.initialInversionista?['email'] ?? '');
    _tieneTerminal = widget.initialInversionista?['tieneTerminal'] ?? false;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'nombre': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'tieneTerminal': _tieneTerminal,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.initialInversionista != null ? 'Editar Inversionista' : 'Nuevo Inversionista',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Icon(Icons.credit_card, size: 18),
                const SizedBox(width: 8),
                Text('Tiene terminal de tarjeta', style: theme.textTheme.bodyMedium),
              ],
            ),
            subtitle: Text(
              'Recibe los pagos con tarjeta del día',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            value: _tieneTerminal,
            onChanged: (v) => setState(() => _tieneTerminal = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
