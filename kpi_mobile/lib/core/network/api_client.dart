import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'package:kpi_mobile/core/stubs/io_stub.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;
import '../../features/auth/controllers/auth_controller.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final String baseUrl = ApiConstants.baseUrl;
  
  // Chế độ Mock Development để thiết kế UI nhanh không cần bật backend
  static const bool isDebugMode = false; 
  
  static const _secureStorage = FlutterSecureStorage();

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!isDebugMode) {
          // Lấy token từ secure storage nếu không phải chế độ debug
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
              // Gọi API refresh token (sử dụng instance Dio mới để tránh bị lặp vô tận interceptor)
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

                // Gắn token mới vào request hiện tại và thử lại
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
              print("Tự động làm mới token thất bại: $refreshErr");
              // Refresh thất bại -> Gọi AuthController đăng xuất dọn dẹp bộ nhớ và đưa về màn đăng nhập
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
}