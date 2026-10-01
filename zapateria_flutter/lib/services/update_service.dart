import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Archivo que publica el servidor cuando sale un APK nuevo:
/// {"version": "1.0.1", "build": 2, "apk": "https://.../zapateria-1.0.1-b2.apk", "notas": "..."}
const String versionUrl = String.fromEnvironment(
  'VERSION_URL',
  defaultValue: 'https://aragorn-system.com/app/version.json',
);

class AppUpdate {
  final String version;
  final int build;
  final String apkUrl;
  final String notas;

  AppUpdate({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.notas,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) => AppUpdate(
        version: json['version'] as String,
        build: (json['build'] as num).toInt(),
        apkUrl: json['apk'] as String,
        notas: (json['notas'] as String?) ?? '',
      );
}

class UpdateService {
  /// Regresa la versión publicada si es más nueva que la instalada.
  /// En web no aplica: el sitio siempre sirve la última versión.
  static Future<AppUpdate?> buscarActualizacion() async {
    if (kIsWeb) return null;
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      // Evita que un caché intermedio devuelva un version.json viejo
      final response = await dio.get(
        versionUrl,
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      );
      final publicada = AppUpdate.fromJson(response.data as Map<String, dynamic>);
      final instalada = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      return publicada.build > instalada ? publicada : null;
    } catch (e) {
      // Sin internet o servidor caído: la app sigue funcionando normal
      debugPrint('No se pudo revisar si hay actualización: $e');
      return null;
    }
  }

  static Future<void> revisarYAvisar(BuildContext context) async {
    final update = await buscarActualizacion();
    if (update == null || !context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva versión disponible'),
        content: Text(
          'Hay una nueva versión de Zapatería (${update.version}).'
          '${update.notas.isNotEmpty ? '\n\n${update.notas}' : ''}'
          '\n\nAl descargarla, abre el archivo y toca "Actualizar".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(update.apkUrl), mode: LaunchMode.externalApplication);
            },
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }
}
