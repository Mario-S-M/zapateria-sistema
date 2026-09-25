import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/components/neo_style.dart';
import 'package:zapateria_flutter/services/api_client.dart';

class ZapatoImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double width;
  final double borderRadius;
  final BoxFit fit;

  const ZapatoImage({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.width = double.infinity,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  String _resolveImageUrl(String url) {
    String path = url;
    if (url.startsWith('http')) {
      path = Uri.parse(url).path.replaceFirst(RegExp(r'^/'), '');
    }
    if (path.startsWith('api/')) path = path.substring(4);
    return '$baseUrl/$path';
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder(context, icon: Icons.category, label: 'Sin foto');
    }

    final fullUrl = _resolveImageUrl(imageUrl!);
    // Nunca decodifica a más resolución que el tamaño real en pantalla —
    // sin esto, una foto de 1600px se decodifica completa aunque el widget
    // mida 80px, desperdiciando memoria y tiempo en cada render.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = width.isFinite ? (width * dpr).round() : null;
    final cacheHeight = height.isFinite ? (height * dpr).round() : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        // En web el navegador ya cachea por los headers de nginx; en móvil
        // CachedNetworkImage guarda en disco y la próxima vez carga al
        // instante.
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => _shimmer(context),
        errorWidget: (_, __, ___) =>
            _placeholder(context, icon: Icons.broken_image_outlined, label: 'Error'),
      ),
    );
  }

  Widget _shimmer(BuildContext context) {
    final t = NeoTheme.of(context);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: t.ink.withOpacity(0.15), width: 2),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.ink.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, {required IconData icon, required String label}) {
    final t = NeoTheme.of(context);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: t.ink.withOpacity(0.25), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: height > 60 ? 40 : 18, color: t.ink.withOpacity(0.4)),
          if (height > 60) ...[
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.ink.withOpacity(0.5))),
          ],
        ],
      ),
    );
  }
}
