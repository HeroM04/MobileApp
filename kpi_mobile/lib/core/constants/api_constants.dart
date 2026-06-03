import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Lấy Base URL từ file .env, fallback nếu không tìm thấy
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.88.98:8080/api/v1';

  // Lấy WS URL từ file .env
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'ws://192.168.88.98:8080/ws';
}
