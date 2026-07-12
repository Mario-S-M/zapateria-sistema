import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class MarcaService {
  final Dio _dio = apiClient.dio;

  Future<List<MarcaModel>> getAll() async {
    final response = await _dio.get('/marcas');
    return (response.data as List).map((j) => MarcaModel.fromJson(j)).toList();
  }

  Future<MarcaModel> getOne(String id) async {
    final response = await _dio.get('/marcas/$id');
    return MarcaModel.fromJson(response.data);
  }

  Future<MarcaModel> create({
    required String nombre,
    String? codigoEjemplo,
    List<BarcodeSegmentoModel>? patronSegmentos,
  }) async {
    final response = await _dio.post(
      '/marcas',
      data: {
        'nombre': nombre,
        if (codigoEjemplo != null) 'codigoEjemplo': codigoEjemplo,
        if (patronSegmentos != null)
          'patronSegmentos': patronSegmentos.map((s) => s.toJson()).toList(),
      },
    );
    return MarcaModel.fromJson(response.data);
  }

  Future<MarcaModel> update(
    String id, {
    String? nombre,
    String? codigoEjemplo,
    List<BarcodeSegmentoModel>? patronSegmentos,
    bool? activo,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (codigoEjemplo != null) data['codigoEjemplo'] = codigoEjemplo;
    if (patronSegmentos != null) {
      data['patronSegmentos'] = patronSegmentos.map((s) => s.toJson()).toList();
    }
    if (activo != null) data['activo'] = activo;
    final response = await _dio.put('/marcas/$id', data: data);
    return MarcaModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/marcas/$id');
  }
}

final marcaService = MarcaService();
