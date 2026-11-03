import 'package:flutter/material.dart';

/// Giao diện chung của app — một chỗ cho màu, chữ, nút, ô nhập.
ThemeData kieuChuApp() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: const Color(0xFF0F2C59),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F2C59),
      primary: const Color(0xFF0F2C59),
      secondary: const Color(0xFFD4AF37),
    ),
    // Tab 3 mục trên máy 360 dp chỉ rộng 120 dp: lề mặc định 16 dp mỗi bên làm
    // chữ "CHẤM CÔNG", "PHÒNG HỌC"… bị cắt khi chữ to. Thu lề cho chữ đủ chỗ.
    tabBarTheme: const TabBarThemeData(
      labelPadding: EdgeInsets.symmetric(horizontal: 6),
    ),
  );
}

/// Mức phóng chữ lớn nhất app chấp nhận theo cài đặt điện thoại.
///
/// Android cho chỉnh cỡ chữ tới 200% (Samsung còn hơn). App là màn hình số liệu
/// dày đặc — để chữ to hết cỡ thì ô số, thẻ, hàng nút tràn ra ngoài và vỡ bố
/// cục. Giữ tới 130%: người để chữ to vẫn thấy chữ to hơn, mà bố cục không vỡ.
const double heSoChuToiDa = 1.3;

/// Bọc toàn app: tôn trọng cỡ chữ điện thoại nhưng không vượt [heSoChuToiDa].
Widget gioiHanCoChu(BuildContext context, Widget child) =>
    MediaQuery.withClampedTextScaling(maxScaleFactor: heSoChuToiDa, child: child);
