import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapateria_flutter/utils/phone_utils.dart';

void main() {
  test('formatea de dos en dos con guiones', () {
    expect(formatTelefono('5512345678'), '55-12-34-56-78');
    expect(formatTelefono('551'), '55-1');
  });

  test('el formatter solo deja dígitos y corta a 10', () {
    final f = TelefonoInputFormatter();
    final r = f.formatEditUpdate(
        TextEditingValue.empty, const TextEditingValue(text: '55 12abc34-56-78-99'));
    expect(r.text, '55-12-34-56-78');
    expect(soloDigitos(r.text), '5512345678');
  });

  test('validación: vacío ok, 10 dígitos ok, otra longitud falla', () {
    expect(validateTelefono(''), isNull);
    expect(validateTelefono('55-12-34-56-78'), isNull);
    expect(validateTelefono('55-12-34'), isNotNull);
  });
}
