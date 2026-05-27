import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/zapato_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:zapateria_flutter/screens/zapato_form_screen.dart';
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
  final int _perPage = 15;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadZapatos();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _loadZapatos();
    if (mounted) setState(() {});
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
            padding: const EdgeInsets.all(16),
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
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
                      )
                    : _filtered.isEmpty
                    ? Center(
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
                      )
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _paginated.length,
                          itemBuilder: (context, index) => _ZapatoCard(
                            zapato: _paginated[index],
                            tipoPrecio: cartProvider.tipoPrecio,
                            onEdit: () => _showForm(context, _paginated[index]),
                            onAddToCart: () {
                              final tipo = cartProvider.tipoPrecio;
                              double precio;
                              switch (tipo) {
                                case TipoPrecio.publico:
                                  precio = _paginated[index].precioPublico;
                                  break;
                                case TipoPrecio.mayorista:
                                  precio = _paginated[index].precioCompra * 1.3;
                                  break;
                                case TipoPrecio.inversionista:
                                  precio = _paginated[index].precioCompra * 1.2;
                                  break;
                              }
                              cartProvider.addItem(_paginated[index], 1, precio);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${_paginated[index].nombre} agregado al carrito')),
                              );
                            },
                            onDelete: () => _deleteZapato(_paginated[index]),
                          ),
                        ),
                      ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Página ${_page + 1} de $_totalPages', style: theme.textTheme.bodySmall),
                  OutlinedButton(
                    onPressed: _page < _totalPages - 1 ? () => setState(() => _page++) : null,
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  void _showForm(BuildContext context, ZapatoModel? zapato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZapatoFormScreen(zapato: zapato),
      ),
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
}

class _ZapatoCard extends StatelessWidget {
  final ZapatoModel zapato;
  final TipoPrecio tipoPrecio;
  final VoidCallback onEdit;
  final VoidCallback onAddToCart;
  final VoidCallback onDelete;

  const _ZapatoCard({
    required this.zapato,
    required this.tipoPrecio,
    required this.onEdit,
    required this.onAddToCart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double precio;
    switch (tipoPrecio) {
      case TipoPrecio.publico:
        precio = zapato.precioPublico;
        break;
      case TipoPrecio.mayorista:
        precio = zapato.precioCompra * 1.3;
        break;
      case TipoPrecio.inversionista:
        precio = zapato.precioCompra * 1.2;
        break;
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
                children: zapato.colores.map((zc) {
                  return ColorCircle(color: zc.color, size: 24);
                }).toList(),
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
