import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/neo_style.dart';
import 'package:zapateria_flutter/screens/recomendaciones_screen.dart';
import 'package:zapateria_flutter/services/agente_client.dart';

/// Chat con el asesor de ventas (agente de ElevenLabs). El vendedor habla o
/// escribe lo que pide el cliente; el agente pregunta lo siguiente y, cuando
/// tiene suficiente, abre [RecomendacionesScreen].
class AsesorScreen extends StatefulWidget {
  /// true mientras esta pestaña es la visible. Al salir se cierra la sesión:
  /// cada minuto abierto consume créditos de ElevenLabs.
  final bool activo;

  /// Solo para pruebas.
  final AgenteClient? client;

  const AsesorScreen({super.key, this.activo = true, this.client});

  @override
  State<AsesorScreen> createState() => _AsesorScreenState();
}

class _AsesorScreenState extends State<AsesorScreen> {
  late final AgenteClient _agente = widget.client ?? AgenteClient();
  final _texto = TextEditingController();
  final _scroll = ScrollController();
  MostrarRecomendacionesParams? _ultimas;
  Route<void>? _rutaRecomendaciones;

  @override
  void initState() {
    super.initState();
    _agente.onMostrarRecomendaciones = _abrirRecomendaciones;
    _agente.addListener(_alCambiar);
  }

  @override
  void didUpdateWidget(AsesorScreen old) {
    super.didUpdateWidget(old);
    if (old.activo && !widget.activo) _agente.terminar();
  }

  @override
  void dispose() {
    _agente.removeListener(_alCambiar);
    _agente.onMostrarRecomendaciones = null;
    if (widget.client == null) _agente.dispose();
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _alCambiar() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _abrirRecomendaciones(MostrarRecomendacionesParams p) {
    if (!mounted) return;
    _ultimas = p;
    final ruta = MaterialPageRoute<void>(
      builder: (_) => RecomendacionesScreen(
        talla: p.talla,
        categoriaId: p.categoriaId,
        colorId: p.colorId,
        zapatoIdsRecomendados: p.zapatoIds,
      ),
    );
    ruta.popped.then((_) {
      if (_rutaRecomendaciones == ruta) _rutaRecomendaciones = null;
    });
    final navigator = Navigator.of(context);
    // Si el agente vuelve a llamar con la pantalla ya abierta, se reemplaza.
    if (_rutaRecomendaciones != null) {
      _rutaRecomendaciones = ruta;
      navigator.pushReplacement(ruta);
    } else {
      _rutaRecomendaciones = ruta;
      navigator.push(ruta);
    }
  }

  /// Botón manual: usa lo último que mandó el agente; si no hay nada, pide la talla.
  Future<void> _verRecomendaciones() async {
    final previas = _ultimas;
    if (previas != null) {
      _abrirRecomendaciones(previas);
      return;
    }
    final talla = await _pedirTalla();
    if (talla == null || !mounted) return;
    _abrirRecomendaciones(
        MostrarRecomendacionesParams(talla: talla, zapatoIds: const []));
  }

  Future<double?> _pedirTalla() {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué talla busca?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Ej. 23 o 23.5'),
          onSubmitted: (v) =>
              Navigator.pop(ctx, double.tryParse(v.replaceAll(',', '.'))),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final t = double.tryParse(ctrl.text.replaceAll(',', '.'));
              Navigator.pop(ctx, (t != null && t > 0) ? t : null);
            },
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }

  void _enviar() {
    _agente.enviarTexto(_texto.text);
    _texto.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeoTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: const Text('Asesor'),
        actions: [
          TextButton.icon(
            onPressed: _verRecomendaciones,
            icon: const Icon(Icons.list_alt),
            label: const Text('Ver recomendaciones'),
          ),
          if (_agente.estado == AgenteEstado.conectado)
            IconButton(
              icon: const Icon(Icons.call_end),
              tooltip: 'Terminar conversación',
              onPressed: _agente.terminar,
            ),
        ],
      ),
      body: switch (_agente.estado) {
        AgenteEstado.desconectado => _inicio(context),
        AgenteEstado.conectando =>
          const Center(child: CircularProgressIndicator()),
        AgenteEstado.conectado => _conversacion(context),
      },
    );
  }

  Widget _inicio(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: NeoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asesor de ventas',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Cuéntale qué busca el cliente. El asesor te dice qué preguntarle y, con lo que hay en existencia, te arma la lista para ofrecer.',
                  ),
                  if (_agente.error != null) ...[
                    const SizedBox(height: 12),
                    _avisoError(context, _agente.error!),
                  ],
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    FilledButton.icon(
                      onPressed: () => _agente.iniciar(voz: true),
                      icon: const Icon(Icons.mic),
                      label: const Text('Hablar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _agente.iniciar(voz: false),
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Escribir'),
                    ),
                  ]),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _avisoError(BuildContext context, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer),
        const SizedBox(width: 8),
        Expanded(
            child: Text(texto,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer))),
      ]),
    );
  }

  Widget _conversacion(BuildContext context) {
    final t = NeoTheme.of(context);
    final mensajes = _agente.mensajes;
    return Column(children: [
      if (_agente.error != null)
        Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _avisoError(context, _agente.error!)),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          itemCount: mensajes.length,
          itemBuilder: (_, i) {
            final m = mensajes[i];
            return Align(
              alignment:
                  m.delAgente ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: m.delAgente ? t.paper : NeoColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.ink, width: 2),
                ),
                child: Text(m.texto,
                    style: TextStyle(
                        color: m.delAgente ? t.ink : NeoColors.inkLight)),
              ),
            );
          },
        ),
      ),
      if (_agente.agenteHablando)
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child:
              Text('El asesor está hablando…', style: TextStyle(fontSize: 12)),
        ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(children: [
            if (_agente.vozActiva)
              IconButton(
                icon: Icon(
                    _agente.microfonoSilenciado ? Icons.mic_off : Icons.mic),
                tooltip: _agente.microfonoSilenciado
                    ? 'Activar micrófono'
                    : 'Silenciar micrófono',
                onPressed: () =>
                    _agente.silenciarMicrofono(!_agente.microfonoSilenciado),
              ),
            Expanded(
              child: TextField(
                controller: _texto,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                    hintText: 'Escribe lo que pide el cliente',
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
                onPressed: _enviar,
                icon: const Icon(Icons.send),
                tooltip: 'Enviar'),
          ]),
        ),
      ),
    ]);
  }
}
