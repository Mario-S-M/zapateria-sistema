import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class CategoriaService {
  final Dio _dio = apiClient.dio;

  Future<List<CategoriaModel>> getAll() async {
    final response = await _dio.get('/categorias');
    return (response.data as List).map((j) => CategoriaModel.fromJson(j)).toList();
  }

  Future<CategoriaModel> getOne(String id) async {
    final response = await _dio.get('/categorias/$id');
    return CategoriaModel.fromJson(response.data);
  }

  Future<CategoriaModel> create({required String nombre}) async {
    final response = await _dio.post('/categorias', data: {'nombre': nombre});
    return CategoriaModel.fromJson(response.data);
  }

  Future<CategoriaModel> update(String id, {String? nombre, bool? activo}) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (activo != null) data['activo'] = activo;
    final response = await _dio.put('/categorias/$id', data: data);
    return CategoriaModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/categorias/$id');
  }
}

final categoriaService = CategoriaService();
