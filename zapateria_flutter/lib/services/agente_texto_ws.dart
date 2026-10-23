import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef AgenteToolHandler = Future<({bool ok, String resultado})> Function(
  String nombre,
  Map<String, dynamic> parametros,
);

/// Sesión del agente solo de texto por WebSocket (signed URL). No usa el
/// micrófono, así que funciona en una PC de mostrador sin micrófono o cuando se
/// niega el permiso; el SDK de voz (WebRTC) siempre lo pide.
class AgenteTextoWs {
  final void Function(String texto) onMensajeAgente;
  final AgenteToolHandler onToolCall;

  /// `motivo` es el texto con el que ElevenLabs cerró el canal (ej. `quota_exceeded`).
  final void Function(String? motivo) onCerrado;
  final WebSocketChannel Function(Uri uri) _conectar;

  WebSocketChannel? _canal;
  StreamSubscription<dynamic>? _sub;

  AgenteTextoWs({
    required this.onMensajeAgente,
    required this.onToolCall,
    required this.onCerrado,
    WebSocketChannel Function(Uri uri)? conectar,
  }) : _conectar = conectar ?? WebSocketChannel.connect;

  Future<void> conectar(String signedUrl) async {
    final canal = _conectar(Uri.parse(signedUrl));
    _canal = canal;
    await canal.ready;
    _enviar({
      'type': 'conversation_initiation_client_data',
      'conversation_config_override': {
        'conversation': {'text_only': true},
      },
    });
    _sub = canal.stream.listen(
      (dato) => _alRecibir(dato as String),
      onDone: () => onCerrado(canal.closeReason),
      onError: (_) => onCerrado(null),
    );
  }

  void enviarTexto(String texto) =>
      _enviar({'type': 'user_message', 'text': texto});

  Future<void> cerrar() async {
    await _sub?.cancel();
    _sub = null;
    await _canal?.sink.close();
    _canal = null;
  }

  void _enviar(Map<String, dynamic> mensaje) =>
      _canal?.sink.add(jsonEncode(mensaje));

  Future<void> _alRecibir(String crudo) async {
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(crudo) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (m['type']) {
      case 'ping':
        final id = (m['ping_event'] as Map?)?['event_id'];
        _enviar({'type': 'pong', 'event_id': id});
      case 'agent_response':
        final texto =
            (m['agent_response_event'] as Map?)?['agent_response'] as String?;
        if (texto != null && texto.isNotEmpty) onMensajeAgente(texto);
      case 'client_tool_call':
        final llamada = m['client_tool_call'] as Map<String, dynamic>;
        final r = await onToolCall(
          llamada['tool_name'] as String,
          Map<String, dynamic>.from(llamada['parameters'] as Map? ?? {}),
        );
        _enviar({
          'type': 'client_tool_result',
          'tool_call_id': llamada['tool_call_id'],
          'result': r.resultado,
          'is_error': !r.ok,
        });
    }
  }
}
