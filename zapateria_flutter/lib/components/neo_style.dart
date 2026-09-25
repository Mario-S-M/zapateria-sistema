// Neobrutalist / playful direction — shared tokens and widgets.
// Bold black outlines, hard offset shadows (no blur), warm paper background,
// single bold yellow accent. See DESIGN.md for the full rationale.
import 'package:flutter/material.dart';

class NeoColors {
  static const Color inkLight = Color(0xFF181818);
  static const Color inkDark = Color(0xFFF5F0E6);
  static const Color paperLight = Color(0xFFFFFFFF);
  static const Color paperDark = Color(0xFF232323);
  static const Color bgLight = Color(0xFFFBF3E4);
  static const Color bgDark = Color(0xFF121212);
  static const Color accent = Color(0xFFFFC800);
}

/// Ink/paper/shadow colors resolved for the current brightness.
class NeoTheme {
  final Color ink;
  final Color paper;
  final Color bg;
  final Color shadow;
  const NeoTheme({required this.ink, required this.paper, required this.bg, required this.shadow});

  factory NeoTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return NeoTheme(
      ink: dark ? NeoColors.inkDark : NeoColors.inkLight,
      paper: dark ? NeoColors.paperDark : NeoColors.paperLight,
      bg: dark ? NeoColors.bgDark : NeoColors.bgLight,
      // Hard shadows read against the page background, not the card — a pure
      // black shadow disappears on a near-black page, so dark mode uses a
      // lighter charcoal that still contrasts against bgDark.
      shadow: dark ? const Color(0xFF000000) : NeoColors.inkLight,
    );
  }
}

BoxDecoration neoCardDecoration(BuildContext context, {double radius = 20, Color? color}) {
  final t = NeoTheme.of(context);
  return BoxDecoration(
    color: color ?? t.paper,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: t.ink, width: 2),
    boxShadow: [BoxShadow(color: t.shadow, offset: const Offset(4, 4), blurRadius: 0)],
  );
}

/// A flat, hard-shadowed "sticker" card — the signature container of the
/// neobrutalist direction. Use instead of Material [Card] wherever a card
/// should carry the full treatment (border + offset shadow).
class NeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Clip clipBehavior;

  const NeoCard({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(12),
    this.radius = 20,
    this.color,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    // Material (transparent) por dentro del Container decorado: sin esto,
    // un ListTile/InkWell hijo (ej. ExpansionTile) busca un ancestro
    // Material para pintar su ripple y lo encuentra fuera de esta caja —
    // el fondo opaco del Container lo tapa y el ripple queda invisible.
    final content = Material(
      type: MaterialType.transparency,
      child: clipBehavior == Clip.none ? Padding(padding: padding, child: child) : child,
    );
    return Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: neoCardDecoration(context, radius: radius, color: color),
      child: content,
    );
  }
}

/// A small square icon button with a bold border — used in card action rows
/// instead of a bare [IconButton].
class NeoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final String? tooltip;
  final double size;

  const NeoIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.tooltip,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final t = NeoTheme.of(context);
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.ink, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(icon, size: size * 0.5, color: iconColor ?? t.ink),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Bottom pagination bar — bordered page chips, selected page filled with
/// [NeoColors.accent] and a small hard shadow. `page` and `onPageChanged`
/// are 0-indexed. Shared by any list screen with server- or client-side
/// pagination (Zapatos, Ventas, ...).
class NeoPaginator extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const NeoPaginator({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<int> _buildPageNumbers() {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i);
    final result = <int>[];
    result.add(0);
    if (page > 2) result.add(-1);
    for (int i = (page - 1).clamp(1, totalPages - 2);
         i <= (page + 1).clamp(1, totalPages - 2);
         i++) {
      result.add(i);
    }
    if (page < totalPages - 3) result.add(-1);
    result.add(totalPages - 1);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final t = NeoTheme.of(context);
    final pages = _buildPageNumbers();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(top: BorderSide(color: t.ink, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NeoPageButton(
            icon: Icons.chevron_left,
            enabled: page > 0,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 4),
          ...pages.map((p) => p == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…', style: TextStyle(fontSize: 14)),
                )
              : _NeoPageButton(
                  label: '${p + 1}',
                  selected: p == page,
                  onTap: () => onPageChanged(p),
                )),
          const SizedBox(width: 4),
          _NeoPageButton(
            icon: Icons.chevron_right,
            enabled: page < totalPages - 1,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }
}

class _NeoPageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _NeoPageButton({
    this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = NeoTheme.of(context);
    final borderColor = enabled ? t.ink : t.ink.withOpacity(0.25);
    final fg = enabled ? t.ink : t.ink.withOpacity(0.35);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? NeoColors.accent : t.paper,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: selected
                ? [BoxShadow(color: t.shadow, offset: const Offset(2, 2), blurRadius: 0)]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: enabled ? onTap : null,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 18, color: fg)
                    : Text(
                        label!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: fg,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
