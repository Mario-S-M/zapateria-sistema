import 'package:dio/dio.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = apiClient.dio;

  Future<String> uploadZapatoImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/upload/zapato-image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final filePath = response.data['filePath'] as String;
      final baseUrl = apiClient.dio.options.baseUrl ?? 'http://192.168.0.200:3000';
      return '$baseUrl/$filePath';
    } catch (e) {
      throw Exception('Error al subir la imagen: $e');
    }
  }
}

final uploadService = UploadService();
