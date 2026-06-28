import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:zapateria_flutter/components/image_picker_component.dart';
import 'package:zapateria_flutter/screens/zapato_form_screen.dart';
import 'package:zapateria_flutter/screens/inventario_screen.dart';
import 'package:zapateria_flutter/services/inventario_service.dart';
import 'package:zapateria_flutter/utils/talla_converter.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';
import 'package:zapateria_flutter/components/color_circle.dart';

class ZapatosScreen extends StatefulWidget {
  const ZapatosScreen({super.key});

  @override
  State<ZapatosScreen> createState() => _ZapatosScreenState();
}

class _ZapatosScreenState extends State<ZapatosScreen> with SingleTickerProviderStateMixin {
  List<ZapatoModel> _zapatos = [];
  List<ZapatoModel> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  int _page = 0;
  static const int _perPage = 12;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadZapatos();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    const tipos = [TipoPrecio.publico, TipoPrecio.mayorista, TipoPrecio.inversionista];
    context.read<CartProvider>().setTipoPrecio(tipos[_tabController.index]);
  }

  Future<void> _loadZapatos() async {
    setState(() { _loading = true; _error = null; });
    try {
      _zapatos = await zapatoService.getAll();
      _applyFilter();
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    _filtered = _zapatos.where((z) {
      final q = _searchQuery.toLowerCase();
      return z.nombre.toLowerCase().contains(q) ||
             z.modelo.toLowerCase().contains(q) ||
             z.codigoBarras.contains(_searchQuery);
    }).toList();
    _page = 0;
  }

  List<ZapatoModel> get _paginated => _filtered.skip(_page * _perPage).take(_perPage).toList();
  int get _totalPages => (_filtered.length / _perPage).ceil();

  void _goToPage(int page) {
    setState(() => _page = page);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _loadZapatos();
    if (mounted) setState(() {});
  }

  double _getPrecioForTalla(ZapatoModel zapato, TipoPrecio tipoPrecio, double? talla) {
    final t = talla ?? zapato.medidaInicio.toDouble();
    switch (tipoPrecio) {
      case TipoPrecio.publico: return zapato.getPrecioPublicoForTalla(t);
      case TipoPrecio.mayorista: return zapato.getPrecioCompraForTalla(t) * 1.3;
      case TipoPrecio.inversionista: return zapato.getPrecioCompraForTalla(t) * 1.2;
    }
  }

  void _addToCart(ZapatoModel zapato, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (_) => _AddToCartDialog(
        zapato: zapato,
        tipoPrecio: cartProvider.tipoPrecio,
        onAdd: ({required String? colorId, required String? colorNombre, required List<({double talla, int cantidad})> tallasCantidad}) {
          for (final item in tallasCantidad) {
            cartProvider.addItem(
              zapato,
              item.cantidad,
              _getPrecioForTalla(zapato, cartProvider.tipoPrecio, item.talla),
              colorId: colorId,
              colorNombre: colorNombre,
              talla: item.talla,
            );
          }
          final total = tallasCantidad.fold(0, (s, i) => s + i.cantidad);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${zapato.nombre} agregado al carrito ($total ${total == 1 ? 'par' : 'pares'})')),
          );
        },
      ),
    );
  }

  void _goToInventario(ZapatoModel zapato) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InventarioScreen(zapato: zapato)),
    );
  }

  void _showForm(BuildContext context, ZapatoModel? zapato) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ZapatoFormScreen(zapato: zapato)),
    ).then((_) => _loadZapatos());
  }

  Future<void> _deleteZapato(ZapatoModel zapato) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${zapato.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await zapatoService.delete(zapato.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zapato eliminado')));
        _loadZapatos();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _mergeZapato(ZapatoModel zapato) async {
    final others = _zapatos.where((z) => z.id != zapato.id).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay otros zapatos para unir')));
      return;
    }

    ZapatoModel? selected;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Unir zapato duplicado'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original: ${zapato.nombre} (${zapato.modelo})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Selecciona el duplicado a eliminar:',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: others.map((z) => RadioListTile<ZapatoModel>(
                        value: z,
                        groupValue: selected,
                        title: Text(z.nombre),
                        subtitle: Text('${z.modelo} · ${z.codigoBarras}'),
                        onChanged: (v) => setModal(() => selected = v),
                        dense: true,
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Unir'),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      await zapatoService.merge(zapato.id, selected!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${selected!.nombre}" unido a "${zapato.nombre}"')),
        );
        _loadZapatos();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zapatos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Público'),
            Tab(text: 'Mayorista'),
            Tab(text: 'Inversionista'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, modelo o código...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest ?? Colors.grey[100],
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _applyFilter();
              },
            ),
          ),
          if (!_loading && _error == null)
            _buildTotalBar(theme),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty(context)
                        : kIsWeb
                            ? _buildWebGrid(context, cartProvider)
                            : _buildMobileList(context, cartProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      bottomNavigationBar: (!_loading && _error == null && _filtered.isNotEmpty && _totalPages > 1)
          ? _buildPaginator(theme)
          : null,
    );
  }

  Widget _buildTotalBar(ThemeData theme) {
    final isFiltered = _searchQuery.isNotEmpty;
    final label = isFiltered
        ? '${_filtered.length} resultado${_filtered.length == 1 ? '' : 's'} de ${_zapatos.length} artículos'
        : '${_zapatos.length} artículo${_zapatos.length == 1 ? '' : 's'} en total';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 16, color: theme.hintColor),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildPaginator(ThemeData theme) {
    final pages = _buildPageNumbers();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(
            icon: Icons.chevron_left,
            enabled: _page > 0,
            onTap: () => _goToPage(_page - 1),
          ),
          const SizedBox(width: 4),
          ...pages.map((p) => p == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…', style: TextStyle(fontSize: 14)),
                )
              : _PageButton(
                  label: '${p + 1}',
                  selected: p == _page,
                  onTap: () => _goToPage(p),
                )),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_right,
            enabled: _page < _totalPages - 1,
            onTap: () => _goToPage(_page + 1),
          ),
        ],
      ),
    );
  }

  List<int> _buildPageNumbers() {
    if (_totalPages <= 7) return List.generate(_totalPages, (i) => i);
    final result = <int>[];
    result.add(0);
    if (_page > 2) result.add(-1);
    for (int i = (_page - 1).clamp(1, _totalPages - 2);
         i <= (_page + 1).clamp(1, _totalPages - 2);
         i++) {
      result.add(i);
    }
    if (_page < _totalPages - 3) result.add(-1);
    result.add(_totalPages - 1);
    return result;
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error al conectar con el servidor'),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadZapatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('No hay zapatos registrados', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Registrar primer zapato'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, CartProvider cartProvider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _paginated.length,
        itemBuilder: (context, index) {
          final zapato = _paginated[index];
          return _ZapatoCard(
            zapato: zapato,
            tipoPrecio: cartProvider.tipoPrecio,
            onEdit: () => _showForm(context, zapato),
            onAddToCart: () => _addToCart(zapato, cartProvider),
            onDelete: () => _deleteZapato(zapato),
            onInventario: () => _goToInventario(zapato),
            onMerge: () => _mergeZapato(zapato),
          );
        },
      ),
    );
  }

  Widget _buildWebGrid(BuildContext context, CartProvider cartProvider) {
    final items = _paginated;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 240).floor().clamp(2, 7);
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final zapato = items[index];
            return _ZapatoGridCard(
              zapato: zapato,
              tipoPrecio: cartProvider.tipoPrecio,
              onEdit: () => _showForm(context, zapato),
              onAddToCart: () => _addToCart(zapato, cartProvider),
              onDelete: () => _deleteZapato(zapato),
              onInventario: () => _goToInventario(zapato),
              onMerge: () => _mergeZapato(zapato),
            );
          },
        );
      },
    );
  }
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: selected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? onTap : null,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 18, color: enabled ? color : theme.disabledColor)
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: enabled ? color : theme.disabledColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZapatoCard extends StatelessWidget {
  final ZapatoModel zapato;
  final TipoPrecio tipoPrecio;
  final VoidCallback onEdit;
  final VoidCallback onAddToCart;
  final VoidCallback onDelete;
  final VoidCallback onInventario;
  final VoidCallback onMerge;

  const _ZapatoCard({
    required this.zapato,
    required this.tipoPrecio,
    required this.onEdit,
    required this.onAddToCart,
    required this.onDelete,
    required this.onInventario,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double precio;
    switch (tipoPrecio) {
      case TipoPrecio.publico: precio = zapato.precioPublico; break;
      case TipoPrecio.mayorista: precio = zapato.precioCompra * 1.3; break;
      case TipoPrecio.inversionista: precio = zapato.precioCompra * 1.2; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: _ZapatoCarousel(fotos: _getEffectiveFotos(zapato)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zapato.nombre, style: theme.textTheme.titleMedium),
                      Text(zapato.modelo, style: theme.textTheme.bodySmall),
                      Text('\$${formatPrice(precio)}', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Carrito',
                  onPressed: onAddToCart,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.inventory_2_outlined),
                  tooltip: 'Inventario',
                  onPressed: onInventario,
                ),
                IconButton(
                  icon: const Icon(Icons.merge_type),
                  tooltip: 'Unir duplicado',
                  onPressed: onMerge,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (zapato.colores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: zapato.colores.map((zc) => ColorCircle(color: zc.color, size: 24)).toList(),
              ),
            ],
            if (zapato.horma != Horma.normal || zapato.categoria != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (zapato.horma != Horma.normal)
                      _HormaBadge(horma: zapato.horma),
                    if (zapato.categoria != null)
                      Text('Categoría: ${zapato.categoria!.nombre}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZapatoGridCard extends StatelessWidget {
  final ZapatoModel zapato;
  final TipoPrecio tipoPrecio;
  final VoidCallback onEdit;
  final VoidCallback onAddToCart;
  final VoidCallback onDelete;
  final VoidCallback onInventario;
  final VoidCallback onMerge;

  const _ZapatoGridCard({
    required this.zapato,
    required this.tipoPrecio,
    required this.onEdit,
    required this.onAddToCart,
    required this.onDelete,
    required this.onInventario,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double precio;
    switch (tipoPrecio) {
      case TipoPrecio.publico: precio = zapato.precioPublico; break;
      case TipoPrecio.mayorista: precio = zapato.precioCompra * 1.3; break;
      case TipoPrecio.inversionista: precio = zapato.precioCompra * 1.2; break;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _ZapatoCarousel(
              fotos: _getEffectiveFotos(zapato),
              borderRadius: BorderRadius.zero,
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zapato.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    zapato.modelo,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${formatPrice(precio)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (zapato.categoria != null)
                    Text(
                      zapato.categoria!.nombre,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (zapato.colores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 3,
                        children: zapato.colores.take(6).map((zc) => ColorCircle(color: zc.color, size: 14)).toList(),
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEdit,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Icon(Icons.edit, size: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAddToCart,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Icon(Icons.shopping_cart, size: 15),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.inventory_2_outlined, size: 18),
                          tooltip: 'Inventario',
                          onPressed: onInventario,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.merge_type, size: 18),
                          tooltip: 'Unir duplicado',
                          onPressed: onMerge,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _getEffectiveFotos(ZapatoModel z) {
  if (z.fotos.isNotEmpty) return z.fotos;
  if (z.foto != null && z.foto!.isNotEmpty) return [z.foto!];
  return [];
}

class _ZapatoCarousel extends StatefulWidget {
  final List<String> fotos;
  final BorderRadius borderRadius;

  const _ZapatoCarousel({
    required this.fotos,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ZapatoCarousel> createState() => _ZapatoCarouselState();
}

class _ZapatoCarouselState extends State<_ZapatoCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotos;

    if (fotos.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          color: Colors.grey[200],
          child: Center(child: Icon(Icons.inventory_2, color: Colors.grey[400])),
        ),
      );
    }

    if (fotos.length == 1) {
      return GestureDetector(
        onTap: () => showPhotoLightbox(context, fotos, 0),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: ZapatoImage(imageUrl: fotos[0], height: double.infinity, width: double.infinity, borderRadius: 0),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: fotos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => showPhotoLightbox(context, fotos, _currentIndex),
              child: ZapatoImage(imageUrl: fotos[i], height: double.infinity, width: double.infinity, borderRadius: 0),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(fotos.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: _currentIndex == i ? 12 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentIndex == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

String _tallaDialogLabel(double t) =>
    t % 1 == 0 ? t.toInt().toString() : t.toString();

class _HormaBadge extends StatelessWidget {
  final Horma horma;
  const _HormaBadge({required this.horma});

  @override
  Widget build(BuildContext context) {
    final isAmplio = horma == Horma.amplio;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAmplio ? Colors.blue.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        horma.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isAmplio ? Colors.blue.shade800 : Colors.orange.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Add-to-cart dialog with color + talla selection ───────────────────────────

class _AddToCartDialog extends StatefulWidget {
  final ZapatoModel zapato;
  final TipoPrecio tipoPrecio;
  final void Function({
    required String? colorId,
    required String? colorNombre,
    required List<({double talla, int cantidad})> tallasCantidad,
  }) onAdd;

  const _AddToCartDialog({
    required this.zapato,
    required this.tipoPrecio,
    required this.onAdd,
  });

  @override
  State<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<_AddToCartDialog> {
  String? _selectedColorId;
  final Map<double, int> _selectedTallas = {};
  List<InventarioItemModel> _inventario = [];
  bool _loadingInv = true;

  List<double> get _tallas {
    final s = widget.zapato.medidaInicio;
    final e = widget.zapato.medidaFin;
    if (e < s) return [];
    final result = <double>[];
    for (var t = s; t <= e; t++) {
      result.add(t.toDouble());
      if (t < e) result.add(t + 0.5);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    if (widget.zapato.colores.isNotEmpty) {
      _selectedColorId = widget.zapato.colores.first.colorId;
    }
    _loadInventario();
  }

  Future<void> _loadInventario() async {
    try {
      final items = await inventarioService.getByZapato(widget.zapato.id);
      if (mounted) setState(() { _inventario = items; _loadingInv = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingInv = false);
    }
  }

  int _stock(String? colorId, double? talla) {
    if (colorId == null || talla == null) return 0;
    try {
      return _inventario
          .firstWhere((i) => i.colorId == colorId && i.talla == talla)
          .cantidad;
    } catch (_) {
      return 0;
    }
  }

  int get _totalItems => _selectedTallas.values.fold(0, (s, q) => s + q);

  double _priceForTalla(double t) {
    switch (widget.tipoPrecio) {
      case TipoPrecio.publico: return widget.zapato.getPrecioPublicoForTalla(t);
      case TipoPrecio.mayorista: return widget.zapato.getPrecioCompraForTalla(t) * 1.3;
      case TipoPrecio.inversionista: return widget.zapato.getPrecioCompraForTalla(t) * 1.2;
    }
  }

  double get _totalPrice {
    double total = 0;
    _selectedTallas.forEach((talla, qty) => total += _priceForTalla(talla) * qty);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colores = widget.zapato.colores;
    final tallas = _tallas;
    final colorNombre = colores.isEmpty
        ? null
        : colores.firstWhere((c) => c.colorId == _selectedColorId,
              orElse: () => colores.first)
            .color
            .nombre;
    final horma = widget.zapato.horma;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.zapato.nombre, style: theme.textTheme.titleMedium)),
          if (horma != Horma.normal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: horma == Horma.amplio
                    ? Colors.blue.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                horma.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: horma == Horma.amplio
                      ? Colors.blue.shade800
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color selection
            if (colores.isNotEmpty) ...[
              Text('Color', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colores.map((zc) {
                  final selected = _selectedColorId == zc.colorId;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedColorId = zc.colorId;
                      _selectedTallas.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? theme.colorScheme.primary : theme.dividerColor,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: selected ? theme.colorScheme.primaryContainer : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ColorCircle(color: zc.color, size: 16),
                          const SizedBox(width: 6),
                          Text(zc.color.nombre, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Talla selection (multi-select: toca para añadir cantidad, badge muestra el total)
            if (tallas.isNotEmpty) ...[
              Text('Tallas  •  toca para seleccionar', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 10,
                children: tallas.map((t) {
                  final count = _selectedTallas[t] ?? 0;
                  final stock = _loadingInv ? -1 : _stock(_selectedColorId, t);
                  final sinStock = !_loadingInv && stock == 0;
                  final selected = count > 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: sinStock ? null : () {
                          setState(() {
                            final current = _selectedTallas[t] ?? 0;
                            final maxCount = (!_loadingInv && stock > 0) ? stock : 10;
                            if (current < maxCount) {
                              _selectedTallas[t] = current + 1;
                            } else {
                              _selectedTallas.remove(t);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : sinStock
                                      ? theme.disabledColor.withOpacity(0.3)
                                      : theme.dividerColor,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: selected
                                ? theme.colorScheme.primaryContainer
                                : sinStock
                                    ? theme.disabledColor.withOpacity(0.05)
                                    : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'MX ${_tallaDialogLabel(t)}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: sinStock ? theme.disabledColor : theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'EU ${_tallaDialogLabel(mxToEu(t))}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: sinStock ? theme.disabledColor : theme.hintColor,
                                ),
                              ),
                              Text(
                                'US ${_tallaDialogLabel(mxToUs(t))}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: sinStock ? theme.disabledColor : theme.hintColor,
                                ),
                              ),
                              if (!_loadingInv)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: stock > 0 ? Colors.green.shade100 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    stock > 0 ? '$stock' : '–',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: stock > 0 ? Colors.green.shade800 : theme.disabledColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Badge con la cantidad seleccionada; tócalo para quitar la talla
                      if (count > 0)
                        Positioned(
                          top: -7,
                          right: -7,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTallas.remove(t)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Resumen de selección
            if (_selectedTallas.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedTallas.entries
                            .map((e) => 'T${_tallaDialogLabel(e.key)}${e.value > 1 ? ' ×${e.value}' : ''}')
                            .join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Text(
              _totalItems > 0
                  ? '\$${formatPrice(_totalPrice)} · $_totalItems ${_totalItems == 1 ? 'par' : 'pares'}'
                  : 'Sin selección',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _totalItems > 0 ? Colors.green.shade700 : theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _totalItems == 0
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onAdd(
                        colorId: _selectedColorId,
                        colorNombre: colorNombre,
                        tallasCantidad: _selectedTallas.entries
                            .map((e) => (talla: e.key, cantidad: e.value))
                            .toList(),
                      );
                    },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ],
    );
  }
}
