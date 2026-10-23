import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_utils.dart';
import 'agente_service.dart';
import 'agente_texto_ws.dart';

/// Parámetros del client tool `mostrar_recomendaciones` que dispara el agente.
class MostrarRecomendacionesParams {
  final double talla;
  final List<String> zapatoIds;
  final String? categoriaId;
  final String? colorId;

  const MostrarRecomendacionesParams({
    required this.talla,
    required this.zapatoIds,
    this.categoriaId,
    this.colorId,
  });

  /// ElevenLabs no admite arreglos como parámetro: los ids llegan separados por comas.
  /// Devuelve null si falta o es inválida la talla (no se puede abrir la pantalla sin ella).
  static MostrarRecomendacionesParams? tryParse(Map<String, dynamic> p) {
    final talla = double.tryParse('${p['talla']}');
    if (talla == null || talla <= 0) return null;
    String? limpio(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return MostrarRecomendacionesParams(
      talla: talla,
      zapatoIds: (limpio(p['zapato_ids']) ?? '')
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(),
      categoriaId: limpio(p['categoria_id']),
      colorId: limpio(p['color_id']),
    );
  }
}

class AgenteMensaje {
  final bool delAgente;
  final String texto;
  const AgenteMensaje({required this.delAgente, required this.texto});
}

enum AgenteEstado { desconectado, conectando, conectado }

/// Tiempo máximo para abrir la voz. Si el navegador muestra el aviso del micrófono
/// y nadie lo contesta, la conexión se queda esperando: pasado este tiempo se cae a texto.
const _esperaVoz = Duration(seconds: 25);

/// Conversación con el agente de ElevenLabs. Un solo cliente para móvil y web.
/// - Voz: SDK `elevenlabs_agents` (WebRTC/LiveKit), también acepta mensajes escritos.
/// - Solo texto: WebSocket ([AgenteTextoWs]), sin micrófono. El SDK siempre pide el
///   micrófono, así que si la voz no arranca (sin micrófono o permiso negado) se
///   cae a texto automáticamente.
class AgenteClient extends ChangeNotifier {
  /// La pantalla Asesor lo asigna para abrir la lista de recomendaciones.
  void Function(MostrarRecomendacionesParams params)? onMostrarRecomendaciones;

  ConversationClient? _client;
  AgenteTextoWs? _texto;
  AgenteEstado _estado = AgenteEstado.desconectado;
  final List<AgenteMensaje> _mensajes = [];
  bool _agenteHablando = false;
  bool _vozActiva = false;
  String? _error;

  AgenteEstado get estado => _estado;
  List<AgenteMensaje> get mensajes => List.unmodifiable(_mensajes);
  bool get agenteHablando => _agenteHablando;
  bool get vozActiva => _vozActiva;
  bool get microfonoSilenciado => _client?.isMuted ?? true;
  String? get error => _error;

  Future<void> iniciar({required bool voz}) async {
    if (_estado != AgenteEstado.desconectado) return;
    _error = null;
    _mensajes.clear();
    _vozActiva = voz;
    _setEstado(AgenteEstado.conectando);
    try {
      final sesion = await agenteService.crearSesion();
      if (!voz) {
        await _iniciarTexto(sesion.signedUrl);
        return;
      }
      try {
        await _iniciarVoz(sesion.conversationToken).timeout(_esperaVoz);
      } catch (e) {
        await _limpiar();
        _error = 'No se pudo usar el micrófono; seguimos por texto.';
        _vozActiva = false;
        await _iniciarTexto(sesion.signedUrl);
      }
    } catch (e) {
      _error = 'No se pudo conectar con el asesor: ${friendlyError(e)}';
      await _limpiar();
      _setEstado(AgenteEstado.desconectado);
    }
  }

