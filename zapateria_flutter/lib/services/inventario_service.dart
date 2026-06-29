import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class InventarioService {
  final Dio _dio = apiClient.dio;

  Future<List<InventarioItemModel>> getAll() async {
    final response = await _dio.get('/inventario');
    return (response.data as List)
        .map((j) => InventarioItemModel.fromJson(j))
        .toList();
  }

  Future<List<InventarioItemModel>> getByZapato(String zapatoId) async {
    final response = await _dio.get('/inventario/zapato/$zapatoId');
    return (response.data as List)
        .map((j) => InventarioItemModel.fromJson(j))
        .toList();
  }

  Future<void> bulkUpsert(List<Map<String, dynamic>> items) async {
    await _dio.post('/inventario/bulk', data: {'items': items});
  }
}

final inventarioService = InventarioService();
