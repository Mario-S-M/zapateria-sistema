import 'package:flutter_test/flutter_test.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/utils/recomendaciones_utils.dart';

InventarioTallaItemModel _item(String id) => InventarioTallaItemModel(
      zapatoId: id,
      nombre: 'Zapato $id',
      modelo: 'M-$id',
      foto: '',
      precioPublico: 100,
      variantes: [VarianteTallaModel(colorId: 'k', color: 'Rosa', cantidad: 2)],
    );

ZapatoModel _zapato(String id) => ZapatoModel(
      id: id,
      codigoBarras: 'cb',
      nombre: 'Zapato $id',
      modelo: 'M',
      precioCompra: 50,
      precioPublico: 100,
      medidaInicio: 20,
      medidaFin: 26,
      colores: const [],
      createdAt: '',
      updatedAt: '',
    );

void main() {
  group('separarRecomendados', () {
    final items = [_item('a'), _item('b'), _item('c')];

    test('respeta el orden del agente y deja el resto en orden del servidor', () {
      final s = separarRecomendados(items, ['c', 'a']);
      expect(s.recomendados.map((i) => i.zapatoId), ['c', 'a']);
      expect(s.resto.map((i) => i.zapatoId), ['b']);
    });

    test('descarta ids que no existen en el inventario de la talla', () {
      final s = separarRecomendados(items, ['zzz', 'b']);
      expect(s.recomendados.map((i) => i.zapatoId), ['b']);
      expect(s.resto.map((i) => i.zapatoId), ['a', 'c']);
    });

    test('ignora ids repetidos', () {
      final s = separarRecomendados(items, ['a', 'a']);
      expect(s.recomendados, hasLength(1));
      expect(s.resto, hasLength(2));
    });

    test('sin recomendados todo queda en el resto', () {
      final s = separarRecomendados(items, []);
      expect(s.recomendados, isEmpty);
      expect(s.resto, hasLength(3));
    });
  });

  group('disponibleParaAgregar', () {
    test('descuenta lo que ya está en el carrito de esa variante y talla', () {
      final carrito = [
        CartItem(zapato: _zapato('a'), cantidad: 1, precioUnitario: 100, colorId: 'k', talla: 23),
        CartItem(zapato: _zapato('a'), cantidad: 5, precioUnitario: 100, colorId: 'k', talla: 24),
        CartItem(zapato: _zapato('a'), cantidad: 5, precioUnitario: 100, colorId: 'otro', talla: 23),
      ];
      expect(disponibleParaAgregar(carrito, zapatoId: 'a', colorId: 'k', talla: 23, existencia: 2), 1);
    });

    test('nunca es negativo', () {
      final carrito = [
        CartItem(zapato: _zapato('a'), cantidad: 3, precioUnitario: 100, colorId: 'k', talla: 23),
      ];
      expect(disponibleParaAgregar(carrito, zapatoId: 'a', colorId: 'k', talla: 23, existencia: 2), 0);
    });
  });
}
