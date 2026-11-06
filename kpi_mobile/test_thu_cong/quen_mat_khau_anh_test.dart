// Chụp từng bước "Quên mật khẩu?" ở màn đăng nhập, khổ điện thoại 390×844 dp,
// để xem giao diện mà không cần cài app. Bộ điều khiển giả, không gọi mạng.
//
//   flutter test test_thu_cong/quen_mat_khau_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/quen_mk_*.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/auth/views/login_view.dart';

class _AuthGia extends AuthController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<bool> quenMatKhau(String sdt) async => true;
}

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

  Future<void> cho(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('luồng quên mật khẩu', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
    Get.put<AuthController>(_AuthGia());
    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: const LoginView(),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_1_man_dang_nhap.png'));

    // Gõ số điện thoại rồi bấm "Quên mật khẩu?"
    await tester.enterText(find.byType(TextFormField).first, '0968175189');
    await tester.tap(find.text('Quên mật khẩu?'));
    await cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_2_hop_quen_mat_khau.png'));

    // Đặt lại xong: điền sẵn 123456
    await tester.tap(find.text('Đặt lại về 123456'));
    await cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_3_da_dat_lai.png'));

    // Cho thông báo tự tắt hẳn (hết giờ + hiệu ứng trượt ra), không thì bài thử báo hẹn giờ còn treo
    await tester.pump(const Duration(seconds: 7));
    await cho(tester);
  });
}
