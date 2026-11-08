// Chụp màn Chấm công khi bị báo ngoài phạm vi mà GPS có thể đang sai, khổ
// điện thoại 390 dp, để xem dòng nhắc mà không cần cài app. Bộ điều khiển
// thật nhưng đặt sẵn trạng thái, không gọi mạng / GPS.
//
//   flutter test test_thu_cong/gps_lech_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/gps_*.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/checkin/controllers/checkin_controller.dart';
import 'package:kpi_mobile/features/checkin/views/checkin_view.dart';

class _AuthGia extends AuthController {
  _AuthGia() {
    currentUser.value = {'userId': 1, 'role': 'SALE', 'fullName': 'Nguyễn Văn A'};
  }
  @override
  // ignore: must_call_super
  void onInit() {}
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

  final truongHop = {
    'gps_1_tin_hieu_yeu': (ganDung: false, saiSo: 640.0),
    'gps_2_tat_vi_tri_chinh_xac': (ganDung: true, saiSo: 2000.0),
  };

  for (final e in truongHop.entries) {
    testWidgets(e.key, (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 860 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
      Get.put<AuthController>(_AuthGia());
      final c = Get.put<CheckinController>(CheckinController());
      c.isOutOfRange.value = true;
      c.viTriGanDung.value = e.value.ganDung;
      c.goiYViTri.value = CheckinController.goiYNgoaiPhamVi(ganDung: e.value.ganDung, saiSo: e.value.saiSo);

      await tester.pumpWidget(GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kieuChuApp(),
        builder: (context, child) => gioiHanCoChu(context, child!),
        home: Scaffold(body: CheckinView()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/${e.key}.png'));
    });
  }
}
