import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/screens/zapatos_screen.dart';
import 'package:zapateria_flutter/screens/ventas_screen.dart';
import 'package:zapateria_flutter/screens/cart_screen.dart';
import 'package:zapateria_flutter/screens/scanner_screen.dart';
import 'package:zapateria_flutter/screens/cierre_caja_screen.dart';
import 'package:zapateria_flutter/screens/inversionistas_screen.dart';
import 'package:zapateria_flutter/screens/categorias_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = [
    const ZapatosScreen(),
    const VentasScreen(),
    const CartScreen(),
    const ScannerScreen(),
    const CierreCajaScreen(),
    const InversionistasScreen(),
    const CategoriasScreen(),
  ];

  static const _icons = [
    Icons.inventory_2,
    Icons.point_of_sale,
    Icons.shopping_cart,
    Icons.qr_code_scanner,
    Icons.receipt_long,
    Icons.people,
    Icons.category,
  ];

  static const _labels = [
    'Zapatos',
    'Ventas',
    'Carrito',
    'Escanear',
    'Cierre',
    'Inversionistas',
    'Categorías',
  ];

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              extended: true,
              minExtendedWidth: 180,
              selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
              destinations: List.generate(
                _icons.length,
                (i) => NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(_labels[i]),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      );
    }

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
        items: List.generate(
          _icons.length,
          (i) => BottomNavigationBarItem(icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
    );
  }
}
