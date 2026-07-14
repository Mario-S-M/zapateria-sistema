import 'package:dio/dio.dart';

/// Extrae un mensaje de error legible para mostrar en un SnackBar/toast.
///
/// El backend (NestJS) responde los errores de validación como
/// `{"message": "texto" | ["texto1", "texto2"], "error": "...", "statusCode": 400}`.
/// Sin esto, un catch genérico solo muestra el `toString()` de DioException,
/// que es ilegible para el usuario.
String friendlyError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join('\n');
      return message.toString();
    }
    if (error.response == null) {
      return 'No se pudo conectar con el servidor. Revisa tu conexión.';
    }
    return 'Error del servidor (${error.response?.statusCode})';
  }
  return error.toString();
}
