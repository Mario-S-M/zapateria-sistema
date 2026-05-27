import 'package:flutter/material.dart';
import 'package:zapateria_flutter/screens/zapatos_screen.dart';
import 'package:zapateria_flutter/screens/ventas_screen.dart';
import 'package:zapateria_flutter/screens/cart_screen.dart';
import 'package:zapateria_flutter/screens/scanner_screen.dart';
import 'package:zapateria_flutter/screens/cierre_caja_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    ZapatosScreen(),
    VentasScreen(),
    CartScreen(),
    ScannerScreen(),
    CierreCajaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).disabledColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Zapatos'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Ventas'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Cierre'),
        ],
      ),
    );
  }
}
