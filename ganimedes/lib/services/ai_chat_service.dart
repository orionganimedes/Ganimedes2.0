import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';

class AiChatService {
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;
  AiChatService._internal();

  // Agente de IA (FastAPI) en el VPS.
  static const String _baseUrl = 'http://37.60.242.14:8000';
  String get baseUrl => _baseUrl;

  /// Verifica si el agente de IA está en línea.
  Future<bool> isServiceAvailable() async {
    try {
      final url = Uri.parse('$_baseUrl/api/agent/health');
      final res = await http.get(url).timeout(const Duration(milliseconds: 3500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Chat con STREAMING: devuelve la respuesta palabra por palabra
  /// (efecto máquina de escribir) usando el endpoint de streaming.
  static Stream<String> sendMessageStream(
    String message, {
    List<Map<String, String>>? history,
  }) async* {
    final pb = PocketBaseService();
    final token = pb.token;

    if (token == null || token.isEmpty) {
      throw Exception(
          'No hay sesión activa. Inicia sesión con tu correo y contraseña para usar la IA.');
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/agent/chat/stream'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Authorization'] = token;
      request.body = jsonEncode({
        'message': message.trim(),
        'history': history ?? [],
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        String msg = 'Error del servidor de IA (${streamedResponse.statusCode})';
        try {
          final err = jsonDecode(body);
          if (err['detail'] != null) msg = err['detail'].toString();
        } catch (_) {}
        throw Exception(msg);
      }

      // Leer el stream SSE línea por línea y emitir cada token.
      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final data = jsonDecode(jsonStr);
            if (data['done'] == true) return;
            if (data['error'] != null) throw Exception(data['error']);
            if (data['token'] != null) {
              yield data['token'].toString();
            }
          } catch (e) {
            if (e.toString().contains('Exception:')) rethrow;
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Error de conexión con la IA: $e');
    } finally {
      client.close();
    }
  }

  /// Método de conveniencia de instancia.
  Stream<String> streamMessage(String message, {List<Map<String, String>>? history}) =>
      sendMessageStream(message, history: history);
}
