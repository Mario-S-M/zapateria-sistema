import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import 'api_client.dart';

class AgenteService {
  final Dio _dio = apiClient.dio;

  /// Abre una sesión con el agente. El backend guarda la llave de ElevenLabs;
  /// la app solo recibe credenciales efímeras.
  Future<SesionAgenteModel> crearSesion() async {
    final response = await _dio.post('/agente/sesion', data: {
      'plataforma': kIsWeb ? 'web' : 'movil',
    });
    return SesionAgenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Todo el stock con existencia en UNA talla exacta; opcionalmente de una categoría.
  Future<InventarioTallaModel> inventarioPorTalla(
    double talla, {
    String? categoriaId,
  }) async {
    final response = await _dio.get('/agente/inventario', queryParameters: {
      'talla': talla,
      if (categoriaId != null) 'categoriaId': categoriaId,
    });
    return InventarioTallaModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final agenteService = AgenteService();
