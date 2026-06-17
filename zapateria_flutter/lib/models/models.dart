class ColorModel {
  final String id;
  final String nombre;
  final String? hexadecimal;
  final bool? isCombo;
  final String? primaryColor;
  final String? secondaryColor;
  final String createdAt;
  final String updatedAt;

  ColorModel({
    required this.id,
    required this.nombre,
    this.hexadecimal,
    this.isCombo,
    this.primaryColor,
    this.secondaryColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      hexadecimal: json['hexadecimal'] as String?,
      isCombo: json['isCombo'] as bool?,
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (hexadecimal != null) 'hexadecimal': hexadecimal,
      if (isCombo != null) 'isCombo': isCombo,
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (secondaryColor != null) 'secondaryColor': secondaryColor,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class CategoriaModel {
  final String id;
  final String nombre;
  final bool activo;
  final String createdAt;
  final String updatedAt;

  CategoriaModel({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activo': activo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ZapatoModel {
  final String id;
  final String codigoBarras;
  final String nombre;
  final String modelo;
  final String? foto;
  final double precioCompra;
  final double precioPublico;
  final int medidaInicio;
  final int medidaFin;
  final String? categoriaId;
  final CategoriaModel? categoria;
  final String? inversionistaId;
  final InversionistaModel? inversionista;
  final List<ZapatoColorModel> colores;
  final String createdAt;
  final String updatedAt;

  ZapatoModel({
    required this.id,
    required this.codigoBarras,
    required this.nombre,
    required this.modelo,
    this.foto,
    required this.precioCompra,
    required this.precioPublico,
    required this.medidaInicio,
    required this.medidaFin,
    this.categoriaId,
    this.categoria,
    this.inversionistaId,
    this.inversionista,
    required this.colores,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ZapatoModel.fromJson(Map<String, dynamic> json) {
    final coloresJson = json['colores'] as List? ?? [];
    final colores = coloresJson
        .whereType<Map<String, dynamic>>()
        .map((c) => ZapatoColorModel.fromJson(c))
        .toList();

    return ZapatoModel(
      id: json['id'] as String,
      codigoBarras: json['codigoBarras'] as String,
      nombre: json['nombre'] as String,
      modelo: json['modelo'] as String,
      foto: json['foto'] as String?,
      precioCompra: double.parse(json['precioCompra'].toString()),
      precioPublico: double.parse(json['precioPublico'].toString()),
      medidaInicio: double.parse(json['medidaInicio'].toString()).toInt(),
      medidaFin: double.parse(json['medidaFin'].toString()).toInt(),
      categoriaId: json['categoriaId'] as String?,
      categoria: json['categoria'] != null
          ? CategoriaModel.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
      inversionistaId: json['inversionistaId'] as String?,
      inversionista: json['inversionista'] != null
          ? InversionistaModel.fromJson(json['inversionista'] as Map<String, dynamic>)
          : null,
      colores: colores,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigoBarras': codigoBarras,
      'nombre': nombre,
      'modelo': modelo,
      if (foto != null) 'foto': foto,
      'precioCompra': precioCompra,
      'precioPublico': precioPublico,
      'medidaInicio': medidaInicio,
      'medidaFin': medidaFin,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (inversionistaId != null) 'inversionistaId': inversionistaId,
      'colores': colores.map((c) => c.colorId).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ZapatoColorModel {
  final String id;
  final String zapatoId;
  final String colorId;
  final ColorModel color;
  final String createdAt;

  ZapatoColorModel({
    required this.id,
    required this.zapatoId,
    required this.colorId,
    required this.color,
    required this.createdAt,
  });

  factory ZapatoColorModel.fromJson(Map<String, dynamic> json) {
    return ZapatoColorModel(
      id: json['id'] as String,
      zapatoId: json['zapatoId'] as String,
      colorId: json['colorId'] as String,
      color: ColorModel.fromJson(json['color'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
    );
  }
}

class InversionistaModel {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final bool activo;
  final bool tieneTerminal;
  final String createdAt;
  final String updatedAt;

  InversionistaModel({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    required this.activo,
    this.tieneTerminal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InversionistaModel.fromJson(Map<String, dynamic> json) {
    return InversionistaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      activo: json['activo'] as bool,
      tieneTerminal: json['tieneTerminal'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      'activo': activo,
      'tieneTerminal': tieneTerminal,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

enum TipoPrecio {
  publico,
  mayorista,
  inversionista,
}

enum MetodoPago {
  efectivo,
  tarjeta,
  mixto,
}

class VentaItemModel {
  final String id;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String ventaId;
  final String? zapatoId;
  final ZapatoModel? zapato;
  final String createdAt;
  final String updatedAt;

  VentaItemModel({
    required this.id,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.ventaId,
    this.zapatoId,
    this.zapato,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VentaItemModel.fromJson(Map<String, dynamic> json) {
    ZapatoModel? zapato;
    if (json['zapato'] != null) {
      try {
        zapato = ZapatoModel.fromJson(json['zapato'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return VentaItemModel(
      id: json['id'] as String,
      cantidad: json['cantidad'] as int,
      precioUnitario: double.parse(json['precioUnitario'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      ventaId: json['ventaId'] as String,
      zapatoId: json['zapatoId'] as String?,
      zapato: zapato,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class VentaModel {
  final String id;
  final String folio;
  final String fecha;
  final double total;
  final TipoPrecio tipoPrecio;
  final MetodoPago metodoPago;
  final double montoTarjeta;
  final String? inversionistaId;
  final InversionistaModel? inversionista;
  final List<VentaItemModel> items;
  final String createdAt;
  final String updatedAt;

  VentaModel({
    required this.id,
    required this.folio,
    required this.fecha,
    required this.total,
    required this.tipoPrecio,
    this.metodoPago = MetodoPago.efectivo,
    this.montoTarjeta = 0,
    this.inversionistaId,
    this.inversionista,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List? ?? [];
    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map((i) => VentaItemModel.fromJson(i))
        .toList();

    TipoPrecio tipoPrecio;
    switch ((json['tipoPrecio'] as String? ?? 'PUBLICO').toUpperCase()) {
      case 'MAYORISTA':
        tipoPrecio = TipoPrecio.mayorista;
        break;
      case 'INVERSIONISTA':
        tipoPrecio = TipoPrecio.inversionista;
        break;
      default:
        tipoPrecio = TipoPrecio.publico;
    }

    MetodoPago metodoPago;
    switch ((json['metodoPago'] as String? ?? 'EFECTIVO').toUpperCase()) {
      case 'TARJETA':
        metodoPago = MetodoPago.tarjeta;
        break;
      case 'MIXTO':
        metodoPago = MetodoPago.mixto;
        break;
      default:
        metodoPago = MetodoPago.efectivo;
    }

    return VentaModel(
      id: json['id'] as String,
      folio: json['folio'] as String,
      fecha: json['fecha'] as String,
      total: double.parse(json['total'].toString()),
      tipoPrecio: tipoPrecio,
      metodoPago: metodoPago,
      montoTarjeta: double.parse((json['montoTarjeta'] ?? 0).toString()),
      inversionistaId: json['inversionistaId'] as String?,
      inversionista: json['inversionista'] != null
          ? InversionistaModel.fromJson(json['inversionista'] as Map<String, dynamic>)
          : null,
      items: items,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  String get tipoPrecioString {
    switch (tipoPrecio) {
      case TipoPrecio.publico:
        return 'PÚBLICO';
      case TipoPrecio.mayorista:
        return 'MAYORISTA';
      case TipoPrecio.inversionista:
        return 'INVERSIONISTA';
    }
  }

  String get metodoPagoString {
    switch (metodoPago) {
      case MetodoPago.efectivo:
        return 'EFECTIVO';
      case MetodoPago.tarjeta:
        return 'TARJETA';
      case MetodoPago.mixto:
        return 'MIXTO';
    }
  }
}

class CierreCajaArticulo {
  final String? zapatoId;
  final String nombre;
  final String? modelo;
  final String? foto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? hora;

  CierreCajaArticulo({
    this.zapatoId,
    required this.nombre,
    this.modelo,
    this.foto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.hora,
  });

  factory CierreCajaArticulo.fromJson(Map<String, dynamic> json) {
    return CierreCajaArticulo(
      zapatoId: json['zapatoId'] as String?,
      nombre: json['nombre'] as String? ?? 'Artículo',
      modelo: json['modelo'] as String?,
      foto: json['foto'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitario: double.parse(json['precioUnitario'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      hora: json['hora'] as String?,
    );
  }
}

class CierreCajaInversionista {
  final String? inversionistaId;
  final String nombre;
  final int totalItems;
  final double total;
  final List<CierreCajaArticulo> articulos;

  CierreCajaInversionista({
    this.inversionistaId,
    required this.nombre,
    required this.totalItems,
    required this.total,
    this.articulos = const [],
  });

  factory CierreCajaInversionista.fromJson(Map<String, dynamic> json) {
    final artJson = json['articulos'] as List? ?? [];
    final articulos = artJson
        .whereType<Map<String, dynamic>>()
        .map((a) => CierreCajaArticulo.fromJson(a))
        .toList();
    return CierreCajaInversionista(
      inversionistaId: json['inversionistaId'] as String?,
      nombre: json['nombre'] as String? ?? 'Sin Inversionista',
      totalItems: (json['totalItems'] as num).toInt(),
      total: double.parse(json['total'].toString()),
      articulos: articulos,
    );
  }
}

class CierreCajaDeuda {
  final String acreedorId;
  final String acreedorNombre;
  final double monto;

  CierreCajaDeuda({
    required this.acreedorId,
    required this.acreedorNombre,
    required this.monto,
  });

  factory CierreCajaDeuda.fromJson(Map<String, dynamic> json) {
    return CierreCajaDeuda(
      acreedorId: json['acreedorId'] as String,
      acreedorNombre: json['acreedorNombre'] as String,
      monto: double.parse(json['monto'].toString()),
    );
  }
}

class CierreCajaDia {
  final String fecha;
  final List<CierreCajaInversionista> inversionistas;
  final double totalDia;
  final double totalEfectivo;
  final double totalTarjeta;
  final List<CierreCajaDeuda> deudasTarjeta;
  final String? terminalNombre;

  CierreCajaDia({
    required this.fecha,
    required this.inversionistas,
    required this.totalDia,
    this.totalEfectivo = 0,
    this.totalTarjeta = 0,
    this.deudasTarjeta = const [],
    this.terminalNombre,
  });

  factory CierreCajaDia.fromJson(Map<String, dynamic> json) {
    final invJson = json['inversionistas'] as List? ?? [];
    final inversionistas = invJson
        .whereType<Map<String, dynamic>>()
        .map((i) => CierreCajaInversionista.fromJson(i))
        .toList();

    final deudasJson = json['deudasTarjeta'] as List? ?? [];
    final deudasTarjeta = deudasJson
        .whereType<Map<String, dynamic>>()
        .map((d) => CierreCajaDeuda.fromJson(d))
        .toList();

    final totalDia = double.parse(json['totalDia'].toString());

    return CierreCajaDia(
      fecha: json['fecha'] as String,
      inversionistas: inversionistas,
      totalDia: totalDia,
      totalEfectivo: double.parse((json['totalEfectivo'] ?? totalDia).toString()),
      totalTarjeta: double.parse((json['totalTarjeta'] ?? 0).toString()),
      deudasTarjeta: deudasTarjeta,
      terminalNombre: json['terminalNombre'] as String?,
    );
  }
}

class InventarioItemModel {
  final String id;
  final String zapatoId;
  final String? colorId;
  final ColorModel? color;
  final double talla;
  final int cantidad;

  InventarioItemModel({
    required this.id,
    required this.zapatoId,
    this.colorId,
    this.color,
    required this.talla,
    required this.cantidad,
  });

  factory InventarioItemModel.fromJson(Map<String, dynamic> json) {
    return InventarioItemModel(
      id: json['id'] as String,
      zapatoId: json['zapatoId'] as String,
      colorId: json['colorId'] as String?,
      color: json['color'] != null
          ? ColorModel.fromJson(json['color'] as Map<String, dynamic>)
          : null,
      talla: (json['talla'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),
    );
  }
}
