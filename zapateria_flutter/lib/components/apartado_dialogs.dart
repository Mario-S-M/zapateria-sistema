import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class NuevoApartadoData {
  final String clienteNombre;
  final String? clienteTelefono;
  final double abono;
  final MetodoAbono metodo;

  NuevoApartadoData({
    required this.clienteNombre,
    this.clienteTelefono,
    required this.abono,
    required this.metodo,
  });
}

class AbonoData {
  final double monto;
  final MetodoAbono metodo;
  AbonoData(this.monto, this.metodo);
}

Future<NuevoApartadoData?> showNuevoApartadoDialog(BuildContext context, {required double total}) {
  return showDialog<NuevoApartadoData>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ApartadoForm(total: total),
        ),
      ),
    ),
  );
}

Future<AbonoData?> showAbonoDialog(BuildContext context, {required double saldo}) {
  return showDialog<AbonoData>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ApartadoForm(total: saldo, soloAbono: true),
        ),
      ),
    ),
  );
}

/// Formulario compartido: datos del cliente + abono (o solo abono).
class _ApartadoForm extends StatefulWidget {
  final double total; // total del apartado, o saldo si [soloAbono]
  final bool soloAbono;
  const _ApartadoForm({required this.total, this.soloAbono = false});

  @override
  State<_ApartadoForm> createState() => _ApartadoFormState();
}

class _ApartadoFormState extends State<_ApartadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _monto = TextEditingController();
  MetodoAbono _metodo = MetodoAbono.efectivo;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _monto.dispose();
    super.dispose();
  }

  double get _montoValue => double.tryParse(_monto.text.replaceAll(',', '.')) ?? 0;

  String? _validateMonto(String? v) {
    final m = double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0;
    if (m <= 0) {
      return widget.soloAbono ? 'Ingresa el monto del abono' : null;
    }
    if (m > widget.total) {
      return widget.soloAbono
          ? 'Excede el saldo (\$${formatPrice(widget.total)})'
          : 'No puede ser mayor al total (\$${formatPrice(widget.total)})';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.soloAbono) {
      Navigator.pop(context, AbonoData(_montoValue, _metodo));
    } else {
      final tel = _telefono.text.trim();
      Navigator.pop(
        context,
        NuevoApartadoData(
          clienteNombre: _nombre.text.trim(),
          clienteTelefono: tel.isEmpty ? null : tel,
          abono: _montoValue,
          metodo: _metodo,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.soloAbono ? 'Registrar abono' : 'Apartar',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.soloAbono
                  ? 'Saldo pendiente: \$${formatPrice(widget.total)}'
                  : 'Total del apartado: \$${formatPrice(widget.total)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!widget.soloAbono) ...[
              TextFormField(
                controller: _nombre,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre del cliente *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _monto,
              autofocus: widget.soloAbono,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(
                labelText: widget.soloAbono ? 'Monto del abono *' : 'Abono inicial (opcional)',
                prefixText: '\$ ',
              ),
              validator: _validateMonto,
            ),
            const SizedBox(height: 12),
            SegmentedButton<MetodoAbono>(
              segments: const [
                ButtonSegment(
                    value: MetodoAbono.efectivo,
                    icon: Icon(Icons.payments_outlined),
                    label: Text('Efectivo')),
                ButtonSegment(
                    value: MetodoAbono.tarjeta,
                    icon: Icon(Icons.credit_card),
                    label: Text('Tarjeta')),
              ],
              selected: {_metodo},
              onSelectionChanged: (s) => setState(() => _metodo = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(widget.soloAbono ? 'Registrar abono' : 'Guardar apartado'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
