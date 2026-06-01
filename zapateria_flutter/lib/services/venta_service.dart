import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class VentaService {
  final Dio _dio = apiClient.dio;

  Future<List<VentaModel>> getAll() async {
    final response = await _dio.get('/ventas');
    return (response.data as List).map((j) => VentaModel.fromJson(j)).toList();
  }

  Future<VentaModel> getOne(String id) async {
    final response = await _dio.get('/ventas/$id');
    return VentaModel.fromJson(response.data);
  }

  Future<VentaModel> create({
    required String folio,
    required TipoPrecio tipoPrecio,
    String? inversionistaId,
    required List<VentaItemDto> items,
    MetodoPago metodoPago = MetodoPago.efectivo,
    double montoTarjeta = 0,
  }) async {
    final data = <String, dynamic>{
      'folio': folio,
      'tipoPrecio': tipoPrecioString(tipoPrecio),
      if (inversionistaId != null) 'inversionistaId': inversionistaId,
      'metodoPago': metodoPagoString(metodoPago),
      if (montoTarjeta > 0) 'montoTarjeta': montoTarjeta,
      'items': items.map((i) => i.toJson()).toList(),
    };
    final response = await _dio.post('/ventas', data: data);
    return VentaModel.fromJson(response.data);
  }

  Future<VentaModel> update(String id, VentaUpdateDto data) async {
    final response = await _dio.put('/ventas/$id', data: data.toJson());
    return VentaModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/ventas/$id');
  }

  Future<List<CierreCajaDia>> getReporte({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final query = <String, String>{};
    if (fechaInicio != null) query['fechaInicio'] = fechaInicio;
    if (fechaFin != null) query['fechaFin'] = fechaFin;
    final response = await _dio.get('/ventas/reporte/cierre-caja',
        queryParameters: query.isEmpty ? null : query);
    return (response.data as List).map((j) => CierreCajaDia.fromJson(j)).toList();
  }
}

String tipoPrecioString(TipoPrecio tp) {
  switch (tp) {
    case TipoPrecio.publico:
      return 'PUBLICO';
    case TipoPrecio.mayorista:
      return 'MAYORISTA';
    case TipoPrecio.inversionista:
      return 'INVERSIONISTA';
  }
}

String metodoPagoString(MetodoPago mp) {
  switch (mp) {
    case MetodoPago.efectivo:
      return 'EFECTIVO';
    case MetodoPago.tarjeta:
      return 'TARJETA';
    case MetodoPago.mixto:
      return 'MIXTO';
  }
}

class VentaItemDto {
  final String zapatoId;
  final int cantidad;
  final double precioUnitario;

  VentaItemDto({
    required this.zapatoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  Map<String, dynamic> toJson() {
    return {
      'zapatoId': zapatoId,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
    };
  }
}

class VentaUpdateDto {
  final String? folio;
  final TipoPrecio? tipoPrecio;
  final String? inversionistaId;
  final MetodoPago? metodoPago;
  final double? montoTarjeta;
  final List<VentaItemDto>? items;

  VentaUpdateDto({
    this.folio,
    this.tipoPrecio,
    this.inversionistaId,
    this.metodoPago,
    this.montoTarjeta,
    this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      if (folio != null) 'folio': folio,
      if (tipoPrecio != null) 'tipoPrecio': tipoPrecioString(tipoPrecio!),
      if (inversionistaId != null) 'inversionistaId': inversionistaId,
      if (metodoPago != null) 'metodoPago': metodoPagoString(metodoPago!),
      if (montoTarjeta != null) 'montoTarjeta': montoTarjeta,
      if (items != null) 'items': items!.map((i) => i.toJson()).toList(),
    };
  }
}

final ventaService = VentaService();
