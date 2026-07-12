import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zapateria_flutter/components/zapato_image.dart';
import 'package:zapateria_flutter/services/upload_service.dart';

class MultiImagePickerComponent extends StatefulWidget {
  final List<String> images;
  final int maxImages;
  final void Function(List<String>) onChanged;

  const MultiImagePickerComponent({
    super.key,
    required this.images,
    this.maxImages = 4,
    required this.onChanged,
  });

  @override
  State<MultiImagePickerComponent> createState() => _MultiImagePickerComponentState();
}

class _MultiImagePickerComponentState extends State<MultiImagePickerComponent> {
  bool _uploading = false;

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await uploadService.uploadZapatoImage(xFile.path);
      widget.onChanged([...widget.images, url]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _remove(int index) {
    final list = List<String>.from(widget.images)..removeAt(index);
    widget.onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = !_uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Fotos', style: theme.textTheme.labelLarge),
            const SizedBox(width: 6),
            Text(
              '${widget.images.length}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...widget.images.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ImageTile(
                  url: e.value,
                  allImages: widget.images,
                  index: e.key,
                  onDelete: () => _remove(e.key),
                ),
              )),
              if (canAdd) _AddTile(onTap: _addImage),
              if (_uploading) const _UploadingTile(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final List<String> allImages;
  final int index;
  final VoidCallback onDelete;

  const _ImageTile({
    required this.url,
    required this.allImages,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 110,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => showPhotoLightbox(context, allImages, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ZapatoImage(imageUrl: url, height: 100, width: 100),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: const Text(
                  'Principal',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

void showPhotoLightbox(BuildContext context, List<String> images, int initialIndex) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => _PhotoLightbox(images: images, initialIndex: initialIndex),
  );
}

class _PhotoLightbox extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _PhotoLightbox({required this.images, required this.initialIndex});

  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late PageController _pageController;
  late TransformationController _transformController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformController = TransformationController();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _isZoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            itemCount: widget.images.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
              _transformController.value = Matrix4.identity();
            },
            itemBuilder: (_, i) => InteractiveViewer(
              transformationController: i == _currentIndex ? _transformController : TransformationController(),
              minScale: 1.0,
              maxScale: 4.0,
              clipBehavior: Clip.none,
              child: Center(
                child: ZapatoImage(
                  imageUrl: widget.images[i],
                  height: MediaQuery.of(context).size.height * 0.65,
                  width: MediaQuery.of(context).size.width * 0.85,
                  borderRadius: 8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(backgroundColor: Colors.black38),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == i ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
          if (widget.images.length > 1 && _currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 36),
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          if (widget.images.length > 1 && _currentIndex < widget.images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 36),
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
