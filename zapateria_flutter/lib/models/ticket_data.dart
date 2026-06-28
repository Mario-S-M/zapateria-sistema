class TicketItem {
  final String nombre;
  final String modelo;
  final String? color;
  final double? talla;
  final int cantidad;
  final double precioUnitario;

  const TicketItem({
    required this.nombre,
    required this.modelo,
    this.color,
    this.talla,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => precioUnitario * cantidad;
}

class TicketData {
  final String folio;
  final DateTime fecha;
  final List<TicketItem> items;
  final double total;
  final String metodoPago;
  final double? montoTarjeta;
  final double? montoRecibido;
  final double? cambio;
  final String tipoPrecio;
  final String? inversionistaNombre;

  const TicketData({
    required this.folio,
    required this.fecha,
    required this.items,
    required this.total,
    required this.metodoPago,
    this.montoTarjeta,
    this.montoRecibido,
    this.cambio,
    required this.tipoPrecio,
    this.inversionistaNombre,
  });
}
