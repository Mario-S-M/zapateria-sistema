import 'package:flutter/material.dart';
import '../models/models.dart';

class ColorCircle extends StatelessWidget {
  final ColorModel color;
  final double size;

  const ColorCircle({super.key, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (color.isCombo == true && color.primaryColor != null && color.secondaryColor != null) {
      return _buildComboColor(color);
    }
    return _buildSimpleColor(color);
  }

  Widget _buildSimpleColor(ColorModel c) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _parseHex(c.hexadecimal) ?? Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
    );
  }

  Widget _buildComboColor(ColorModel c) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Row(
              children: [
                Expanded(child: Container(color: _parseHex(c.primaryColor) ?? Colors.red)),
                Expanded(child: Container(color: _parseHex(c.secondaryColor) ?? Colors.blue)),
              ],
            ),
          ),
        ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
        ),
      ],
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}

class ColorPickerGrid extends StatelessWidget {
  final List<ColorModel> colors;
  final List<String> selectedColorIds;
  final ValueChanged<String> onColorSelect;
  final int crossAxisCount;

  const ColorPickerGrid({
    super.key,
    required this.colors,
    required this.selectedColorIds,
    required this.onColorSelect,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = selectedColorIds.contains(color.id);
        return _ColorChip(
          color: color,
          isSelected: isSelected,
          onTap: () => onColorSelect(color.id),
          isSelectedColor: isSelected,
        );
      },
    );
  }
}

class _ColorChip extends StatelessWidget {
  final ColorModel color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSelectedColor;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isSelectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (color.isCombo == true && color.primaryColor != null)
                ClipOval(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Row(
                      children: [
                        Expanded(child: Container(color: _parseHex(color.primaryColor) ?? Colors.red)),
                        Expanded(child: Container(color: _parseHex(color.secondaryColor) ?? Colors.blue)),
                      ],
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.isCombo == true
                      ? null
                      : (_parseHex(color.hexadecimal) ?? Colors.grey),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelectedColor
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelectedColor ? 3 : 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              color.nombre,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}
