import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../core/network/api_client.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../shell/views/shell_view.dart';
import '../views/login_view.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  var currentUser = <String, dynamic>{}.obs;

  final _secureStorage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  // 1. Kiểm tra trạng thái đăng nhập khi mở App
  Future<void> checkLoginStatus() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('userId');
        final fullName = prefs.getString('fullName');
        final phoneNumber = prefs.getString('phoneNumber');
        final role = prefs.getString('role');
        final departmentName = prefs.getString('departmentName');
        final officeLat = prefs.getDouble('officeLat');
        final officeLng = prefs.getDouble('officeLng');
        final allowedRadius = prefs.getInt('allowedRadius');

        if (userId != null && fullName != null) {
          currentUser.value = {
            'userId': userId,
            'fullName': fullName,
            'phoneNumber': phoneNumber ?? '',
            'role': role ?? 'SALE',
            'departmentId': prefs.getInt('departmentId'),
            'departmentName': departmentName ?? '',
            'officeLat': officeLat ?? 0.0,
            'officeLng': officeLng ?? 0.0,
            'allowedRadius': allowedRadius ?? 100,
          };
          isLoggedIn.value = true;
        }
      }
    } catch (e) {
      print("Lỗi kiểm tra trạng thái đăng nhập: $e");
    }
  }

  // HÀM KIỂM TRA TRẠNG THÁI SERVER (ĐÁNH THỨC RENDER)
  Future<bool> checkServerStatus() async {
    try {
      final response = await ApiClient.dio.get(
        '/health', // Endpoint nhẹ nhất hoặc một endpoint public nào đó trên server
        options: dio_pkg.Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      // Nếu server phản hồi bất kỳ mã nào (kể cả 404, 401) đều chứng tỏ server đã SỐNG
      return response.statusCode != null;
    } catch (e) {
      if (e is dio_pkg.DioException && e.response != null) {
        return true; // Server sống nhưng trả mã lỗi 4xx, 5xx
      }
      return false; // SocketTimeout, ConnectionRefused -> Server đang ngủ
    }
  }

  // 2. Hàm đăng nhập (Login)
  Future<void> login(String phone, String password) async {
    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar("Lỗi", "Số điện thoại và mật khẩu không được trống!");
      return;
    }

    try {
      isLoading.value = true;

      if (ApiClient.isDebugMode) {
        // --- CHẾ ĐỘ MOCK (DEVELOPMENT) ---
        await Future.delayed(const Duration(seconds: 1)); // Giả lập độ trễ mạng

        // Tạo dữ liệu giả lập chuẩn theo DTO của từng tài khoản tương ứng số điện thoại
        String fullName = 'Lê Thị Sale A (Mock)';
        String role = 'SALE';
        int userId = 3;
        String deptName = 'Phòng Kinh Doanh 1';

        if (phone == '0900000001') {
          fullName = 'Nguyễn Văn Admin (Mock)';
          role = 'ADMIN';
          userId = 1;
          deptName = 'Ban Quản Trị';
        } else if (phone == '0900000002') {
          fullName = 'Trần Văn Trưởng Phòng (Mock)';
          role = 'TRUONG_PHONG';
          userId = 2;
          deptName = 'Phòng Kinh Doanh 1';
        } else if (phone == '0900000005') {
          fullName = 'Nguyễn Thị Văn Phòng (Mock)';
          role = 'VAN_PHONG';
          userId = 4;
          deptName = 'Phòng Hành Chính';
        }

        final mockUser = {
          'userId': userId,
          'fullName': fullName,
          'phoneNumber': phone,
          'role': role,
          'departmentId': 1, // Mặc định cho mock
          'departmentName': deptName,
          'officeLat': 20.999042,
          'officeLng': 105.806702,
          'allowedRadius': 2000,
        };


        // Lưu tokens vào Secure Storage
        await _secureStorage.write(key: 'accessToken', value: 'mock_jwt_access_token_sale_a');
        await _secureStorage.write(key: 'refreshToken', value: 'mock_jwt_refresh_token_sale_a');

        // Lưu profile vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', mockUser['userId'] as int);
        await prefs.setString('fullName', mockUser['fullName'] as String);
        await prefs.setString('phoneNumber', mockUser['phoneNumber'] as String);
        await prefs.setString('role', mockUser['role'] as String);
        await prefs.setInt('departmentId', mockUser['departmentId'] as int);
        await prefs.setString('departmentName', mockUser['departmentName'] as String);
        await prefs.setDouble('officeLat', mockUser['officeLat'] as double);
        await prefs.setDouble('officeLng', mockUser['officeLng'] as double);
        await prefs.setInt('allowedRadius', mockUser['allowedRadius'] as int);

        currentUser.value = mockUser;
        isLoggedIn.value = true;

        Get.snackbar("Thành công", "Đăng nhập thử nghiệm thành công!");
        Get.offAll(() => ShellView());
      } else {
        // --- CHẾ ĐỘ THỰC TẾ (CONNECT BACKEND) ---
        // 1. Kiểm tra trạng thái server trước (Ping 5s)
        bool isServerUp = await checkServerStatus();
        if (!isServerUp) {
          isLoading.value = false;
          Get.snackbar(
            "Hệ thống đang khởi động", 
            "Server đang được đánh thức. Vui lòng đợi khoảng 1 phút rồi bấm Đăng nhập lại nhé!",
            duration: const Duration(seconds: 5),
          );
          return;
        }

        // 2. Nếu server sống, gọi API đăng nhập với Timeout 60s
        final response = await ApiClient.dio.post(
          '/auth/login', 
          data: {
            'phoneNumber': phone,
            'password': password,
          },
          options: dio_pkg.Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          )
        );

        if (response.statusCode == 200 && response.data['status'] == 'SUCCESS') {
          final data = response.data['data'];
          
          // Lưu tokens vào Secure Storage
          await _secureStorage.write(key: 'accessToken', value: data['accessToken']);
          await _secureStorage.write(key: 'refreshToken', value: data['refreshToken']);

          // Lưu profile vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', data['userId']);
          await prefs.setString('fullName', data['fullName'] ?? 'Nhân viên');
          await prefs.setString('phoneNumber', data['phoneNumber'] ?? '');
          await prefs.setString('role', data['role'] ?? 'SALE');
          if (data['departmentId'] != null) {
            await prefs.setInt('departmentId', data['departmentId']);
          } else {
            await prefs.remove('departmentId');
          }
          await prefs.setString('departmentName', data['departmentName'] ?? '');
          await prefs.setDouble('officeLat', (data['officeLat'] as num?)?.toDouble() ?? 0.0);
          await prefs.setDouble('officeLng', (data['officeLng'] as num?)?.toDouble() ?? 0.0);
          await prefs.setInt('allowedRadius', data['allowedRadius'] ?? 100);

          currentUser.value = {
            'userId': data['userId'],
            'fullName': data['fullName'],
            'phoneNumber': data['phoneNumber'],
            'role': data['role'],
            'departmentId': data['departmentId'],
            'departmentName': data['departmentName'],
            'officeLat': data['officeLat'],
            'officeLng': data['officeLng'],
            'allowedRadius': data['allowedRadius'],
          };
          isLoggedIn.value = true;

          Get.snackbar("Thành công", "Đăng nhập hệ thống thành công!");
          Get.offAll(() => ShellView());
        } else {
          final errMsg = response.data['message'] ?? "Sai mật khẩu hoặc tài khoản bị khóa";
          Get.snackbar("Lỗi đăng nhập", errMsg);
        }
      }
    } catch (e) {
      String errorMessage = "Kết nối máy chủ thất bại";
      if (e is dio_pkg.DioException) {
        if (e.response != null && e.response?.data != null) {
          final resData = e.response?.data;
          if (resData is Map) {
            errorMessage = resData['message'] ?? errorMessage;
          } else if (resData is String && resData.isNotEmpty) {
            errorMessage = resData;
          }
        }
      }
      Get.snackbar("Lỗi kết nối", errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // 3. Hàm đăng xuất (Logout)
  Future<void> logout() async {
    try {
      if (!ApiClient.isDebugMode) {
        final refreshToken = await _secureStorage.read(key: 'refreshToken');
        if (refreshToken != null) {
          // Gọi API logout ở backend để vô hiệu hóa token
          try {
            await ApiClient.dio.post('/auth/logout', data: {
              'refreshToken': refreshToken,
            });
          } catch (err) {
            print("Lỗi khi gọi API logout: $err");
          }
        }
      }
    } catch (e) {
      print("Lỗi logout API: $e");
    } finally {
      // Dọn dẹp cả hai phân vùng lưu trữ
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // XÓA SẠCH toàn bộ cache thay vì xóa từng key

      currentUser.clear();
      isLoggedIn.value = false;

      // Reset toàn bộ state trong bộ nhớ RAM để tránh dính dữ liệu (như báo cáo Thực chiến) sang Acc mới
      Get.deleteAll(force: true);
      Get.put(AuthController(), permanent: true); // Khởi tạo lại AuthController vì vừa bị xóa

      Get.snackbar("Thông báo", "Đã đăng xuất tài khoản!");
      Get.offAll(() => LoginView());
    }
  }
  // 4. Hàm đổi mật khẩu (Change Password)
  Future<void> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar("Lỗi", "Vui lòng nhập đầy đủ các trường thông tin!");
      return;
    }
    if (newPassword != confirmPassword) {
      Get.snackbar("Lỗi", "Mật khẩu xác nhận không khớp!");
      return;
    }
    if (newPassword.length < 6) {
      Get.snackbar("Lỗi", "Mật khẩu mới phải có ít nhất 6 ký tự!");
      return;
    }

    try {
      isLoading.value = true;
      if (ApiClient.isDebugMode) {
        await Future.delayed(const Duration(seconds: 1));
        Get.snackbar("Thành công", "Đổi mật khẩu thành công (Mock)!");
        Get.back(); // Đóng dialog
      } else {
        final response = await ApiClient.dio.post('/auth/change-password', data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        });

        if (response.statusCode == 200) {
          Get.back(); // Đóng dialog đổi mật khẩu
          await Get.defaultDialog(
            title: "Thành công",
            middleText: "Đổi mật khẩu thành công. Vui lòng đăng nhập lại!",
            textConfirm: "Đồng ý",
            confirmTextColor: Colors.white,
            onConfirm: () async {
              Get.back(); // Đóng dialog thông báo
              await logout(); // Đăng xuất
            },
            barrierDismissible: false,
          );
        } else {
          final errMsg = response.data['message'] ?? "Có lỗi xảy ra khi đổi mật khẩu";
          Get.snackbar("Lỗi", errMsg);
        }
      }
    } catch (e) {
      String errorMessage = "Lỗi đổi mật khẩu";
      if (e is dio_pkg.DioException) {
        if (e.response != null && e.response?.data != null) {
          final resData = e.response?.data;
          if (resData is Map) {
            errorMessage = resData['message'] ?? errorMessage;
          } else if (resData is String && resData.isNotEmpty) {
            errorMessage = resData;
          }
        }
      }
      Get.snackbar("Lỗi", errorMessage);
    } finally {
      isLoading.value = false;
    }
  }
}
