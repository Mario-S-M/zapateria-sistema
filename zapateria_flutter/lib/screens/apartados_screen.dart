import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zapateria_flutter/components/apartado_dialogs.dart';
import 'package:zapateria_flutter/components/neo_style.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/models/ticket_data.dart';
import 'package:zapateria_flutter/screens/ticket_screen.dart';
import 'package:zapateria_flutter/services/apartado_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

/// Arma el ticket de un apartado con su histórico de abonos.
TicketData ticketFromApartado(ApartadoModel a) {
  String tipo;
  switch (a.tipoPrecio) {
    case TipoPrecio.publico: tipo = 'PÚBLICO'; break;
    case TipoPrecio.mayorista: tipo = 'MAYORISTA'; break;
    case TipoPrecio.inversionista: tipo = 'INVERSIONISTA'; break;
  }
  return TicketData(
    folio: a.folio,
    fecha: a.fecha.toLocal(),
    items: a.items
        .map((i) => TicketItem(
              nombre: i.zapato?.nombre ?? 'Zapato',
              modelo: i.zapato?.modelo ?? '',
              color: i.colorNombre,
              talla: i.talla,
              cantidad: i.cantidad,
              precioUnitario: i.precioUnitario,
            ))
        .toList(),
    total: a.total,
    metodoPago: '',
    tipoPrecio: tipo,
    inversionistaNombre: a.inversionista?.nombre,
    clienteNombre: a.clienteNombre,
    clienteTelefono: a.clienteTelefono,
    abonos: a.abonos
        .map((x) => TicketAbono(
              fecha: x.fecha.toLocal(),
              monto: x.monto,
              metodoPago: x.metodoPagoLabel,
            ))
        .toList(),
    saldo: a.saldo,
  );
}

class ApartadosScreen extends StatefulWidget {
  const ApartadosScreen({super.key});

  @override
  State<ApartadosScreen> createState() => _ApartadosScreenState();
}

class _ApartadosScreenState extends State<ApartadosScreen> {
  static const int _perPage = 12;

  List<ApartadoModel> _apartados = [];
  bool _loading = true;
  int _page = 0;
  int _totalPages = 1;
  EstadoApartado _filtro = EstadoApartado.activo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await apartadoService.getAll(
          estado: _filtro, page: _page + 1, limit: _perPage);
      _apartados = result.data;
      _totalPages = result.totalPages;
      if (_apartados.isEmpty && _page > 0) {
        _page -= 1;
        return _load();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abonar(ApartadoModel a) async {
    final data = await showAbonoDialog(context, saldo: a.saldo);
    if (data == null) return;
    try {
      final updated = await apartadoService.addAbono(a.id, data.monto, data.metodo);
      await _load();
      if (!mounted) return;
      final imprimir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Abono registrado'),
          content: Text(updated.liquidado
              ? 'El apartado quedó liquidado. Ya puedes entregarlo.'
              : 'Saldo pendiente: \$${formatPrice(updated.saldo)}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cerrar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Imprimir ticket')),
          ],
        ),
      );
      if (imprimir == true) _imprimir(updated);
    } catch (e) {
      _snack(apartadoErrorMessage(e));
    }
  }

  void _imprimir(ApartadoModel a) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketScreen(ticket: ticketFromApartado(a))),
    );
  }

  Future<bool> _confirmar(String titulo, String mensaje, String accion, {Color? color}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          ElevatedButton(
            style: color == null ? null : ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _entregar(ApartadoModel a) async {
    if (!await _confirmar('Entregar apartado',
        '${a.clienteNombre} recibirá sus zapatos y se registrará como venta por \$${formatPrice(a.total)}.',
        'Entregar')) {
      return;
    }
    try {
      await apartadoService.entregar(a.id);
      _snack('Apartado entregado y registrado en Ventas');
      await _load();
    } catch (e) {
      _snack(apartadoErrorMessage(e));
    }
  }

  Future<void> _cancelar(ApartadoModel a) async {
    if (!await _confirmar('Cancelar apartado',
        'Los zapatos regresan al inventario. Los abonos (\$${formatPrice(a.totalAbonado)}) quedan registrados; el reembolso lo decides tú.',
        'Cancelar apartado',
        color: Colors.red)) {
      return;
    }
    try {
      await apartadoService.cancelar(a.id);
      await _load();
    } catch (e) {
      _snack(apartadoErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget list;
    if (_loading) {
      list = const Center(child: CircularProgressIndicator());
    } else if (_apartados.isEmpty) {
      list = Center(child: Text('No hay apartados', style: theme.textTheme.bodyLarge));
    } else {
      list = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: EdgeInsets.all(kIsWeb ? 24 : 12),
          itemCount: _apartados.length,
          itemBuilder: (context, i) {
            final a = _apartados[i];
            return _ApartadoCard(
              apartado: a,
              onAbonar: () => _abonar(a),
              onImprimir: () => _imprimir(a),
              onEntregar: () => _entregar(a),
              onCancelar: () => _cancelar(a),
            );
          },
        ),
      );
    }

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<EstadoApartado>(
              segments: const [
                ButtonSegment(value: EstadoApartado.activo, label: Text('Activos')),
                ButtonSegment(value: EstadoApartado.entregado, label: Text('Entregados')),
                ButtonSegment(value: EstadoApartado.cancelado, label: Text('Cancelados')),
              ],
              selected: {_filtro},
              onSelectionChanged: (s) {
                setState(() {
                  _filtro = s.first;
                  _page = 0;
                });
                _load();
              },
            ),
          ),
        ),
        Expanded(child: list),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Apartados')),
      body: kIsWeb
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body),
            )
          : body,
      bottomNavigationBar: (!_loading && _totalPages > 1)
          ? NeoPaginator(
              page: _page,
              totalPages: _totalPages,
              onPageChanged: (p) {
                setState(() => _page = p);
                _load();
              },
            )
          : null,
    );
  }
}

