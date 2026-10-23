import '../models/models.dart';
import '../providers/cart_provider.dart';

class SeccionesRecomendadas {
  final List<InventarioTallaItemModel> recomendados;
  final List<InventarioTallaItemModel> resto;

  const SeccionesRecomendadas({required this.recomendados, required this.resto});
}

/// Separa el inventario de una talla en los zapatos que recomendó el agente
/// (en el orden del agente) y el resto (en el orden del servidor).
/// Un id que el agente invente o que ya no tenga stock en esa talla se descarta:
/// la fuente de verdad es siempre [items].
SeccionesRecomendadas separarRecomendados(
  List<InventarioTallaItemModel> items,
  List<String> idsRecomendados,
) {
  final porId = {for (final i in items) i.zapatoId: i};
  final vistos = <String>{};
  final recomendados = <InventarioTallaItemModel>[];
  for (final id in idsRecomendados) {
    final item = porId[id];
    if (item != null && vistos.add(id)) recomendados.add(item);
  }
  final resto = items.where((i) => !vistos.contains(i.zapatoId)).toList();
  return SeccionesRecomendadas(recomendados: recomendados, resto: resto);
}

/// Pares que todavía se pueden agregar al carrito de esa variante sin pasar
/// de la existencia (descuenta lo que ya está en el carrito).
int disponibleParaAgregar(
  List<CartItem> carrito, {
  required String zapatoId,
  required String? colorId,
  required double talla,
  required int existencia,
}) {
  final enCarrito = carrito
      .where((i) => i.zapato.id == zapatoId && i.colorId == colorId && i.talla == talla)
      .fold<int>(0, (sum, i) => sum + i.cantidad);
  final libre = existencia - enCarrito;
  return libre < 0 ? 0 : libre;
}
