import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../data/services/push_service.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../shell/views/shell_view.dart';
import '../views/login_view.dart';
import '../../../core/widgets/thong_bao.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  var currentUser = <String, dynamic>{}.obs;

  final _secureStorage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    wakeUpServer(); // Gọi ngầm để đánh thức Render ngay khi mở app
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
          PushService().khoiDong(); // mở lại app khi đã đăng nhập
        }
      }
    } catch (e) {
      print("Lỗi kiểm tra trạng thái đăng nhập: $e");
    }
  }

  // HÀM ĐÁNH THỨC RENDER NGẦM KHI MỞ APP
  //
  // Gọi /auth/ping — đường dẫn công khai, không cần token. Trước đây gọi
  // /health là đường dẫn không hề tồn tại nên máy chủ trả về 404: vẫn đánh
  // thức được nhưng mỗi lần mở app lại sinh một lỗi 404 trong nhật ký, làm
  // nhiễu khi cần tra lỗi thật.
  //
  // Chờ 20 giây thay vì 3, vì máy chủ ngủ dậy mất 30 đến 60 giây — 3 giây thì
  // gần như luôn quá hạn. Dù sao hàm này cũng chạy ngầm, không giữ màn hình.
  Future<void> wakeUpServer() async {
    try {
      await ApiClient.dio.get(
        '/auth/ping',
        options: dio_pkg.Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
    } catch (_) {
      // Bỏ qua lỗi vì mục đích chỉ là gửi request để Render khởi động
    }
  }

  // 2. Hàm đăng nhập (Login)
  Future<void> login(String phone, String password) async {
    if (phone.isEmpty || password.isEmpty) {
      snack("Lỗi", "Số điện thoại và mật khẩu không được trống!");
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
        PushService().khoiDong();

        snack("Thành công", "Đăng nhập thử nghiệm thành công!");
        Get.offAll(() => ShellView());
      } else {
        // --- CHẾ ĐỘ THỰC TẾ (CONNECT BACKEND) ---
        // Gọi thẳng API đăng nhập với Timeout 60s để chờ Render thức dậy
        final response = await ApiClient.dio.post(
          '/auth/login', 
          data: {
            'phoneNumber': phone,
            'password': password,
          },
          options: dio_pkg.Options(
            sendTimeout: const Duration(seconds: 90),
            receiveTimeout: const Duration(seconds: 90),
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
          PushService().khoiDong();

          snack("Thành công", "Đăng nhập hệ thống thành công!");
          Get.offAll(() => ShellView());
        } else {
          final errMsg = response.data['message'] ?? "Sai mật khẩu hoặc tài khoản bị khóa";
          snack("Lỗi đăng nhập", errMsg);
        }
      }
    } catch (e) {
      // Trước đây mọi lỗi đều hiện "Lỗi kết nối" — sai mật khẩu cũng "lỗi kết nối",
      // máy chủ đang dậy cũng "lỗi kết nối", app ném lỗi nội bộ cũng "lỗi kết nối".
      // Người dùng không biết phải làm gì, người sửa không có manh mối.
      final loi = describeApiFailure(e, action: 'đăng nhập');
      final tieuDe = loi.kind == ApiFailureKind.user ? 'Đăng nhập thất bại' : loi.title;
      snack(tieuDe, loi.message);
    } finally {
      isLoading.value = false;
    }
  }

  // 3. Hàm đăng xuất (Logout)
  //
  // Thứ tự: dọn máy và về màn hình đăng nhập NGAY, rồi mới báo máy chủ trong nền.
  //
  // Trước đây làm ngược lại — gọi máy chủ xong mới dọn — nên người dùng bấm
  // Đăng xuất mà không thấy gì xảy ra:
  //   - Máy chủ Render đang ngủ: hai lượt gọi, mỗi lượt chờ tới 110 giây.
  //   - Token đã hết hạn (mở app sáng hôm sau): mỗi lượt gọi bị 401 → interceptor
  //     đi làm mới token → thất bại → interceptor gọi lại logout() → lồng vào
  //     chính lượt đăng xuất đang dở, mỗi tầng lại gọi mạng thêm lần nữa.
  // Người dùng muốn rời đi; máy chủ có thu hồi được token hay không là việc phụ,
  // không được bắt họ chờ.
  bool _dangDangXuat = false;

  Future<void> logout() async {
    if (_dangDangXuat) return;   // chặn gọi lồng từ interceptor khi 401
    _dangDangXuat = true;

    // 1) Giữ lại token để báo máy chủ, xong dọn sạch máy
    String? accessToken;
    String? refreshToken;
    try {
      accessToken = await _secureStorage.read(key: 'accessToken');
      refreshToken = await _secureStorage.read(key: 'refreshToken');
    } catch (_) {}
    try { await _secureStorage.delete(key: 'accessToken'); } catch (_) {}
    try { await _secureStorage.delete(key: 'refreshToken'); } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // XÓA SẠCH toàn bộ cache thay vì xóa từng key
    } catch (_) {}

    currentUser.clear();
    isLoggedIn.value = false;

    Get.offAll(() => LoginView());
    // Hiển thị thông báo sau khi đã chuyển trang để tránh lỗi rebuild widget cũ
    snack("Thông báo", "Đã đăng xuất tài khoản!");
    _dangDangXuat = false;

    // 2) Báo máy chủ trong nền — không await, không chặn ai
    _baoMayChuDangXuat(accessToken, refreshToken);
  }

  /// Gỡ mã thiết bị (thôi nhận thông báo) và thu hồi refresh token ở máy chủ.
  /// Dùng Dio riêng KHÔNG có interceptor: token hết hạn thì 401 rồi thôi, không
  /// kéo theo làm mới token hay gọi lại logout. Mỗi việc chờ tối đa vài giây.
  Future<void> _baoMayChuDangXuat(String? accessToken, String? refreshToken) async {
    if (ApiClient.isDebugMode || accessToken == null) return;
    final dio = dio_pkg.Dio(dio_pkg.BaseOptions(
      baseUrl: ApiClient.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      headers: {'Authorization': 'Bearer $accessToken'},
    ));
    await PushService().huyDangKy(dio: dio);
    if (refreshToken != null) {
      try {
        await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // Không thu hồi được cũng không sao: token đã bị xóa khỏi máy,
        // refresh token tự hết hạn sau 7 ngày.
      }
    }
  }
  // 4. Hàm đổi mật khẩu (Change Password)
  Future<void> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      snack("Lỗi", "Vui lòng nhập đầy đủ các trường thông tin!");
      return;
    }
    if (newPassword != confirmPassword) {
      snack("Lỗi", "Mật khẩu xác nhận không khớp!");
      return;
    }
    if (newPassword.length < 6) {
      snack("Lỗi", "Mật khẩu mới phải có ít nhất 6 ký tự!");
      return;
    }

    try {
      isLoading.value = true;
      if (ApiClient.isDebugMode) {
        await Future.delayed(const Duration(seconds: 1));
        snack("Thành công", "Đổi mật khẩu thành công (Mock)!");
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
          snack("Lỗi", errMsg);
        }
      }
    } catch (e) {
      final loi = describeApiFailure(e, action: 'đổi mật khẩu');
      snack(loi.kind == ApiFailureKind.user ? 'Không đổi được mật khẩu' : loi.title, loi.message);
    } finally {
      isLoading.value = false;
    }
  }
}
