import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/app.dart';
import 'package:zapateria_flutter/providers/cart_provider.dart';
import 'package:zapateria_flutter/providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const ZapateriaApp(),
    ),
  );
}
