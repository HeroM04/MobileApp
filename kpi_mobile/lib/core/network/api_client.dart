import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;
import '../../features/auth/controllers/auth_controller.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static String get baseUrl => ApiConstants.baseUrl;

  // Chế độ Mock Development để thiết kế UI nhanh không cần bật backend
  static const bool isDebugMode = false;

  static const _secureStorage = FlutterSecureStorage();

  static final Dio dio = _buildDio();

  static Dio _buildDio() {
    final dioInstance = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    // ── NETWORK LOGGER (chỉ chạy khi Debug Build) ───────────────────────────
    // In đầy đủ: URL, Method, Headers, Body, Status Code, Response, Error.
    // KHÔNG nuốt lỗi mạng – mọi thứ đều được log ra terminal.
    if (!kIsWeb && const bool.fromEnvironment('dart.vm.product') == false) {
      dioInstance.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugLog('┌── REQUEST ─────────────────────────────────────');
            debugLog('│ [${options.method}] ${options.uri}');
            debugLog('│ Headers: ${options.headers}');
            if (options.data != null) debugLog('│ Body: ${options.data}');
            debugLog('└────────────────────────────────────────────────');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugLog('┌── RESPONSE ────────────────────────────────────');
            debugLog('│ [${response.statusCode}] ${response.requestOptions.uri}');
            debugLog('│ Data: ${response.data}');
            debugLog('└────────────────────────────────────────────────');
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            debugLog('┌── ❌ NETWORK ERROR ─────────────────────────────');
            debugLog('│ [${e.type.name}] ${e.requestOptions.uri}');
            debugLog('│ Message: ${e.message}');
            if (e.response != null) {
              debugLog('│ Status: ${e.response?.statusCode}');
              debugLog('│ Response: ${e.response?.data}');
            } else {
              debugLog('│ ⚠️ Không có response – kiểm tra:');
              debugLog('│    1. Backend có đang chạy không?');
              debugLog('│    2. IP và Port trong .env.development có đúng không?');
              debugLog('│    3. Windows Firewall có chặn port 8088 không?');
              debugLog('│    4. Điện thoại và Laptop có cùng mạng Wi-Fi không?');
            }
            debugLog('└────────────────────────────────────────────────');
            // KHÔNG nuốt lỗi – tiếp tục forward để UI xử lý
            return handler.next(e);
          },
        ),
      );
    }

    // ── AUTH INTERCEPTOR (Token tự động) ────────────────────────────────────
    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!isDebugMode) {
            final token = await _secureStorage.read(key: 'accessToken');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Tự động làm mới access token nếu gặp lỗi 401 Unauthorized
          if (!isDebugMode && e.response?.statusCode == 401) {
            final refreshToken = await _secureStorage.read(key: 'refreshToken');
            if (refreshToken != null) {
              try {
                // Gọi API refresh token (dùng instance Dio mới tránh lặp vô tận interceptor)
                final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
                final response = await refreshDio.post('/auth/refresh', data: {
                  'refreshToken': refreshToken,
                });

                if (response.statusCode == 200 && response.data['status'] == 'SUCCESS') {
                  final data = response.data['data'];
                  final newAccessToken = data['accessToken'];
                  final newRefreshToken = data['refreshToken'];

                  // Lưu token mới vào Secure Storage
                  await _secureStorage.write(key: 'accessToken', value: newAccessToken);
                  await _secureStorage.write(key: 'refreshToken', value: newRefreshToken);

                  // Gắn token mới và retry request gốc
                  e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                  final cloneOptions = Options(
                    method: e.requestOptions.method,
                    headers: e.requestOptions.headers,
                    extra: e.requestOptions.extra,
                    responseType: e.requestOptions.responseType,
                    contentType: e.requestOptions.contentType,
                    validateStatus: e.requestOptions.validateStatus,
                    receiveTimeout: e.requestOptions.receiveTimeout,
                    sendTimeout: e.requestOptions.sendTimeout,
                  );

                  final retryResponse = await Dio().request(
                    '${e.requestOptions.baseUrl}${e.requestOptions.path}',
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                    options: cloneOptions,
                  );

                  return handler.resolve(retryResponse);
                }
              } catch (refreshErr) {
                debugLog('Refresh token thất bại: $refreshErr');
                if (getx.Get.isRegistered<AuthController>()) {
                  getx.Get.find<AuthController>().logout();
                }
              }
            }
          }
          return handler.next(e);
        },
      ),
    );

    return dioInstance;
  }

  /// Log helper – chỉ in trong debug build, tắt hoàn toàn trong release
  static void debugLog(String message) {
    assert(() {
      // ignore: avoid_print
      print(message);
      return true;
    }());
  }
}