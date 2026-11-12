// Chụp màn Lịch sử chấm công có lượt Admin "Chỉ tính công" và hộp xem lý do —
// khổ điện thoại 390 dp, dữ liệu mẫu, không gọi mạng.
//
//   flutter test test_thu_cong/chi_tinh_cong_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/chi_tinh_cong_*.png. Không chạy trong `flutter test` mặc định.
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

class _ChamCongGia extends CheckinController {
  final List<Map<String, dynamic>> ds;
  _ChamCongGia(this.ds);
  @override
  Future<List<Map<String, dynamic>>> fetchHistory(String date) async => ds;
  @override
  Future<List<Map<String, dynamic>>> fetchHistoryMonth(String month) async => ds;
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

  testWidgets('lịch sử chấm công: chỉ tính công', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 760 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
    final hom = DateTime.now();
    String luc(int gio, int phut) => DateTime(hom.year, hom.month, hom.day, gio, phut).toIso8601String();
    Get.put<AuthController>(_AuthGia());
    Get.put<CheckinController>(_ChamCongGia([
      {'id': 2, 'actionType': 'CHECK_OUT', 'status': 'APPROVED', 'checkinTime': luc(17, 35), 'note': ''},
      {
        'id': 1, 'actionType': 'CHECK_IN', 'status': 'APPROVED', 'checkinTime': luc(8, 45), 'note': '',
        'chiTinhCong': 'DI_MUON', 'chiTinhCongLyDo': 'Chấm công ở cửa lúc 08:45, lên tới công ty đã muộn',
      },
    ]));

    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: Scaffold(body: CheckinView()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('LỊCH SỬ').first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/chi_tinh_cong_1_lich_su.png'));

    await tester.tap(find.textContaining('Admin chỉ tính công'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/chi_tinh_cong_2_xem_ly_do.png'));
  });
}
