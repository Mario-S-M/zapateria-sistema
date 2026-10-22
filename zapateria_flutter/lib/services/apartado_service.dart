import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'venta_service.dart';

class ApartadoPage {
  final List<ApartadoModel> data;
  final int total;
  final int page;
  final int totalPages;

  ApartadoPage({required this.data, required this.total, required this.page, required this.totalPages});
}

class ApartadoService {
  final Dio _dio = apiClient.dio;

  Future<ApartadoPage> getAll({EstadoApartado? estado, int page = 1, int limit = 12}) async {
    final response = await _dio.get('/apartados', queryParameters: {
      if (estado != null) 'estado': estado.name.toUpperCase(),
      'page': page,
      'limit': limit,
    });
    final json = response.data as Map<String, dynamic>;
    return ApartadoPage(
      data: (json['data'] as List).map((j) => ApartadoModel.fromJson(j)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  Future<ApartadoModel> create({
    required String folio,
    required String clienteNombre,
    String? clienteTelefono,
    required TipoPrecio tipoPrecio,
    String? inversionistaId,
    required List<VentaItemDto> items,
    double abonoInicial = 0,
    MetodoAbono metodoAbono = MetodoAbono.efectivo,
  }) async {
    final response = await _dio.post('/apartados', data: {
      'folio': folio,
      'clienteNombre': clienteNombre,
      if (clienteTelefono != null && clienteTelefono.isNotEmpty) 'clienteTelefono': clienteTelefono,
      'tipoPrecio': tipoPrecioString(tipoPrecio),
      if (inversionistaId != null) 'inversionistaId': inversionistaId,
      'items': items.map((i) => i.toJson()).toList(),
      if (abonoInicial > 0)
        'abonoInicial': {'monto': abonoInicial, 'metodoPago': metodoAbono.name.toUpperCase()},
    });
    return ApartadoModel.fromJson(response.data);
  }

  Future<ApartadoModel> addAbono(String id, double monto, MetodoAbono metodo) async {
    final response = await _dio.post('/apartados/$id/abonos',
        data: {'monto': monto, 'metodoPago': metodo.name.toUpperCase()});
    return ApartadoModel.fromJson(response.data);
  }

  Future<ApartadoModel> entregar(String id) async {
    final response = await _dio.post('/apartados/$id/entregar');
    return ApartadoModel.fromJson(response.data);
  }

  Future<ApartadoModel> cancelar(String id) async {
    final response = await _dio.post('/apartados/$id/cancelar');
    return ApartadoModel.fromJson(response.data);
  }
}

/// Extrae el mensaje legible de un error del backend (400 con `message`).
String apartadoErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.join('\n') : m.toString();
    }
  }
  return e.toString();
}

final apartadoService = ApartadoService();
