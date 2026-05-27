import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zapateria_flutter/services/upload_service.dart';

class ImagePickerComponent extends StatelessWidget {
  final String? currentImage;
  final ValueChanged<String>? onImagePicked;
  final ValueChanged<String>? onImageUploaded;

  const ImagePickerComponent({
    super.key,
    this.currentImage,
    this.onImagePicked,
    this.onImageUploaded,
  });

  Future<void> _pickAndUpload(BuildContext context) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Subiendo imagen...')));

    try {
      final url = await uploadService.uploadZapatoImage(xFile.path);
      onImageUploaded?.call(url);
      scaffold.showSnackBar(const SnackBar(content: Text('Imagen subida correctamente')));
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (currentImage != null && currentImage!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              currentImage!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          )
        else
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1, strokeAlign: BorderSide.strokeAlignInside),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Sin foto', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pickAndUpload(context),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Subir foto'),
        ),
      ],
    );
  }
}
