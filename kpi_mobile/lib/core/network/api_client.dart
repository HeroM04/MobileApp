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

  static const _secureStorage = FlutterSecureStorage(
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  /// Đọc token an toàn – bắt lỗi CryptUnprotectData trên Windows
  static Future<String?> _safeRead(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugLog('⚠️ SecureStorage read lỗi ($key): $e');
      debugLog('   → Xoá storage bị hỏng để tránh crash liên tục...');
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
      // Đăng xuất nếu AuthController đã sẵn sàng
      if (getx.Get.isRegistered<AuthController>()) {
        getx.Get.find<AuthController>().logout();
      }
      return null;
    }
  }

  static final Dio dio = _buildDio();

  /// Lượt làm mới token đang chạy (nếu có). Mọi yêu cầu bị 401 trong lúc đó
  /// cùng chờ lượt này, không tự mở lượt riêng.
  static Future<String?>? _dangLamMoi;

  /// Làm mới access token — CHỈ MỘT LƯỢT tại một thời điểm.
  ///
  /// Mở app sau hơn một giờ, năm sáu màn hình cùng gọi API, cùng bị 401. Trước
  /// đây mỗi cái tự đi làm mới bằng cùng một refresh token; máy chủ xoay vòng
  /// token nên cái đầu thành công và THU HỒI token cũ, các cái sau bị từ chối
  /// "đã thu hồi" → app hiểu là hết phiên → đá người dùng ra đăng nhập lại.
  /// Thành ra refresh token 7 ngày mà cứ hơn một giờ là phải đăng nhập lại.
  ///
  /// Giờ lượt đầu tiên mở một Future dùng chung; các lượt sau await cùng
  /// Future đó và nhận cùng token mới. Trả về null khi không làm mới được.
  static Future<String?> _lamMoiTokenMotLan() {
    final dangChay = _dangLamMoi;
    if (dangChay != null) return dangChay;
    final moi = _lamMoiToken().whenComplete(() { _dangLamMoi = null; });
    _dangLamMoi = moi;
    return moi;
  }

  static Future<String?> _lamMoiToken() async {
    final refreshToken = await _safeRead('refreshToken');
    if (refreshToken == null) return null;
    try {
      // Dio riêng, không interceptor — không thì 401 của chính lượt refresh lại
      // gọi refresh nữa, lặp vô tận.
      final refreshDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 90),
      ));
      final response = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      if (response.statusCode == 200 && response.data['status'] == 'SUCCESS') {
        final data = response.data['data'];
        final String newAccessToken = data['accessToken'];
        final String newRefreshToken = data['refreshToken'];
        await _secureStorage.write(key: 'accessToken', value: newAccessToken);
        await _secureStorage.write(key: 'refreshToken', value: newRefreshToken);
        return newAccessToken;
      }
      debugLog('Refresh token: máy chủ không cấp token mới (${response.statusCode})');
    } on DioException catch (err) {
      debugLog('Refresh token thất bại: ${err.type.name} ${err.response?.statusCode}');
      // Chỉ đăng xuất khi máy chủ NÓI RÕ là token hỏng (4xx). Mất mạng hay
      // máy chủ đang dậy (không có response / 5xx) thì giữ phiên, lần sau thử
      // lại — đá người dùng ra vì rớt wifi 5 giây là vô lý.
      final code = err.response?.statusCode ?? 0;
      if (code >= 400 && code < 500 && getx.Get.isRegistered<AuthController>()) {
        getx.Get.find<AuthController>().logout();
      }
    } catch (err) {
      debugLog('Refresh token lỗi khác: $err');
    }
    return null;
  }

  static Dio _buildDio() {
    final dioInstance = Dio(BaseOptions(
      baseUrl: baseUrl,
      // Bắt tay với máy chủ vốn nhanh; mất mạng thật là hỏng ngay ở bước này
      // nên để ngắn để báo lỗi sớm cho người dùng.
      connectTimeout: const Duration(seconds: 20),
      // Nhưng bắt tay xong thì phải kiên nhẫn: máy chủ chạy gói Render miễn phí,
      // tự ngủ khi vắng người dùng và mất 30 đến 60 giây mới dậy. Để 30 giây như
      // trước thì lần gọi đầu trong ngày gần như luôn quá hạn, rồi bị hiểu nhầm
      // thành mất mạng — nhất là khi còn phải tải kèm ảnh.
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 90),
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
            final token = await _safeRead('accessToken');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Tự động làm mới access token nếu gặp lỗi 401 Unauthorized
          if (!isDebugMode && e.response?.statusCode == 401) {
            final newAccessToken = await _lamMoiTokenMotLan();
            if (newAccessToken != null) {
              try {
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
              } catch (retryErr) {
                debugLog('Gọi lại sau khi làm mới token thất bại: $retryErr');
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