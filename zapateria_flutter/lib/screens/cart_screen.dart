import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }

    try {
      final folio = 'V-${DateTime.now().millisecondsSinceEpoch}';
      await ventaService.create(
        folio: folio,
        tipoPrecio: cart.tipoPrecio,
        inversionistaId: cart.inversionistaId,
        items: cart.items.map((i) => VentaItemDto(
          zapatoId: i.zapato.id,
          cantidad: i.cantidad,
          precioUnitario: i.precioUnitario,
        )).toList(),
      );

      cart.clearCart();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta registrada exitosamente')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de Compras')),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('El carrito está vacío', style: theme.textTheme.bodyLarge),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: item.zapato.foto != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item.zapato.foto!, width: 50, height: 50, fit: BoxFit.cover),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.category, size: 24),
                                ),
                          title: Text(item.zapato.nombre, style: theme.textTheme.titleMedium),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.zapato.modelo, style: theme.textTheme.bodySmall),
                              Text('\$${formatPrice(item.precioUnitario)}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => cart.updateQuantity(item.zapato.id, item.cantidad - 1),
                              ),
                              Text('${item.cantidad}', style: theme.textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => cart.updateQuantity(item.zapato.id, item.cantidad + 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => cart.removeItem(item.zapato.id),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
                _CartBottomBar(cart: cart, theme: theme, onCheckout: () => _checkout(context)),
              ],
            ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final CartProvider cart;
  final ThemeData theme;
  final VoidCallback onCheckout;

  const _CartBottomBar({required this.cart, required this.theme, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tipo de precio:', style: theme.textTheme.titleMedium),
                Text(cart.tipoPrecioString, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: theme.textTheme.headlineMedium),
                Text('\$${formatPrice(cart.total)}', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Finalizar Venta', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

extension on CartProvider {
  String get tipoPrecioString {
    switch (tipoPrecio) {
      case TipoPrecio.publico:
        return 'PÚBLICO';
      case TipoPrecio.mayorista:
        return 'MAYORISTA';
      case TipoPrecio.inversionista:
        return 'INVERSIONISTA';
    }
  }
}