  Future<void> _iniciarTexto(String signedUrl) async {
    final ws = AgenteTextoWs(
      onMensajeAgente: (t) {
        _mensajes.add(AgenteMensaje(delAgente: true, texto: t));
        notifyListeners();
      },
      onToolCall: (nombre, params) async {
        final r = await _ejecutarTool(nombre, params);
        return (
          ok: r.success,
          resultado: r.success ? '${r.data}' : '${r.error}'
        );
      },
      onCerrado: _alCerrar,
    );
    _texto = ws;
    await ws.conectar(signedUrl);
    _setEstado(AgenteEstado.conectado);
  }

  Future<void> _iniciarVoz(String conversationToken) async {
    final client = ConversationClient(
      callbacks: ConversationCallbacks(
        onMessage: ({required String message, required Role source}) {
          _mensajes
              .add(AgenteMensaje(delAgente: source == Role.ai, texto: message));
          notifyListeners();
        },
        onModeChange: ({required ConversationMode mode}) {
          _agenteHablando = mode == ConversationMode.speaking;
          notifyListeners();
        },
        onDisconnect: (_) => _alCerrar(null),
        onError: (mensaje, [contexto]) {
          _error = mensaje;
          notifyListeners();
        },
      ),
      clientTools: {
        'mostrar_recomendaciones': _MostrarRecomendacionesTool(this)
      },
    );
    _client = client;
    await client.startSession(conversationToken: conversationToken);
    _vozActiva = true;
    _setEstado(AgenteEstado.conectado);
  }

  Future<ClientToolResult> _ejecutarTool(
      String nombre, Map<String, dynamic> params) async {
    if (nombre != 'mostrar_recomendaciones') {
      return ClientToolResult.failure('herramienta desconocida');
    }
    final p = MostrarRecomendacionesParams.tryParse(params);
    if (p == null) return ClientToolResult.failure('talla inválida');
    final abrir = onMostrarRecomendaciones;
    if (abrir == null) {
      return ClientToolResult.failure('la pantalla no está disponible');
    }
    abrir(p);
    return ClientToolResult.success('pantalla abierta');
  }

  void enviarTexto(String texto) {
    final t = texto.trim();
    if (t.isEmpty || _estado != AgenteEstado.conectado) return;
    _mensajes.add(AgenteMensaje(delAgente: false, texto: t));
    if (_client != null) {
      _client!.sendUserMessage(t);
    } else {
      _texto?.enviarTexto(t);
    }
    notifyListeners();
  }

  Future<void> silenciarMicrofono(bool silenciar) async {
    await _client?.setMicMuted(silenciar);
    notifyListeners();
  }

  Future<void> terminar() async {
    await _limpiar();
    _setEstado(AgenteEstado.desconectado);
  }

  void _alCerrar(String? motivo) {
    final estabaConectado = _estado == AgenteEstado.conectado;
    _client = null;
    _texto = null;
    _agenteHablando = false;
    _vozActiva = false;
    if (motivo != null && motivo.contains('quota')) {
      _error = 'El asesor no tiene créditos disponibles en este momento.';
    } else if (estabaConectado && motivo != null && motivo.isNotEmpty) {
      _error = 'El asesor se desconectó: $motivo';
    }
    _setEstado(AgenteEstado.desconectado);
  }

  Future<void> _limpiar() async {
    final client = _client;
    final texto = _texto;
    _client = null;
    _texto = null;
    _agenteHablando = false;
    _vozActiva = false;
    await texto?.cerrar();
    if (client == null) return;
    try {
      await client.endSession();
    } catch (_) {}
    client.dispose();
  }

  void _setEstado(AgenteEstado e) {
    _estado = e;
    notifyListeners();
  }

  @override
  void dispose() {
    _limpiar();
    super.dispose();
  }
}

class _MostrarRecomendacionesTool implements ClientTool {
  final AgenteClient _agente;
  _MostrarRecomendacionesTool(this._agente);

  @override
  Future<ClientToolResult?> execute(Map<String, dynamic> parameters) =>
      _agente._ejecutarTool('mostrar_recomendaciones', parameters);
}
