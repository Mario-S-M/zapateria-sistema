import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class InversionistaService {
  final Dio _dio = apiClient.dio;

  Future<List<InversionistaModel>> getAll() async {
    final response = await _dio.get('/inversionistas');
    return (response.data as List).map((j) => InversionistaModel.fromJson(j)).toList();
  }

  Future<List<InversionistaModel>> getActivos() async {
    final response = await _dio.get('/inversionistas/activos');
    return (response.data as List).map((j) => InversionistaModel.fromJson(j)).toList();
  }

  Future<InversionistaModel> getOne(String id) async {
    final response = await _dio.get('/inversionistas/$id');
    return InversionistaModel.fromJson(response.data);
  }

  Future<InversionistaModel> create({
    required String nombre,
    String? telefono,
    String? email,
    bool? activo,
    bool tieneTerminal = false,
  }) async {
    final data = <String, dynamic>{
      'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (activo != null) 'activo': activo,
      'tieneTerminal': tieneTerminal,
    };
    final response = await _dio.post('/inversionistas', data: data);
    return InversionistaModel.fromJson(response.data);
  }

  Future<InversionistaModel> update(
    String id, {
    String? nombre,
    String? telefono,
    String? email,
    bool? activo,
    bool? tieneTerminal,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (telefono != null) data['telefono'] = telefono;
    if (email != null) data['email'] = email;
    if (activo != null) data['activo'] = activo;
    if (tieneTerminal != null) data['tieneTerminal'] = tieneTerminal;
    final response = await _dio.put('/inversionistas/$id', data: data);
    return InversionistaModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/inversionistas/$id');
  }
}

final inversionistaService = InversionistaService();
