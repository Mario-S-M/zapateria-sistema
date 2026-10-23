import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/screens/asesor_screen.dart';
import 'package:zapateria_flutter/screens/recomendaciones_screen.dart';
import 'package:zapateria_flutter/services/agente_client.dart';
import 'package:zapateria_flutter/services/api_client.dart';

class _AgenteFalso extends AgenteClient {
  AgenteEstado _estado = AgenteEstado.desconectado;
  final List<AgenteMensaje> _mensajes = [];
  String? _error;
  final iniciadas = <bool>[];
  final enviados = <String>[];
  int terminadas = 0;

  @override
  AgenteEstado get estado => _estado;
  @override
  List<AgenteMensaje> get mensajes => _mensajes;
  @override
  String? get error => _error;
  @override
  bool get vozActiva => false;

  void agenteDice(String t) {
    _mensajes.add(AgenteMensaje(delAgente: true, texto: t));
    notifyListeners();
  }

  void fallaCon(String mensaje) {
    _error = mensaje;
    _estado = AgenteEstado.desconectado;
    notifyListeners();
  }

  @override
  Future<void> iniciar({required bool voz}) async {
    iniciadas.add(voz);
    _estado = AgenteEstado.conectado;
    notifyListeners();
  }

  @override
  void enviarTexto(String texto) {
    enviados.add(texto);
    _mensajes.add(AgenteMensaje(delAgente: false, texto: texto));
    notifyListeners();
  }

  @override
  Future<void> terminar() async {
    terminadas++;
    _estado = AgenteEstado.desconectado;
    notifyListeners();
  }
}

class _Backend implements HttpClientAdapter {
  final pedidos = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async {
    pedidos.add(o);
    final item = (String id, String nombre) => {
          'zapatoId': id,
          'nombre': nombre,
          'modelo': 'M',
          'foto': '',
          'categoriaId': 'c1',
          'categoria': 'Bota',
          'precioPublico': 100,
          'variantes': [
            {'colorId': 'k', 'color': 'Rosa', 'cantidad': 2},
          ],
        };
    final json = o.path == '/agente/inventario'
        ? {
            'talla': o.queryParameters['talla'],
            'items': [item('a', 'Bota A'), item('b', 'Bota B')]
          }
        : [];
    return ResponseBody.fromString(jsonEncode(json), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<_AgenteFalso> _montar(WidgetTester tester,
    {bool activo = true, _AgenteFalso? agente}) async {
  final falso = agente ?? _AgenteFalso();
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => CartProvider(),
    child: MaterialApp(home: AsesorScreen(activo: activo, client: falso)),
  ));
  return falso;
}

void main() {
  late _Backend backend;

  setUp(() {
    backend = _Backend();
    apiClient.dio.httpClientAdapter = backend;
  });

  testWidgets(
      'Escribir inicia en solo texto, muestra la conversación y envía lo escrito',
      (tester) async {
    final agente = await _montar(tester);

    await tester.tap(find.text('Escribir'));
    await tester.pump();
    expect(agente.iniciadas, [false]);

    agente.agenteDice('Hola, soy tu asesor.');
    await tester.pump();
    expect(find.text('Hola, soy tu asesor.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Calza el 23');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pump();
    expect(agente.enviados, ['Calza el 23']);
    expect(find.text('Calza el 23'), findsOneWidget);
  });

  testWidgets('Hablar inicia con voz', (tester) async {
    final agente = await _montar(tester);
    await tester.tap(find.text('Hablar'));
    await tester.pump();
    expect(agente.iniciadas, [true]);
  });

  testWidgets(
      'el client tool del agente abre las recomendaciones sin acción del vendedor',
      (tester) async {
    final agente = await _montar(tester);
    await tester.tap(find.text('Escribir'));
    await tester.pump();

    agente.onMostrarRecomendaciones!(const MostrarRecomendacionesParams(
      talla: 23,
      zapatoIds: ['b'],
      categoriaId: 'c1',
      colorId: 'k',
    ));
    await tester.pumpAndSettle();

    expect(find.byType(RecomendacionesScreen), findsOneWidget);
    expect(find.text('Talla 23'), findsOneWidget);
    final inv =
        backend.pedidos.firstWhere((p) => p.path == '/agente/inventario');
    expect(inv.queryParameters['talla'], 23.0);
    expect(inv.queryParameters['categoriaId'], 'c1');
    expect(find.text('Recomendados'), findsOneWidget);
  });

  testWidgets(
      'una segunda llamada del agente reemplaza la pantalla abierta, no apila otra',
      (tester) async {
    final agente = await _montar(tester);
    await tester.tap(find.text('Escribir'));
    await tester.pump();

    agente.onMostrarRecomendaciones!(
        const MostrarRecomendacionesParams(talla: 23, zapatoIds: ['a']));
    await tester.pumpAndSettle();
    agente.onMostrarRecomendaciones!(
        const MostrarRecomendacionesParams(talla: 24, zapatoIds: ['a']));
    await tester.pumpAndSettle();

    expect(find.text('Talla 24'), findsOneWidget);
    expect(find.text('Talla 23'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(RecomendacionesScreen), findsNothing);
    expect(find.byType(AsesorScreen), findsOneWidget);
  });

  testWidgets(
      '"Ver recomendaciones" sin talla conocida la pide y abre la pantalla',
      (tester) async {
    await _montar(tester);

    await tester.tap(find.text('Ver recomendaciones'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué talla busca?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '23');
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();

    expect(find.text('Talla 23'), findsOneWidget);
    expect(find.text('Recomendados'),
        findsNothing); // sin ids del agente: todo el stock de la talla
    expect(find.text('En existencia en talla 23'), findsOneWidget);
  });

  testWidgets('"Ver recomendaciones" reutiliza lo último que mandó el agente',
      (tester) async {
    final agente = await _montar(tester);
    await tester.tap(find.text('Escribir'));
    await tester.pump();
    agente.onMostrarRecomendaciones!(
        const MostrarRecomendacionesParams(talla: 23, zapatoIds: ['a']));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver recomendaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Talla 23'), findsOneWidget);
    expect(find.text('Recomendados'), findsOneWidget);
    expect(find.text('¿Qué talla busca?'), findsNothing);
  });

  testWidgets(
      'si el asesor no se puede conectar muestra el error y deja reintentar',
      (tester) async {
    final agente = await _montar(tester);
    agente.fallaCon('El asesor no tiene créditos disponibles en este momento.');
    await tester.pump();

    expect(
        find.text('El asesor no tiene créditos disponibles en este momento.'),
        findsOneWidget);
    expect(find.text('Hablar'), findsOneWidget);
    expect(find.text('Escribir'), findsOneWidget);
  });

  testWidgets('al salir de la pestaña se termina la conversación',
      (tester) async {
    final agente = _AgenteFalso();
    Widget app(bool activo) => ChangeNotifierProvider(
          create: (_) => CartProvider(),
          child:
              MaterialApp(home: AsesorScreen(activo: activo, client: agente)),
        );
    await tester.pumpWidget(app(true));
    expect(agente.terminadas, 0);

    await tester.pumpWidget(app(false));
    expect(agente.terminadas, 1);
  });
}
