import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapateria_flutter/navigation/main_shell.dart';
import 'package:zapateria_flutter/providers/theme_provider.dart';

class ZapateriaApp extends StatelessWidget {
  const ZapateriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Zapatería',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainShell(),
        '/zapato-form': (context) => const _PlaceholderScreen(label: 'Zapato Form'),
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: const Center(child: Text('Ruta en construcción')),
    );
  }
}
