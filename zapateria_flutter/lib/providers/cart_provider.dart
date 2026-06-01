import 'package:flutter/material.dart';
import '../models/models.dart';

class CartItem {
  final ZapatoModel zapato;
  final int cantidad;
  final double precioUnitario;

  CartItem({
    required this.zapato,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => precioUnitario * cantidad;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  TipoPrecio _tipoPrecio = TipoPrecio.publico;
  String? _inversionistaId;
  MetodoPago _metodoPago = MetodoPago.efectivo;
  double _montoTarjeta = 0;

  List<CartItem> get items => _items;
  TipoPrecio get tipoPrecio => _tipoPrecio;
  String? get inversionistaId => _inversionistaId;
  MetodoPago get metodoPago => _metodoPago;
  double get montoTarjeta => _montoTarjeta;
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.cantidad);

  void addItem(ZapatoModel zapato, int cantidad, double precioUnitario) {
    final index = _items.indexWhere((i) => i.zapato.id == zapato.id);
    if (index >= 0) {
      _items[index] = CartItem(
        zapato: zapato,
        cantidad: _items[index].cantidad + cantidad,
        precioUnitario: precioUnitario,
      );
    } else {
      _items.add(CartItem(
        zapato: zapato,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
      ));
    }
    notifyListeners();
  }

  void removeItem(String zapatoId) {
    _items.removeWhere((i) => i.zapato.id == zapatoId);
    notifyListeners();
  }

  void updateQuantity(String zapatoId, int cantidad) {
    if (cantidad <= 0) {
      removeItem(zapatoId);
      return;
    }
    final index = _items.indexWhere((i) => i.zapato.id == zapatoId);
    if (index >= 0) {
      _items[index] = CartItem(
        zapato: _items[index].zapato,
        cantidad: cantidad,
        precioUnitario: _items[index].precioUnitario,
      );
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _inversionistaId = null;
    _metodoPago = MetodoPago.efectivo;
    _montoTarjeta = 0;
    notifyListeners();
  }

  void setTipoPrecio(TipoPrecio tipo) {
    _tipoPrecio = tipo;
    notifyListeners();
  }

  void setInversionista(String? id) {
    _inversionistaId = id;
    notifyListeners();
  }

  void setMetodoPago(MetodoPago mp) {
    _metodoPago = mp;
    if (mp == MetodoPago.efectivo) _montoTarjeta = 0;
    notifyListeners();
  }

  void setMontoTarjeta(double monto) {
    _montoTarjeta = monto;
    notifyListeners();
  }
}
