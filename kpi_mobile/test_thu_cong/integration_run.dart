import 'package:dio/dio.dart';

void main() async {
  final baseUrl = 'http://192.168.88.98:8080/api/v1';
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  print('======================================================');
  print('BẮT ĐẦU KIỂM THỬ TÍCH HỢP HỆ THỐNG (APP - BACKEND)');
  print('Backend URL: $baseUrl');
  print('======================================================\n');

  // Case 1: Kiểm tra kết nối Health check
  try {
    print('[TEST 1] Kiểm tra endpoint /auth/ping...');
    final pingResponse = await dio.get('/auth/ping');
    print('Trạng thái: ${pingResponse.statusCode}');
    print('Kết quả: ${pingResponse.data}\n');
    assert(pingResponse.data['status'] == 'OK');
  } catch (e) {
    print('[FAIL] Lỗi kết nối server: $e');
    return;
  }

  String? accessToken;
  String? refreshToken;

  // Case 2: Đăng nhập với thông tin tài khoản Sales A hợp lệ
  try {
    print('[TEST 2] Đăng nhập tài khoản Sales A (0900000003 / 123456)...');
    final loginResponse = await dio.post('/auth/login', data: {
      'phoneNumber': '0900000003',
      'password': '123456',
    });

    print('Trạng thái: ${loginResponse.statusCode}');
    print('Kết quả: ${loginResponse.data}');

    final responseBody = loginResponse.data;
    if (responseBody['status'] == 'SUCCESS') {
      final data = responseBody['data'];
      accessToken = data['accessToken'];
      refreshToken = data['refreshToken'];

      print('[SUCCESS] Đăng nhập thành công!');
      print('- User ID: ${data['userId']}');
      print('- Full Name: ${data['fullName']}');
      print('- Role: ${data['role']}');
      print('- Department: ${data['departmentName']}');
      print('- Access Token: ${accessToken?.substring(0, 20)}...');
      print('- Refresh Token: ${refreshToken?.substring(0, 20)}...\n');
    } else {
      print('[FAIL] Đăng nhập thất bại: ${responseBody['message']}\n');
      return;
    }
  } catch (e) {
    print('[FAIL] Lỗi gọi API đăng nhập: $e\n');
    return;
  }

  // Case 3: Đăng nhập sai mật khẩu
  try {
    print('[TEST 3] Đăng nhập thất bại với sai mật khẩu (0900000003 / wrong_pass)...');
    await dio.post('/auth/login', data: {
      'phoneNumber': '0900000003',
      'password': 'wrong_pass',
    });
    print('[FAIL] Lẽ ra phải báo lỗi nhưng lại thành công!');
  } on DioException catch (e) {
    print('Trạng thái lỗi: ${e.response?.statusCode}');
    print('Thông điệp lỗi nhận từ backend: ${e.response?.data}');
    print('[SUCCESS] Nhận phản hồi lỗi thành công từ backend!\n');
  }

  // Case 4: Sử dụng Access Token để gọi API được bảo mật (/auth/me)
  if (accessToken != null) {
    try {
      print('[TEST 4] Gọi API /auth/me với Access Token vừa nhận...');
      final profileDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      ));
      
      final profileResponse = await profileDio.get('/auth/me');
      print('Trạng thái: ${profileResponse.statusCode}');
      print('Kết quả Profile: ${profileResponse.data}');
      print('[SUCCESS] Xác thực và đọc thông tin Profile thành công!\n');
    } catch (e) {
      print('[FAIL] Lỗi khi gọi API bảo mật /auth/me: $e\n');
    }
  }

  // Case 5: Làm mới token (Token Rotation) bằng Refresh Token
  if (refreshToken != null) {
    try {
      print('[TEST 5] Kiểm tra làm mới token bằng Refresh Token...');
      final refreshResponse = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      print('Trạng thái: ${refreshResponse.statusCode}');
      print('Kết quả: ${refreshResponse.data}');

      final responseBody = refreshResponse.data;
      if (responseBody['status'] == 'SUCCESS') {
        final data = responseBody['data'];
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        print('[SUCCESS] Làm mới token thành công!');
        print('- New Access Token: ${newAccessToken?.substring(0, 20)}...');
        print('- New Refresh Token: ${newRefreshToken?.substring(0, 20)}...\n');
        
        // Cập nhật token mới để gọi logout
        accessToken = newAccessToken;
        refreshToken = newRefreshToken;
      } else {
        print('[FAIL] Làm mới token thất bại: ${responseBody['message']}\n');
      }
    } catch (e) {
      print('[FAIL] Lỗi gọi API refresh token: $e\n');
    }
  }

  // Case 6: Đăng xuất hệ thống (Revoke Token)
  if (accessToken != null && refreshToken != null) {
    try {
      print('[TEST 6] Đăng xuất tài khoản (Revoke Refresh Token)...');
      final logoutDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      ));

      final logoutResponse = await logoutDio.post('/auth/logout', data: {
        'refreshToken': refreshToken,
      });

      print('Trạng thái: ${logoutResponse.statusCode}');
      print('Kết quả: ${logoutResponse.data}');
      print('[SUCCESS] Đăng xuất và vô hiệu hóa token thành công!');
    } catch (e) {
      print('[FAIL] Lỗi gọi API logout: $e');
    }
  }

  print('\n======================================================');
  print('HOÀN THÀNH TOÀN BỘ KIỂM THỬ TÍCH HỢP APP-BACKEND!');
  print('======================================================');
}
