import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/neo_style.dart';
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
    final t = NeoTheme.of(context);
    final indicatorShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: t.ink, width: 2),
    );

    if (kIsWeb) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: t.bg,
                border: Border(right: BorderSide(color: t.ink, width: 2)),
              ),
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                extended: true,
                minExtendedWidth: 200,
                backgroundColor: Colors.transparent,
                indicatorColor: NeoColors.accent,
                indicatorShape: indicatorShape,
                selectedIconTheme: IconThemeData(color: t.ink),
                unselectedIconTheme: IconThemeData(color: t.ink.withOpacity(0.4)),
                selectedLabelTextStyle: TextStyle(
                  color: t.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                unselectedLabelTextStyle: TextStyle(color: t.ink.withOpacity(0.6), fontSize: 14),
                destinations: List.generate(
                  _icons.length,
                  (i) => NavigationRailDestination(
                    icon: Icon(_icons[i]),
                    label: Text(_labels[i]),
                  ),
                ),
              ),
            ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: t.paper,
          border: Border(top: BorderSide(color: t.ink, width: 2)),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: NeoColors.accent,
            indicatorShape: indicatorShape,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 11,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
                color: t.ink,
              ),
            ),
            destinations: List.generate(
              _icons.length,
              (i) => NavigationDestination(
                icon: Icon(_icons[i], color: t.ink.withOpacity(0.5)),
                selectedIcon: Icon(_icons[i], color: t.ink),
                label: _labels[i],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
