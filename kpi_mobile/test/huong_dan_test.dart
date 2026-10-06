import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/huong_dan.dart';
import 'package:kpi_mobile/features/shell/controllers/shell_controller.dart';

/// Nút (?) trên thanh tiêu đề mở đúng mục hướng dẫn của màn hình đang xem.
/// Thêm hay đổi thứ tự menu mà quên sửa bảng mục thì người dùng bấm (?) ở
/// Chấm công lại nhảy tới Thực chiến.
void main() {
  test('mọi mục trong menu đều có mục hướng dẫn tương ứng', () {
    final menu = ShellController().menuItems;
    expect(mucHuongDanTheoManHinh.length, menu.length);
    for (var i = 0; i < menu.length; i++) {
      expect(mucHuongDanTheoManHinh[i], isNotNull, reason: 'thiếu mục hướng dẫn cho "${menu[i]}"');
    }
    expect(menu[1], 'Chấm công');
    expect(mucHuongDanTheoManHinh[1], 'cham-cong');
    expect(menu[4], 'Đào tạo');
    expect(mucHuongDanTheoManHinh[4], 'dao-tao');
  });

  test('link tới đúng mục; không rõ màn hình thì mở đầu trang', () {
    expect(linkMucHuongDan(1), '$linkHuongDan#cham-cong');
    expect(linkMucHuongDan(), linkHuongDan);
    expect(linkMucHuongDan(99), linkHuongDan);
  });
}
