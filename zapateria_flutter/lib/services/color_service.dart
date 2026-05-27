import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class ColorService {
  final Dio _dio = apiClient.dio;

  Future<List<ColorModel>> getAll() async {
    final response = await _dio.get('/colores');
    return (response.data as List).map((j) => ColorModel.fromJson(j)).toList();
  }

  Future<ColorModel> getOne(String id) async {
    final response = await _dio.get('/colores/$id');
    return ColorModel.fromJson(response.data);
  }

  Future<ColorModel> create({
    required String nombre,
    String? hexadecimal,
    bool? isCombo,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    final data = <String, dynamic>{'nombre': nombre};
    if (hexadecimal != null) data['hexadecimal'] = hexadecimal;
    if (isCombo != null) data['isCombo'] = isCombo;
    if (primaryColor != null) data['primaryColor'] = primaryColor;
    if (secondaryColor != null) data['secondaryColor'] = secondaryColor;
    final response = await _dio.post('/colores', data: data);
    return ColorModel.fromJson(response.data);
  }

  Future<ColorModel> update(
    String id, {
    String? nombre,
    String? hexadecimal,
    bool? isCombo,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (hexadecimal != null) data['hexadecimal'] = hexadecimal;
    if (isCombo != null) data['isCombo'] = isCombo;
    if (primaryColor != null) data['primaryColor'] = primaryColor;
    if (secondaryColor != null) data['secondaryColor'] = secondaryColor;
    final response = await _dio.put('/colores/$id', data: data);
    return ColorModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/colores/$id');
  }
}

final colorService = ColorService();
