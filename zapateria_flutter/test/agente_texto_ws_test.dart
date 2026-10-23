import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zapateria_flutter/services/agente_texto_ws.dart';

class _CanalFalso extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final _entrante = StreamController<dynamic>();
  final enviados = <Map<String, dynamic>>[];
  late final _sink = _SinkFalso(enviados);

  void servidorManda(Map<String, dynamic> m) => _entrante.add(jsonEncode(m));

  @override
  Future<void> get ready => Future.value();
  @override
  Stream<dynamic> get stream => _entrante.stream;
  @override
  WebSocketSink get sink => _sink;
  @override
  String? get protocol => null;
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

class _SinkFalso implements WebSocketSink {
  final List<Map<String, dynamic>> enviados;
  bool cerrado = false;
  _SinkFalso(this.enviados);

  @override
  void add(dynamic data) =>
      enviados.add(jsonDecode(data as String) as Map<String, dynamic>);
  @override
  Future<void> close([int? closeCode, String? closeReason]) async =>
      cerrado = true;
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream stream) async {}
  @override
  Future get done => Future.value();
}

void main() {
  late _CanalFalso canal;
  late List<String> respuestas;
  late List<(String, Map<String, dynamic>)> herramientas;
  late AgenteTextoWs ws;

  setUp(() async {
    canal = _CanalFalso();
    respuestas = [];
    herramientas = [];
    ws = AgenteTextoWs(
      onMensajeAgente: respuestas.add,
      onToolCall: (nombre, params) async {
        herramientas.add((nombre, params));
        return (ok: true, resultado: 'pantalla abierta');
      },
      onCerrado: (_) {},
      conectar: (_) => canal,
    );
    await ws.conectar('wss://ejemplo/convai');
  });

  test('al conectar pide sesión solo de texto', () {
    expect(canal.enviados.first['type'], 'conversation_initiation_client_data');
    expect(
        canal.enviados.first['conversation_config_override']['conversation']
            ['text_only'],
        true);
  });

  test('enviarTexto manda user_message', () {
    ws.enviarTexto('Calza el 23');
    expect(
        canal.enviados.last, {'type': 'user_message', 'text': 'Calza el 23'});
  });

  test('responde ping con pong del mismo evento', () async {
    canal.servidorManda({
      'type': 'ping',
      'ping_event': {'event_id': 7}
    });
    await Future<void>.delayed(Duration.zero);
    expect(canal.enviados.last, {'type': 'pong', 'event_id': 7});
  });

  test('entrega las respuestas del agente', () async {
    canal.servidorManda({
      'type': 'agent_response',
      'agent_response_event': {'agent_response': '¿Qué número calza?'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(respuestas, ['¿Qué número calza?']);
  });

  test('ejecuta el client tool y devuelve el resultado con el mismo id',
      () async {
    canal.servidorManda({
      'type': 'client_tool_call',
      'client_tool_call': {
        'tool_name': 'mostrar_recomendaciones',
        'tool_call_id': 'abc',
        'parameters': {'talla': 23, 'zapato_ids': 'z1'},
      },
    });
    await Future<void>.delayed(Duration.zero);
    expect(herramientas.single.$1, 'mostrar_recomendaciones');
    expect(herramientas.single.$2['talla'], 23);
    expect(canal.enviados.last, {
      'type': 'client_tool_result',
      'tool_call_id': 'abc',
      'result': 'pantalla abierta',
      'is_error': false,
    });
  });

  test('ignora mensajes que no entiende', () async {
    canal.servidorManda({'type': 'audio', 'audio_event': {}});
    canal._entrante.add('no es json');
    await Future<void>.delayed(Duration.zero);
    expect(respuestas, isEmpty);
    expect(canal.enviados, hasLength(1)); // solo el initiation
  });

  test('cerrar cierra el canal', () async {
    await ws.cerrar();
    expect(canal._sink.cerrado, true);
  });
}
