import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/components/neo_style.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/agente_service.dart';
import 'package:zapateria_flutter/services/categoria_service.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/utils/error_utils.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:zapateria_flutter/utils/recomendaciones_utils.dart';

/// Lista final que arma el asesor: SOLO la talla pedida (y la categoría, si el
/// cliente la dijo). Primero lo que recomendó el agente, luego el resto del stock.
class RecomendacionesScreen extends StatefulWidget {
  final double talla;
  final String? categoriaId;
  final String? colorId;
  final List<String> zapatoIdsRecomendados;

  const RecomendacionesScreen({
    super.key,
    required this.talla,
    this.categoriaId,
    this.colorId,
    this.zapatoIdsRecomendados = const [],
  });

  @override
  State<RecomendacionesScreen> createState() => _RecomendacionesScreenState();
}

class _RecomendacionesScreenState extends State<RecomendacionesScreen> {
  late String? _categoriaId = widget.categoriaId;
  String? _categoriaNombre;
  InventarioTallaModel? _inventario;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inventario = await agenteService.inventarioPorTalla(
        widget.talla,
        categoriaId: _categoriaId,
      );
      String? nombre;
      if (_categoriaId != null) {
        nombre = inventario.items.firstOrNull?.categoria;
        nombre ??= (await categoriaService.getAll())
            .where((c) => c.id == _categoriaId)
            .firstOrNull
            ?.nombre;
      }
      if (!mounted) return;
      setState(() {
        _inventario = inventario;
        _categoriaNombre = nombre;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _quitarCategoria() {
    _categoriaId = null;
    _categoriaNombre = null;
    _cargar();
  }

  String get _tallaTexto =>
      widget.talla == widget.talla.roundToDouble() ? widget.talla.toInt().toString() : widget.talla.toString();

  @override
  Widget build(BuildContext context) {
    final t = NeoTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: Text('Talla $_tallaTexto'),
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar', onPressed: _loading ? null : _cargar)],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
          ]),
        ),
      );
    }

    final items = _inventario!.items;
    final secciones = separarRecomendados(items, widget.zapatoIdsRecomendados);
    final chipCategoria = _categoriaId == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_categoriaNombre ?? 'Categoría'),
                onDeleted: _quitarCategoria,
                deleteButtonTooltipMessage: 'Quitar filtro de categoría',
              ),
            ),
          );

    if (items.isEmpty) {
      return Column(children: [
        if (chipCategoria != null) chipCategoria,
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _categoriaId == null
                    ? 'No hay existencias en talla $_tallaTexto.'
                    : 'No hay ${_categoriaNombre ?? 'de esa categoría'} en talla $_tallaTexto. Quita el filtro para ver todo lo demás.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ]);
    }

    const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 460,
      mainAxisExtent: 188,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
    SliverPadding grid(List<InventarioTallaItemModel> lista, {required bool recomendado}) => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            gridDelegate: delegate,
            itemCount: lista.length,
            itemBuilder: (_, i) => _TarjetaZapato(
              item: lista[i],
              talla: widget.talla,
              colorIdSugerido: widget.colorId,
              recomendado: recomendado,
            ),
          ),
        );
    Widget titulo(String texto) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(texto, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
        );

    return CustomScrollView(slivers: [
      if (chipCategoria != null) SliverToBoxAdapter(child: chipCategoria),
      if (secciones.recomendados.isNotEmpty) ...[
        titulo('Recomendados'),
        grid(secciones.recomendados, recomendado: true),
      ],
      if (secciones.resto.isNotEmpty) ...[
        titulo(secciones.recomendados.isEmpty ? 'En existencia en talla $_tallaTexto' : 'Más en talla $_tallaTexto'),
        grid(secciones.resto, recomendado: false),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }
}

class _TarjetaZapato extends StatefulWidget {
  final InventarioTallaItemModel item;
  final double talla;
  final String? colorIdSugerido;
  final bool recomendado;

  const _TarjetaZapato({
    required this.item,
    required this.talla,
    required this.colorIdSugerido,
    required this.recomendado,
  });

  @override
  State<_TarjetaZapato> createState() => _TarjetaZapatoState();
}

class _TarjetaZapatoState extends State<_TarjetaZapato> {
  late VarianteTallaModel _variante = widget.item.variantes.firstWhere(
    (v) => v.colorId != null && v.colorId == widget.colorIdSugerido,
    orElse: () => widget.item.variantes.first,
  );
  bool _agregando = false;

  // Misma regla de precios que ZapatosScreen para el tipo de precio del carrito.
  double _precioParaCarrito(ZapatoModel zapato, TipoPrecio tipo) {
    switch (tipo) {
      case TipoPrecio.publico:
        return zapato.getPrecioPublicoForTalla(widget.talla);
      case TipoPrecio.mayorista:
        return zapato.getPrecioCompraForTalla(widget.talla) * 1.3;
      case TipoPrecio.inversionista:
        return zapato.getPrecioCompraForTalla(widget.talla) * 1.2;
    }
  }

  Future<void> _agregar(CartProvider cart) async {
    setState(() => _agregando = true);
    try {
      final zapato = await zapatoService.getOne(widget.item.zapatoId);
      if (!mounted) return;
      // Se vuelve a calcular con el carrito actual: pudo cambiar durante la carga.
      final libre = disponibleParaAgregar(
        cart.items,
        zapatoId: zapato.id,
        colorId: _variante.colorId,
        talla: widget.talla,
        existencia: _variante.cantidad,
      );
      if (libre <= 0) {
        _aviso('Ya tienes todas las existencias de esta variante en el carrito');
        return;
      }
      cart.addItem(
        zapato,
        1,
        _precioParaCarrito(zapato, cart.tipoPrecio),
        colorId: _variante.colorId,
        colorNombre: _variante.color,
        talla: widget.talla,
      );
      _aviso('${zapato.nombre} agregado al carrito');
    } catch (e) {
      if (mounted) _aviso('Error: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _agregando = false);
    }
  }

  void _aviso(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final t = NeoTheme.of(context);
    final cart = context.watch<CartProvider>();
    final libre = disponibleParaAgregar(
      cart.items,
      zapatoId: item.zapatoId,
      colorId: _variante.colorId,
      talla: widget.talla,
      existencia: _variante.cantidad,
    );

    return NeoCard(
      color: widget.recomendado ? NeoColors.accent.withValues(alpha: 0.18) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ZapatoImage(imageUrl: item.foto, height: 96, width: 96, borderRadius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(
              [item.modelo, if (item.categoria != null) item.categoria!].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: t.ink.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 2),
            Text(formatCurrency(item.precioPublico), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            // Una sola fila desplazable: con muchos colores no crece la tarjeta.
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.variantes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final v = item.variantes[i];
                  return ChoiceChip(
                    label: Text('${v.color ?? 'Sin color'} ×${v.cantidad}', style: const TextStyle(fontSize: 12)),
                    selected: v == _variante,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => setState(() => _variante = v),
                  );
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_agregando || libre <= 0) ? null : () => _agregar(cart),
                icon: _agregando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(libre <= 0 ? 'Todo en el carrito' : 'Agregar al carrito'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
