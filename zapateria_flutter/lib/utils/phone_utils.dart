import 'package:flutter/services.dart';

const int telefonoDigitos = 10;

/// Deja solo los dígitos de [value].
String soloDigitos(String value) => value.replaceAll(RegExp(r'\D'), '');

/// '5512345678' → '55-12-34-56-78' (agrupa de dos en dos).
String formatTelefono(String value) {
  final d = soloDigitos(value);
  final partes = <String>[];
  for (var i = 0; i < d.length; i += 2) {
    partes.add(d.substring(i, i + 2 > d.length ? d.length : i + 2));
  }
  return partes.join('-');
}

/// Valida un teléfono opcional: vacío es válido, si no debe tener 10 dígitos.
String? validateTelefono(String? value) {
  final d = soloDigitos(value ?? '');
  if (d.isEmpty) return null;
  if (d.length != telefonoDigitos) return 'Ingresa $telefonoDigitos dígitos';
  return null;
}

/// Acepta solo dígitos (máx. 10) y los muestra separados por guiones.
class TelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = soloDigitos(newValue.text);
    if (digits.length > telefonoDigitos) digits = digits.substring(0, telefonoDigitos);
    final text = formatTelefono(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
