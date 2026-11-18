// Chụp Trang chủ khi không tải được điểm KPI (mạng yếu) — trước đây hiện 0 / 100.
//
//   flutter test test_thu_cong/kpi_chua_tai_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/kpi_chua_tai.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/home/controllers/kpi_controller.dart';
import 'package:kpi_mobile/features/home/views/home_view.dart';
import 'package:kpi_mobile/features/shell/controllers/shell_controller.dart';

class _AuthGia extends AuthController {
  _AuthGia() {
    currentUser.value = {'userId': 1, 'role': 'SALE', 'fullName': 'Nguyễn Văn A', 'departmentName': 'Phòng Kinh Doanh 9'};
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _ShellGia extends ShellController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _KpiGia extends KpiController {
  @override
  // ignore: must_call_super
  void onInit() {
    kpiTarget.value = 500;
    taiLoi.value = true;
  }

  @override
  Future<void> fetchKpiData() async {}
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

  testWidgets('Trang chủ khi chưa tải được điểm', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
    tester.view.physicalSize = const Size(390 * 2, 760 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    Get.put<AuthController>(_AuthGia());
    Get.put<ShellController>(_ShellGia());
    Get.put<KpiController>(_KpiGia());
    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: SafeArea(child: HomeView())),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/kpi_chua_tai.png'));
  });
}
