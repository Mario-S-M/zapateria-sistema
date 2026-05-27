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

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
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
            Icon(Icons.category, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Sin foto', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    final fullUrl = imageUrl!.startsWith('http') ? imageUrl! : '$baseUrl/$imageUrl';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        fullUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
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
                Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Error al cargar', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
