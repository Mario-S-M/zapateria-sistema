import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/services/api_client.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:zapateria_flutter/screens/zapato_form_screen.dart';
import 'package:zapateria_flutter/screens/inventario_screen.dart';
import 'package:zapateria_flutter/services/inventario_service.dart';
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

  double _getPrecio(ZapatoModel zapato, TipoPrecio tipoPrecio) {
    switch (tipoPrecio) {
      case TipoPrecio.publico: return zapato.precioPublico;
      case TipoPrecio.mayorista: return zapato.precioCompra * 1.3;
      case TipoPrecio.inversionista: return zapato.precioCompra * 1.2;
    }
  }

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

  void _addToCart(ZapatoModel zapato, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (_) => _AddToCartDialog(
        zapato: zapato,
        precio: _getPrecio(zapato, cartProvider.tipoPrecio),
        onAdd: ({required String? colorId, required String? colorNombre, required double? talla}) {
          cartProvider.addItem(
            zapato,
            1,
            _getPrecio(zapato, cartProvider.tipoPrecio),
            colorId: colorId,
            colorNombre: colorNombre,
            talla: talla,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${zapato.nombre} agregado al carrito')),
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
          if (!_loading && _error == null && _filtered.isNotEmpty && _totalPages > 1)
            _buildPaginator(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
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

  const _ZapatoCard({
    required this.zapato,
    required this.tipoPrecio,
    required this.onEdit,
    required this.onAddToCart,
    required this.onDelete,
    required this.onInventario,
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
                ZapatoImage(imageUrl: zapato.foto, height: 80, width: 80),
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('Carrito'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.inventory_2_outlined),
                  tooltip: 'Inventario',
                  onPressed: onInventario,
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
            if (zapato.categoria != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Categoría: ${zapato.categoria!.nombre}', style: theme.textTheme.bodySmall),
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

  const _ZapatoGridCard({
    required this.zapato,
    required this.tipoPrecio,
    required this.onEdit,
    required this.onAddToCart,
    required this.onDelete,
    required this.onInventario,
  });

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    String path = url;
    if (url.startsWith('http')) {
      path = Uri.parse(url).path.replaceFirst(RegExp(r'^/'), '');
    }
    if (path.startsWith('api/')) path = path.substring(4);
    return '$baseUrl/$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double precio;
    switch (tipoPrecio) {
      case TipoPrecio.publico: precio = zapato.precioPublico; break;
      case TipoPrecio.mayorista: precio = zapato.precioCompra * 1.3; break;
      case TipoPrecio.inversionista: precio = zapato.precioCompra * 1.2; break;
    }

    final imageUrl = _resolveUrl(zapato.foto);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: imageUrl.isEmpty
                ? Container(
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.inventory_2, size: 40, color: Colors.grey[400])),
                  )
                : Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
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

String _tallaDialogLabel(double t) =>
    t % 1 == 0 ? t.toInt().toString() : t.toString();

// ── Add-to-cart dialog with color + talla selection ───────────────────────────

class _AddToCartDialog extends StatefulWidget {
  final ZapatoModel zapato;
  final double precio;
  final void Function({
    required String? colorId,
    required String? colorNombre,
    required double? talla,
  }) onAdd;

  const _AddToCartDialog({
    required this.zapato,
    required this.precio,
    required this.onAdd,
  });

  @override
  State<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<_AddToCartDialog> {
  String? _selectedColorId;
  double? _selectedTalla;
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
    if (_tallas.isNotEmpty) _selectedTalla = _tallas.first;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colores = widget.zapato.colores;
    final tallas = _tallas;
    final stockActual = _stock(_selectedColorId, _selectedTalla);
    final colorNombre = colores.isEmpty
        ? null
        : colores.firstWhere((c) => c.colorId == _selectedColorId,
              orElse: () => colores.first)
            .color
            .nombre;

    return AlertDialog(
      title: Text(widget.zapato.nombre, style: theme.textTheme.titleMedium),
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
                    onTap: () => setState(() => _selectedColorId = zc.colorId),
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
            // Talla selection
            if (tallas.isNotEmpty) ...[
              Text('Talla', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tallas.map((t) {
                  final selected = _selectedTalla == t;
                  final stock = _loadingInv ? -1 : _stock(_selectedColorId, t);
                  final sinStock = !_loadingInv && stock == 0;
                  return GestureDetector(
                    onTap: sinStock ? null : () => setState(() => _selectedTalla = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                            _tallaDialogLabel(t),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: sinStock ? theme.disabledColor : null,
                            ),
                          ),
                          if (!_loadingInv)
                            Text(
                              stock > 0 ? '$stock' : '–',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: stock > 0
                                    ? Colors.green.shade700
                                    : theme.disabledColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Stock info
            if (!_loadingInv && _selectedColorId != null && _selectedTalla != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: stockActual > 0
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      stockActual > 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                      size: 16,
                      color: stockActual > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stockActual > 0
                          ? 'Stock disponible: $stockActual pares'
                          : 'Sin stock registrado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: stockActual > 0 ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onAdd(
              colorId: _selectedColorId,
              colorNombre: colorNombre,
              talla: _selectedTalla,
            );
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
