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

class TicketAbono {
  final DateTime fecha;
  final double monto;
  final String metodoPago;

  const TicketAbono({required this.fecha, required this.monto, required this.metodoPago});
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
  final String? clienteNombre;
  final String? clienteTelefono;

  /// Si no es null, el ticket es de un apartado (con histórico de abonos).
  final List<TicketAbono>? abonos;
  final double? saldo;

  bool get esApartado => abonos != null;

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
    this.clienteNombre,
    this.clienteTelefono,
    this.abonos,
    this.saldo,
  });

  TicketData copyWith({String? clienteNombre}) => TicketData(
        folio: folio,
        fecha: fecha,
        items: items,
        total: total,
        metodoPago: metodoPago,
        montoTarjeta: montoTarjeta,
        montoRecibido: montoRecibido,
        cambio: cambio,
        tipoPrecio: tipoPrecio,
        inversionistaNombre: inversionistaNombre,
        clienteNombre: clienteNombre ?? this.clienteNombre,
        clienteTelefono: clienteTelefono,
        abonos: abonos,
        saldo: saldo,
      );
}