class _ApartadoCard extends StatelessWidget {
  final ApartadoModel apartado;
  final VoidCallback onAbonar;
  final VoidCallback onImprimir;
  final VoidCallback onEntregar;
  final VoidCallback onCancelar;

  const _ApartadoCard({
    required this.apartado,
    required this.onAbonar,
    required this.onImprimir,
    required this.onEntregar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = apartado;
    final activo = a.estado == EstadoApartado.activo;
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');

    Color estadoColor;
    String estadoLabel;
    switch (a.estado) {
      case EstadoApartado.activo: estadoColor = Colors.orange; estadoLabel = 'ACTIVO'; break;
      case EstadoApartado.entregado: estadoColor = Colors.green; estadoLabel = 'ENTREGADO'; break;
      case EstadoApartado.cancelado: estadoColor = Colors.red; estadoLabel = 'CANCELADO'; break;
    }

    return NeoCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Expanded(
                child: Text(a.clienteNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: estadoColor, width: 1.5),
                ),
                child: Text(estadoLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: estadoColor)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                Text('${a.folio} · ${fmt.format(a.fecha.toLocal())}', style: theme.textTheme.bodySmall),
                Text('Total \$${formatPrice(a.total)}', style: theme.textTheme.bodySmall),
                Text('Abonado \$${formatPrice(a.totalAbonado)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                if (activo)
                  Text('Saldo \$${formatPrice(a.saldo)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          children: [
            if (a.clienteTelefono != null && a.clienteTelefono!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 6),
                  Text(a.clienteTelefono!),
                ]),
              ),
            for (final i in a.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.cantidad}× ${i.zapato?.nombre ?? 'Zapato'}'
                        '${i.zapato != null && i.zapato!.modelo.isNotEmpty ? ' ${i.zapato!.modelo}' : ''}'
                        '${[
                          if (i.colorNombre != null) i.colorNombre!,
                          if (i.talla != null) 'T${i.talla! % 1 == 0 ? i.talla!.toInt() : i.talla}',
                        ].isEmpty ? '' : '  (${[
                            if (i.colorNombre != null) i.colorNombre!,
                            if (i.talla != null) 'T${i.talla! % 1 == 0 ? i.talla!.toInt() : i.talla}',
                          ].join(' · ')})'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text('\$${formatPrice(i.subtotal)}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            const Divider(height: 24),
            Text('Abonos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            if (a.abonos.isEmpty) const Text('Sin abonos todavía'),
            for (var n = 0; n < a.abonos.length; n++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      a.abonos[n].metodoPago == MetodoAbono.tarjeta
                          ? Icons.credit_card
                          : Icons.payments_outlined,
                      size: 16,
                      color: a.abonos[n].metodoPago == MetodoAbono.tarjeta ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${n + 1}. ${fmt.format(a.abonos[n].fecha.toLocal())} · ${a.abonos[n].metodoPagoLabel}'),
                    ),
                    Text('\$${formatPrice(a.abonos[n].monto)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (activo && !a.liquidado)
                  ElevatedButton.icon(
                    onPressed: onAbonar,
                    icon: const Icon(Icons.add),
                    label: const Text('Abonar'),
                  ),
                OutlinedButton.icon(
                  onPressed: onImprimir,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Ticket'),
                ),
                if (activo)
                  Tooltip(
                    message: a.liquidado
                        ? 'Marcar como entregado'
                        : 'Falta liquidar \$${formatPrice(a.saldo)}',
                    child: ElevatedButton.icon(
                      onPressed: a.liquidado ? onEntregar : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Entregar'),
                    ),
                  ),
                if (activo)
                  TextButton.icon(
                    onPressed: onCancelar,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
