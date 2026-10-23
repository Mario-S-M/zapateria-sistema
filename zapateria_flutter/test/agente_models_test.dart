import 'package:flutter_test/flutter_test.dart';
import 'package:zapateria_flutter/models/models.dart';

void main() {
  test('InventarioTallaModel parsea la respuesta de /agente/inventario', () {
    final model = InventarioTallaModel.fromJson({
      'talla': 23,
      'items': [
        {
          'zapatoId': 'z1',
          'nombre': 'Bota Tobillera',
          'modelo': 'BTB-15',
          'foto': 'uploads/zapatos/a.jpg',
          'categoriaId': 'c1',
          'categoria': 'Bota',
          'precioPublico': 1380,
          'variantes': [
            {'colorId': 'k1', 'color': 'Café', 'cantidad': 1},
            {'colorId': null, 'color': null, 'cantidad': 2},
          ],
        },
      ],
    });

    expect(model.talla, 23.0);
    expect(model.items, hasLength(1));
    final item = model.items.first;
    expect(item.precioPublico, 1380.0);
    expect(item.categoria, 'Bota');
    expect(item.variantes.map((v) => v.cantidad), [1, 2]);
    expect(item.variantes.last.colorId, isNull);
  });

  test('InventarioTallaModel acepta una talla sin existencias', () {
    final model = InventarioTallaModel.fromJson({'talla': 99, 'items': []});
    expect(model.items, isEmpty);
  });

  test('SesionAgenteModel trae token de voz y signedUrl de texto', () {
    final sesion = SesionAgenteModel.fromJson({
      'plataforma': 'movil',
      'conversationToken': 'tok',
      'signedUrl': 'wss://x',
    });
    expect(sesion.conversationToken, 'tok');
    expect(sesion.signedUrl, 'wss://x');
  });
}
