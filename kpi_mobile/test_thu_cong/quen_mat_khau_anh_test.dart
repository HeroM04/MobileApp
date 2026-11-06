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
import 'package:kpi_mobile/features/auth/views/hop_doi_mat_khau.dart';
import 'package:kpi_mobile/features/auth/views/login_view.dart';

class _AuthGia extends AuthController {
  /// Điện thoại này đã từng đăng nhập tài khoản đang gõ chưa.
  bool coKhoa = false;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<bool> coKhoaKhoiPhuc(String sdt) async => coKhoa;

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

  Future<_AuthGia> dung(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
    final auth = Get.put<AuthController>(_AuthGia()) as _AuthGia;
    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: home,
    ));
    await tester.pump(const Duration(milliseconds: 100));
    return auth;
  }

  Future<void> cho(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('luồng quên mật khẩu', (tester) async {
    final auth = await dung(tester, const LoginView());
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_1_man_dang_nhap.png'));

    // Gõ số điện thoại rồi bấm "Quên mật khẩu?"
    await tester.enterText(find.byType(TextFormField).first, '0968175189');
    await tester.tap(find.text('Quên mật khẩu?'));
    await cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_2_hop_quen_mat_khau.png'));

    // Máy này CHƯA từng đăng nhập tài khoản đó
    await tester.tap(find.text('Đặt lại về 123456'));
    await cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_3_may_chua_dang_nhap.png'));
    await tester.tap(find.text('Đã hiểu'));
    await cho(tester);

    // Máy chính chủ: đặt lại xong, điền sẵn 123456
    auth.coKhoa = true;
    await tester.tap(find.text('Quên mật khẩu?'));
    await cho(tester);
    await tester.tap(find.text('Đặt lại về 123456'));
    await cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_4_da_dat_lai.png'));
    // Cho thông báo tự tắt hẳn (hết giờ + hiệu ứng trượt ra), không thì bài thử báo hẹn giờ còn treo
    await tester.pump(const Duration(seconds: 7));
    await cho(tester);
  });

  testWidgets('đăng nhập bằng 123456 → nhắc đổi mật khẩu', (tester) async {
    final auth = await dung(tester, const Scaffold(backgroundColor: Color(0xFFF4F6FA)));
    moHopDoiMatKhau(auth,
        matKhauCu: '123456',
        loiNhac: 'Bạn đang dùng mật khẩu mặc định 123456 — ai biết số điện thoại của bạn '
            'cũng đăng nhập được. Hãy đặt mật khẩu mới.');
    await cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/quen_mk_5_nhac_doi_mat_khau.png'));
    await tester.tap(find.text('Để sau'));
    await cho(tester);
  });
}
