import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zapateria_flutter/services/api_client.dart';

class ZapatoImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double width;
  final double borderRadius;

  const ZapatoImage({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.width = double.infinity,
    this.borderRadius = 12,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: kIsWeb
          // En web el navegador ya cachea por los headers de nginx;
          // CachedNetworkImage igual ayuda con la caché en memoria de Flutter.
          ? CachedNetworkImage(
              imageUrl: fullUrl,
              height: height,
              width: width,
              fit: BoxFit.cover,
              placeholder: (_, __) => _shimmer(),
              errorWidget: (_, __, ___) =>
                  _placeholder(context, icon: Icons.broken_image, label: 'Error'),
            )
          : CachedNetworkImage(
              imageUrl: fullUrl,
              height: height,
              width: width,
              fit: BoxFit.cover,
              // En móvil guarda en disco; la próxima vez carga instantáneo
              placeholder: (_, __) => _shimmer(),
              errorWidget: (_, __, ___) =>
                  _placeholder(context, icon: Icons.broken_image, label: 'Error'),
            ),
    );
  }

  Widget _shimmer() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, {required IconData icon, required String label}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: height > 60 ? 48 : 20, color: Colors.grey[400]),
          if (height > 60) ...[
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
