import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/screens/recomendaciones_screen.dart';
import 'package:zapateria_flutter/services/api_client.dart';

Map<String, dynamic> _item(String id, String nombre, {String cat = 'Escolar'}) => {
      'zapatoId': id,
      'nombre': nombre,
      'modelo': 'M-$id',
      'foto': '',
      'categoriaId': 'cat-1',
      'categoria': cat,
      'precioPublico': 450,
      'variantes': [
        {'colorId': 'rosa', 'color': 'Rosa', 'cantidad': 1},
        {'colorId': 'negro', 'color': 'Negro', 'cantidad': 3},
      ],
    };

Map<String, dynamic> _zapatoJson(String id) => {
      'id': id,
      'codigoBarras': 'cb-$id',
      'nombre': 'Zapato $id',
      'modelo': 'M-$id',
      'foto': '',
      'precioCompra': 200,
      'precioPublico': 450,
      'medidaInicio': 20,
      'medidaFin': 26,
      'horma': 'NORMAL',
      'colores': [],
      'precioRangos': [],
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };

class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> pedidos = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async {
    pedidos.add(o);
    Object json;
    if (o.path == '/agente/inventario') {
      json = {
        'talla': 23,
        'items': [_item('a', 'Tenis A'), _item('b', 'Tenis B'), _item('c', 'Tenis C')],
      };
    } else if (o.path.startsWith('/zapatos/')) {
      json = _zapatoJson(o.path.split('/').last);
    } else {
      json = [];
    }
    return ResponseBody.fromString(
      jsonEncode(json),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('muestra recomendados primero, solo la talla pedida, y agrega al carrito en esa talla',
      (tester) async {
    final adapter = _FakeAdapter();
    apiClient.dio.httpClientAdapter = adapter;
    final cart = CartProvider();

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: const MaterialApp(
        home: RecomendacionesScreen(talla: 23, categoriaId: 'cat-1', zapatoIdsRecomendados: ['c', 'inventado']),
      ),
    ));
    await tester.pumpAndSettle();

    // Pidió talla 23 y categoría escolar al backend
    final inv = adapter.pedidos.firstWhere((p) => p.path == '/agente/inventario');
    expect(inv.queryParameters['talla'], 23.0);
    expect(inv.queryParameters['categoriaId'], 'cat-1');

    expect(find.text('Talla 23'), findsOneWidget);
    expect(find.text('Recomendados'), findsOneWidget);
    expect(find.text('Más en talla 23'), findsOneWidget);
    expect(find.text('Escolar'), findsOneWidget); // chip del filtro

    // Orden: Tenis C (recomendado) antes que A y B; el id inventado no genera tarjeta
    final yC = tester.getTopLeft(find.text('Tenis C')).dy;
    final yA = tester.getTopLeft(find.text('Tenis A')).dy;
    expect(yC, lessThan(yA));
    expect(find.text('Tenis B'), findsOneWidget);

    // Agregar Tenis C (variante Rosa, 1 en existencia) al carrito
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar al carrito').first);
    await tester.pumpAndSettle();

    expect(cart.items, hasLength(1));
    final linea = cart.items.first;
    expect(linea.zapato.id, 'c');
    expect(linea.talla, 23.0);
    expect(linea.colorId, 'rosa');
    expect(linea.cantidad, 1);
    expect(linea.precioUnitario, 450);

    // Ya no hay más existencia de esa variante: el botón se bloquea
    expect(find.text('Todo en el carrito'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
