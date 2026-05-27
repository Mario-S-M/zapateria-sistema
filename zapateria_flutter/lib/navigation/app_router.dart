import 'package:flutter/material.dart';
import 'package:zapateria_flutter/screens/zapatos_screen.dart';
import 'package:zapateria_flutter/screens/ventas_screen.dart';
import 'package:zapateria_flutter/screens/cart_screen.dart';
import 'package:zapateria_flutter/screens/scanner_screen.dart';
import 'package:zapateria_flutter/screens/cierre_caja_screen.dart';

class AppRouter {
  static const String zapatos = '/zapatos';
  static const String ventas = '/ventas';
  static const String cart = '/cart';
  static const String scanner = '/scanner';
  static const String cierreCaja = '/cierre-caja';

  static final routes = <String, WidgetBuilder>{
    zapatos: (context) => const ZapatosScreen(),
    ventas: (context) => const VentasScreen(),
    cart: (context) => const CartScreen(),
    scanner: (context) => const ScannerScreen(),
    cierreCaja: (context) => const CierreCajaScreen(),
  };

  static final navigationShell = <String, WidgetBuilder>{
    zapatos: (context) => const ZapatosScreen(),
    ventas: (context) => const VentasScreen(),
    cart: (context) => const CartScreen(),
    scanner: (context) => const ScannerScreen(),
    cierreCaja: (context) => const CierreCajaScreen(),
  };

  static const bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2),
      label: 'Zapatos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.point_of_sale),
      label: 'Ventas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: 'Carrito',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner),
      label: 'Escanear',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long),
      label: 'Cierre',
    ),
  ];
}
