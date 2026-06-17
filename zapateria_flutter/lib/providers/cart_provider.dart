import 'package:flutter/material.dart';
import '../models/models.dart';

class CartItem {
  final ZapatoModel zapato;
  final int cantidad;
  final double precioUnitario;
  final String? colorId;
  final String? colorNombre;
  final double? talla;

  CartItem({
    required this.zapato,
    required this.cantidad,
    required this.precioUnitario,
    this.colorId,
    this.colorNombre,
    this.talla,
  });

  // Unique key so the same zapato with different color+talla is a separate item
  String get key => '${zapato.id}-${colorId ?? ''}-${talla ?? ''}';

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

  void addItem(
    ZapatoModel zapato,
    int cantidad,
    double precioUnitario, {
    String? colorId,
    String? colorNombre,
    double? talla,
  }) {
    final newItem = CartItem(
      zapato: zapato,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      colorId: colorId,
      colorNombre: colorNombre,
      talla: talla,
    );
    final index = _items.indexWhere((i) => i.key == newItem.key);
    if (index >= 0) {
      _items[index] = CartItem(
        zapato: zapato,
        cantidad: _items[index].cantidad + cantidad,
        precioUnitario: precioUnitario,
        colorId: colorId,
        colorNombre: colorNombre,
        talla: talla,
      );
    } else {
      _items.add(newItem);
    }
    notifyListeners();
  }

  void removeItem(String key) {
    _items.removeWhere((i) => i.key == key);
    notifyListeners();
  }

  void updateQuantity(String key, int cantidad) {
    if (cantidad <= 0) {
      removeItem(key);
      return;
    }
    final index = _items.indexWhere((i) => i.key == key);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = CartItem(
        zapato: existing.zapato,
        cantidad: cantidad,
        precioUnitario: existing.precioUnitario,
        colorId: existing.colorId,
        colorNombre: existing.colorNombre,
        talla: existing.talla,
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
