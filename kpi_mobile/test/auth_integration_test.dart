import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/network/api_client.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';

void main() {
  // Cho phép kết nối mạng thực trong quá trình test
  HttpOverrides.global = null;

  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  // Mock FlutterSecureStorage MethodChannel
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> secureStorageMock = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          final key = methodCall.arguments['key'];
          return secureStorageMock[key];
        case 'write':
          final key = methodCall.arguments['key'];
          final value = methodCall.arguments['value'];
          secureStorageMock[key] = value;
          return null;
        case 'delete':
          final key = methodCall.arguments['key'];
          secureStorageMock.remove(key);
          return null;
        case 'deleteAll':
          secureStorageMock.clear();
          return null;
        default:
          return null;
      }
    });
  });

  group('Auth Integration Tests with Real Backend', () {
    late AuthController authController;

    setUp(() {
      // Clear mock storage trước mỗi test
      secureStorageMock.clear();
      // Khởi tạo AuthController
      authController = Get.put(AuthController());
    });

    tearDown(() {
      Get.delete<AuthController>();
    });

    test('Test Real Login API - Sales A Account (Phone: 0900000003, Pass: 123456)', () async {
      print('Bắt đầu gửi yêu cầu đăng nhập thực tế tới backend...');
      print('URL Backend: ${ApiClient.baseUrl}');

      // Thiết lập trạng thái ban đầu
      expect(authController.isLoggedIn.value, false);

      // Gọi hàm login thật
      await authController.login('0900000003', '123456');

      // Đợi Get.snackbar hoặc animation hoàn thành nếu cần, 
      // vì login trả về async lưu dữ liệu, ta kiểm tra kết quả ngay sau đó.
      
      print('Kết quả login: isLoggedIn = ${authController.isLoggedIn.value}');
      print('Dữ liệu user hiện tại: ${authController.currentUser}');

      // Xác minh đăng nhập thành công
      expect(authController.isLoggedIn.value, true);
      expect(authController.currentUser['userId'], isNotNull);
      expect(authController.currentUser['phoneNumber'], '0900000003');
      expect(authController.currentUser['fullName'], isNotNull);
      
      // Xác minh tokens đã được lưu vào Secure Storage mock thành công
      expect(secureStorageMock['accessToken'], isNotNull);
      expect(secureStorageMock['refreshToken'], isNotNull);
      print('Access Token nhận được: ${secureStorageMock['accessToken']}');

      // Đọc SharedPreferences mock để kiểm tra profile
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('userId'), isNotNull);
      expect(prefs.getString('fullName'), isNotNull);

      // --- TEST TIẾP TỤC: ĐĂNG XUẤT ---
      print('Tiến hành kiểm thử đăng xuất...');
      await authController.logout();

      expect(authController.isLoggedIn.value, false);
      expect(authController.currentUser.isEmpty, true);
      expect(secureStorageMock['accessToken'], isNull);
      expect(secureStorageMock['refreshToken'], isNull);
      print('Đăng xuất thành công, dọn dẹp Storage hoàn tất.');
    });

    test('Test Real Login API - Thất bại khi sai mật khẩu', () async {
      print('Thử đăng nhập với mật khẩu sai...');
      expect(authController.isLoggedIn.value, false);

      // Gọi hàm login với sai mật khẩu
      await authController.login('0900000003', 'sai_mat_khau');

      // Xác minh đăng nhập thất bại
      expect(authController.isLoggedIn.value, false);
      expect(secureStorageMock['accessToken'], isNull);
      print('Đăng nhập thất bại chính xác như mong đợi.');
    });
  });
}
