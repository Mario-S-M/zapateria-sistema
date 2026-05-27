import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/components/zapato_form_component.dart';

class ZapatoFormScreen extends StatelessWidget {
  final ZapatoModel? zapato;

  const ZapatoFormScreen({super.key, this.zapato});

  @override
  Widget build(BuildContext context) {
    final isEditing = zapato != null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Zapato' : 'Nuevo Zapato'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ZapatoFormComponent(
        zapato: zapato,
        onSave: (data) {
          Navigator.pop(context, data);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
