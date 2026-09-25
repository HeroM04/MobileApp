import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/shell/controllers/shell_controller.dart';

/// AuthController giả: bỏ qua đọc bộ nhớ máy và gọi mạng lúc khởi tạo, chỉ
/// giữ vai trò để menu đọc.
class _AuthGia extends AuthController {
  _AuthGia(String vaiTro) {
    currentUser.value = {'userId': 1, 'role': vaiTro};
  }

  @override
  // ignore: must_call_super
  void onInit() {}
}

/// Menu bên trái theo vai trò. Back-Office chỉ chấm công — thấy "Thực chiến",
/// "Chốt căn"… là bấm vào gửi báo cáo rồi chờ điểm không bao giờ tới.
void main() {
  tearDown(Get.reset);

  List<String> menuCua(String vaiTro) {
    Get.put<AuthController>(_AuthGia(vaiTro));
    final shell = ShellController();
    return shell.mucHienThi.map((i) => shell.menuItems[i]).toList();
  }

  test('Sale và Trưởng phòng thấy đủ mọi phân hệ', () {
    expect(menuCua('SALE'), hasLength(10));
    Get.reset();
    expect(menuCua('TRUONG_PHONG'), hasLength(10));
  });

  test('Văn phòng (Back-Office) chỉ thấy phần chấm công', () {
    expect(menuCua('VAN_PHONG'), ['Trang chủ', 'Chấm công', 'Phản hồi', 'Trang cá nhân']);
  });

  test('Admin đăng nhập app cũng không có phân hệ KPI', () {
    expect(menuCua('ADMIN'), isNot(contains('Chốt căn')));
    expect(menuCua('ADMIN'), isNot(contains('Thông báo')));
  });

  test('chỉ số menu giữ nguyên ý nghĩa sau khi lọc — mở đúng màn hình', () {
    Get.put<AuthController>(_AuthGia('VAN_PHONG'));
    final shell = ShellController();
    // Chỉ số là tham số của changeMenuIndex: "Phản hồi" phải vẫn là 6
    expect(shell.mucHienThi, [0, 1, 6, 9]);
    expect(shell.menuItems[6], 'Phản hồi');
  });
}
