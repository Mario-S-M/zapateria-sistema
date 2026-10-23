import 'package:flutter_test/flutter_test.dart';
import 'package:zapateria_flutter/services/agente_client.dart';

void main() {
  test('parsea lo que manda el agente (ids separados por comas)', () {
    final p = MostrarRecomendacionesParams.tryParse({
      'talla': 23,
      'zapato_ids': 'a, b ,c',
      'categoria_id': 'cat-1',
      'color_id': 'rosa',
    })!;
    expect(p.talla, 23.0);
    expect(p.zapatoIds, ['a', 'b', 'c']);
    expect(p.categoriaId, 'cat-1');
    expect(p.colorId, 'rosa');
  });

  test('acepta talla como texto o decimal y campos opcionales ausentes', () {
    final p = MostrarRecomendacionesParams.tryParse({'talla': '23.5', 'zapato_ids': 'a'})!;
    expect(p.talla, 23.5);
    expect(p.categoriaId, isNull);
    expect(p.colorId, isNull);
  });

  test('ids vacíos o con comas sobrantes no generan elementos vacíos', () {
    expect(MostrarRecomendacionesParams.tryParse({'talla': 23, 'zapato_ids': ''})!.zapatoIds, isEmpty);
    expect(MostrarRecomendacionesParams.tryParse({'talla': 23, 'zapato_ids': ',a,,'})!.zapatoIds, ['a']);
  });

  test('sin talla válida devuelve null', () {
    expect(MostrarRecomendacionesParams.tryParse({'zapato_ids': 'a'}), isNull);
    expect(MostrarRecomendacionesParams.tryParse({'talla': 0, 'zapato_ids': 'a'}), isNull);
    expect(MostrarRecomendacionesParams.tryParse({'talla': 'x'}), isNull);
  });
}
