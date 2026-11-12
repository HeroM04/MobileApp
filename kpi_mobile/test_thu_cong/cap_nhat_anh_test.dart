// Chụp hộp "Đã có bản mới" nhân viên Android thấy khi mở app — khổ điện thoại
// 390 dp, dữ liệu mẫu, không gọi mạng.
//
//   flutter test test_thu_cong/cap_nhat_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/cap_nhat_*.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/core/utils/cap_nhat_app.dart';

Future<void> _napPhong() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final thuMuc = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> doc(String ten) async => ByteData.view((await File('$thuMuc/$ten').readAsBytes()).buffer);
  for (final ho in ['Roboto', 'Montserrat', 'Poppins']) {
    final p = FontLoader(ho);
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']) {
      p.addFont(doc(f));
    }
    await p.load();
  }
  final icons = FontLoader('MaterialIcons')..addFont(doc('materialicons-regular.otf'));
  await icons.load();
}

void main() {
  setUpAll(_napPhong);
  tearDown(Get.reset);

  const ghiChu = '- Bài đăng: chọn Facebook / TikTok / Zalo; hashtag không bắt buộc\n'
      '- Lịch sử: lọc "Bị từ chối" và xem lý do Admin ghi\n'
      '- Chấm công: xem ghi chú khi Admin chỉ tính công';
  final truongHop = {
    'cap_nhat_1_khong_ghi_chu': const BanMoi(soBuild: 71, ten: '1.2.0', linkApk: 'https://x/y.apk'),
    'cap_nhat_2_co_ghi_chu': const BanMoi(soBuild: 71, ten: '1.2.0', linkApk: 'https://x/y.apk', ghiChu: ghiChu),
    'cap_nhat_3_bat_buoc': const BanMoi(soBuild: 71, ten: '1.2.0', linkApk: 'https://x/y.apk', ghiChu: ghiChu, batBuoc: true),
  };

  for (final e in truongHop.entries) {
    testWidgets(e.key, (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kieuChuApp(),
        builder: (context, child) => gioiHanCoChu(context, child!),
        home: const Scaffold(body: Center(child: Text('Màn hình chính', style: TextStyle(color: Colors.grey)))),
      ));
      // test_thu_cong không nằm trong test/ nên analyzer không coi là test
      // ignore: invalid_use_of_visible_for_testing_member
      Get.dialog(hopCapNhatXemThu(e.value), barrierDismissible: false);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/${e.key}.png'));
    });
  }
}
