import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/models/models.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/services/inversionista_service.dart';
import 'package:zapateria_flutter/services/venta_service.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';
import 'package:zapateria_flutter/utils/price_utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<InversionistaModel> _inversionistas = [];
  final TextEditingController _montoTarjetaCtrl = TextEditingController();
  final TextEditingController _billeteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInversionistas();
    // Rebuild on every keystroke so calculated values update in real time
    _montoTarjetaCtrl.addListener(() => setState(() {}));
    _billeteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montoTarjetaCtrl.dispose();
    _billeteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInversionistas() async {
    try {
      final list = await inversionistaService.getActivos();
      if (mounted) setState(() => _inversionistas = list);
    } catch (_) {}
  }

  double get _montoTarjeta =>
      double.tryParse(_montoTarjetaCtrl.text.replaceAll(',', '.')) ?? 0;

  double _montoEfectivo(double total) {
    return total - _montoTarjeta;
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }
    if (cart.tipoPrecio == TipoPrecio.inversionista && cart.inversionistaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un inversionista')));
      return;
    }

    double montoTarjeta = 0;
    if (cart.metodoPago == MetodoPago.tarjeta) {
      montoTarjeta = cart.total;
    } else if (cart.metodoPago == MetodoPago.mixto) {
      montoTarjeta = _montoTarjeta;
      if (montoTarjeta <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el monto con tarjeta')));
        return;
      }
      if (montoTarjeta >= cart.total) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para pago total con tarjeta selecciona "Tarjeta"')));
        return;
      }
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
        metodoPago: cart.metodoPago,
        montoTarjeta: montoTarjeta,
      );
      cart.clearCart();
      _montoTarjetaCtrl.clear();
      _billeteCtrl.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta registrada exitosamente')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showTipoPrecioSheet(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tipo de precio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            for (final tipo in TipoPrecio.values)
              ListTile(
                leading: Icon(
                  cart.tipoPrecio == tipo ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(_tipoPrecioLabel(tipo)),
                onTap: () {
                  cart.setTipoPrecio(tipo);
                  if (tipo != TipoPrecio.inversionista) cart.setInversionista(null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carrito de Compras')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_basket, size: 64, color: theme.disabledColor),
              const SizedBox(height: 16),
              Text('El carrito está vacío', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de Compras')),
      body: kIsWeb
          ? _buildWebLayout(context, cart, theme)
          : _buildMobileLayout(context, cart, theme),
    );
  }

  Widget _buildWebLayout(BuildContext context, CartProvider cart, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Text('Productos (${cart.items.length})', style: theme.textTheme.titleMedium),
                      ),
                      const Divider(),
                      ...cart.items.map((item) => _WebCartItem(item: item, cart: cart, theme: theme)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 340,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Resumen', style: theme.textTheme.titleLarge),
                        const Divider(height: 24),
                        _buildPaymentControls(context, cart, theme),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: theme.textTheme.titleLarge),
                            Text('\$${formatPrice(cart.total)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _checkout(context),
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Finalizar Venta',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, CartProvider cart, ThemeData theme) {
    return Column(
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
                  leading: ZapatoImage(imageUrl: item.zapato.foto, height: 50, width: 50, borderRadius: 8),
                  title: Text(item.zapato.nombre, style: theme.textTheme.titleMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.zapato.modelo, style: theme.textTheme.bodySmall),
                      Text('\$${formatPrice(item.precioUnitario)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cart.updateQuantity(item.zapato.id, item.cantidad - 1)),
                      Text('${item.cantidad}', style: theme.textTheme.titleMedium),
                      IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cart.updateQuantity(item.zapato.id, item.cantidad + 1)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => cart.removeItem(item.zapato.id)),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            },
          ),
        ),
        _CartBottomBar(
          cart: cart,
          theme: theme,
          inversionistas: _inversionistas,
          paymentControls: _buildPaymentControls(context, cart, theme),
          onCheckout: () => _checkout(context),
          onChangeTipo: () => _showTipoPrecioSheet(context, cart),
        ),
      ],
    );
  }

  // ── Payment controls (shared between web and mobile) ──────────────────────

  Widget _buildPaymentControls(BuildContext context, CartProvider cart, ThemeData theme) {
    final efectivoAmount = cart.metodoPago == MetodoPago.mixto
        ? _montoEfectivo(cart.total)
        : (cart.metodoPago == MetodoPago.efectivo ? cart.total : 0.0);

    final billete = double.tryParse(_billeteCtrl.text.replaceAll(',', '.')) ?? 0;
    final cambio = billete > 0 ? billete - efectivoAmount : 0.0;
    final cambioValido = cambio >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo precio
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tipo de precio:', style: theme.textTheme.bodyMedium),
            TextButton(
              onPressed: () => _showTipoPrecioSheet(context, cart),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tipoPrecioLabel(cart.tipoPrecio),
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary, size: 18),
                ],
              ),
            ),
          ],
        ),
        if (cart.tipoPrecio == TipoPrecio.inversionista && _inversionistas.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: cart.inversionistaId,
            decoration: const InputDecoration(
              labelText: 'Inversionista',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _inversionistas
                .map((inv) => DropdownMenuItem(value: inv.id, child: Text(inv.nombre)))
                .toList(),
            onChanged: (id) => context.read<CartProvider>().setInversionista(id),
          ),
        ],
        const SizedBox(height: 12),
        // Método de pago
        Text('Método de pago:', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<MetodoPago>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          segments: const [
            ButtonSegment(
              value: MetodoPago.efectivo,
              icon: Icon(Icons.payments_outlined, size: 16),
              label: Text('Efectivo', style: TextStyle(fontSize: 12)),
            ),
            ButtonSegment(
              value: MetodoPago.tarjeta,
              icon: Icon(Icons.credit_card, size: 16),
              label: Text('Tarjeta', style: TextStyle(fontSize: 12)),
            ),
            ButtonSegment(
              value: MetodoPago.mixto,
              icon: Icon(Icons.swap_horiz, size: 16),
              label: Text('Mixto', style: TextStyle(fontSize: 12)),
            ),
          ],
          selected: {cart.metodoPago},
          onSelectionChanged: (s) {
            context.read<CartProvider>().setMetodoPago(s.first);
            _montoTarjetaCtrl.clear();
            _billeteCtrl.clear();
          },
        ),

        // Monto tarjeta (solo MIXTO)
        if (cart.metodoPago == MetodoPago.mixto) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _montoTarjetaCtrl,
            decoration: InputDecoration(
              labelText: 'Monto con tarjeta',
              prefixText: '\$ ',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixText: _montoTarjeta > 0
                  ? 'Efectivo: \$${formatPrice(_montoEfectivo(cart.total))}'
                  : null,
              suffixStyle: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          ),
          if (_montoTarjeta > 0) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Monto tarjeta:',
              value: '\$${formatPrice(_montoTarjeta)}',
              color: Colors.blue.shade700,
            ),
            _InfoRow(
              label: 'Monto efectivo:',
              value: '\$${formatPrice(_montoEfectivo(cart.total))}',
              color: theme.colorScheme.onSurface,
            ),
          ],
        ],

        // Campo billete (EFECTIVO y MIXTO)
        if (cart.metodoPago != MetodoPago.tarjeta) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _billeteCtrl,
            decoration: InputDecoration(
              labelText: 'Cliente paga con',
              prefixText: '\$ ',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: 'Ingresa el billete',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          ),
          if (billete > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cambioValido ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cambioValido ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cambioValido ? 'Cambio:' : 'Falta:',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '\$${formatPrice(cambio.abs())}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cambioValido ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Artículos:', style: theme.textTheme.bodyMedium),
            Text('${cart.items.length}', style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

// ── Web cart item ─────────────────────────────────────────────────────────────

class _WebCartItem extends StatelessWidget {
  final dynamic item;
  final CartProvider cart;
  final ThemeData theme;

  const _WebCartItem({required this.item, required this.cart, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          ZapatoImage(imageUrl: item.zapato.foto, height: 56, width: 56, borderRadius: 8),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.zapato.nombre, style: theme.textTheme.titleSmall),
                Text(item.zapato.modelo,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
          Text('\$${formatPrice(item.precioUnitario)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700)),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => cart.updateQuantity(item.zapato.id, item.cantidad - 1)),
              SizedBox(
                  width: 32,
                  child: Text('${item.cantidad}',
                      textAlign: TextAlign.center, style: theme.textTheme.titleSmall)),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => cart.updateQuantity(item.zapato.id, item.cantidad + 1)),
            ],
          ),
          Text('\$${formatPrice(item.precioUnitario * item.cantidad)}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () => cart.removeItem(item.zapato.id)),
        ],
      ),
    );
  }
}

// ── Mobile bottom bar ─────────────────────────────────────────────────────────

class _CartBottomBar extends StatelessWidget {
  final CartProvider cart;
  final ThemeData theme;
  final List<InversionistaModel> inversionistas;
  final Widget paymentControls;
  final VoidCallback onCheckout;
  final VoidCallback onChangeTipo;

  const _CartBottomBar({
    required this.cart,
    required this.theme,
    required this.inversionistas,
    required this.paymentControls,
    required this.onCheckout,
    required this.onChangeTipo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            paymentControls,
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: theme.textTheme.headlineMedium),
                Text('\$${formatPrice(cart.total)}',
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.green.shade700)),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String _tipoPrecioLabel(TipoPrecio tipo) {
  switch (tipo) {
    case TipoPrecio.publico: return 'PÚBLICO';
    case TipoPrecio.mayorista: return 'MAYORISTA';
    case TipoPrecio.inversionista: return 'INVERSIONISTA';
  }
}
