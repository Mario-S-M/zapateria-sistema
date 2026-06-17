import 'package:dio/dio.dart';
import '../models/models.dart';
import 'api_client.dart';

class ZapatoService {
  final Dio _dio = apiClient.dio;

  Future<List<ZapatoModel>> getAll() async {
    final response = await _dio.get('/zapatos');
    final list = response.data as List;
    return list.map((json) => ZapatoModel.fromJson(json)).toList();
  }

  Future<ZapatoModel> getOne(String id) async {
    final response = await _dio.get('/zapatos/$id');
    return ZapatoModel.fromJson(response.data);
  }

  Future<ZapatoModel> getByCodigoBarras(String codigo) async {
    final response = await _dio.get('/zapatos/codigo/$codigo');
    return ZapatoModel.fromJson(response.data);
  }

  Future<ZapatoModel> create(ZapatoCreateDto data) async {
    final response = await _dio.post('/zapatos', data: data.toJson());
    return ZapatoModel.fromJson(response.data);
  }

  Future<ZapatoModel> update(String id, ZapatoUpdateDto data) async {
    final response = await _dio.put('/zapatos/$id', data: data.toJson());
    return ZapatoModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/zapatos/$id');
  }
}

class ZapatoCreateDto {
  final String codigoBarras;
  final String nombre;
  final String modelo;
  final String foto;
  final double precioCompra;
  final double precioPublico;
  final int medidaInicio;
  final int medidaFin;
  final Horma horma;
  final List<String> colorIds;
  final String? categoriaId;
  final String? inversionistaId;

  ZapatoCreateDto({
    required this.codigoBarras,
    required this.nombre,
    required this.modelo,
    required this.foto,
    required this.precioCompra,
    required this.precioPublico,
    required this.medidaInicio,
    required this.medidaFin,
    this.horma = Horma.normal,
    required this.colorIds,
    this.categoriaId,
    this.inversionistaId,
  });

  Map<String, dynamic> toJson() {
    return {
      'codigoBarras': codigoBarras,
      'nombre': nombre,
      'modelo': modelo,
      'foto': foto,
      'precioCompra': precioCompra,
      'precioPublico': precioPublico,
      'medidaInicio': medidaInicio,
      'medidaFin': medidaFin,
      'horma': horma.apiValue,
      'colorIds': colorIds,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (inversionistaId != null) 'inversionistaId': inversionistaId,
    };
  }
}

class ZapatoUpdateDto {
  final String? codigoBarras;
  final String? nombre;
  final String? modelo;
  final String? foto;
  final double? precioCompra;
  final double? precioPublico;
  final int? medidaInicio;
  final int? medidaFin;
  final Horma? horma;
  final List<String>? colorIds;
  final String? categoriaId;
  final String? inversionistaId;

  ZapatoUpdateDto({
    this.codigoBarras,
    this.nombre,
    this.modelo,
    this.foto,
    this.precioCompra,
    this.precioPublico,
    this.medidaInicio,
    this.medidaFin,
    this.horma,
    this.colorIds,
    this.categoriaId,
    this.inversionistaId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (codigoBarras != null) 'codigoBarras': codigoBarras,
      if (nombre != null) 'nombre': nombre,
      if (modelo != null) 'modelo': modelo,
      if (foto != null) 'foto': foto,
      if (precioCompra != null) 'precioCompra': precioCompra,
      if (precioPublico != null) 'precioPublico': precioPublico,
      if (medidaInicio != null) 'medidaInicio': medidaInicio,
      if (medidaFin != null) 'medidaFin': medidaFin,
      if (horma != null) 'horma': horma!.apiValue,
      if (colorIds != null) 'colorIds': colorIds,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (inversionistaId != null) 'inversionistaId': inversionistaId,
    };
  }
}

final zapatoService = ZapatoService();
