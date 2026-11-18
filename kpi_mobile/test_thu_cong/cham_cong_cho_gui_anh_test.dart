// Chụp ô "Chấm công VÀO lúc 08:44 chưa gửi được" trên màn Chấm công.
//
//   flutter test test_thu_cong/cham_cong_cho_gui_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/cham_cong_cho_gui.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/core/utils/dong_ho_may.dart';
import 'package:kpi_mobile/data/services/hang_cho_cham_cong.dart';
import 'package:kpi_mobile/features/checkin/views/the_luot_cho_gui.dart';

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

  testWidgets('ô lượt chấm công chờ gửi', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 330 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final hang = HangChoChamCong(nguoiDung: () => 1, docDongHo: () async => null, thongBao: (_, __, ___) {});
    Get.put<HangChoChamCong>(hang);
    hang.ds.add(LuotChamCong(
      maLuot: 'x', userId: 1, actionType: 'CHECK_IN', lucBam: DateTime(2026, 11, 18, 8, 44),
      mocBam: const MocMay(1, 1), lat: 0, lng: 0, address: '', note: '', anhPath: '',
    ));

    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Chấm công')),
        body: const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.topCenter, child: TheLuotChoGui())),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/cham_cong_cho_gui.png'));
    hang.tamDung();
  });
}
