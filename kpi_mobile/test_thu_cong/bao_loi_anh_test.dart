// Chụp các câu báo lỗi sau khi bỏ mã kỹ thuật: lỗi mạng khi chấm công, camera
// đang bận, chờ quá lâu, và màn quét QR khi chưa cấp quyền camera.
//
//   flutter test test_thu_cong/bao_loi_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/bao_loi_*.png. Không chạy trong `flutter test` mặc định.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/core/widgets/thong_bao.dart';
import 'package:kpi_mobile/features/daotao/views/qr_scanner_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

Future<void> _cho(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _app(Widget home) => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: home,
    );

void _khoMay(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 2, 560 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(_napPhong);
  tearDown(Get.reset);

  final nen = Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(title: const Text('Chấm công')),
    body: const SizedBox.expand(),
  );

  Future<void> chup(WidgetTester tester, Object loi, String viec, String ten) async {
    _khoMay(tester);
    await tester.pumpWidget(_app(nen));
    baoLoi(loi, viec: viec);
    await _cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/$ten.png'));
    await tester.pump(const Duration(seconds: 6));
    await _cho(tester);
  }

  testWidgets('mạng chậm khi chấm công', (tester) async {
    await chup(tester, DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionTimeout),
        'chấm công', 'bao_loi_1_mang_cham');
  });

  testWidgets('camera đang bận', (tester) async {
    await chup(tester, PlatformException(code: 'already_active', message: 'Image picker is already active'),
        'chấm công', 'bao_loi_2_camera_ban');
  });

  testWidgets('chờ quá lâu', (tester) async {
    await chup(tester, TimeoutException('x', const Duration(seconds: 30)), 'chấm công', 'bao_loi_3_cho_lau');
  });

  testWidgets('quét QR khi chưa cấp quyền camera', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 820 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR')),
      body: const LoiCameraQuetMa(maLoi: MobileScannerErrorCode.permissionDenied),
    )));
    await _cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/bao_loi_4_qr_chua_cap_quyen.png'));
  });
}
