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
    return Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: neoCardDecoration(context, radius: radius, color: color),
      child: clipBehavior == Clip.none ? Padding(padding: padding, child: child) : child,
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
