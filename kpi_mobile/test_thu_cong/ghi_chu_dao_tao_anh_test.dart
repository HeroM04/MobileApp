// Chụp màn Đào tạo: lịch sử buổi học có tên buổi + ghi chú vắng, và ô gửi ghi
// chú ở buổi kỹ năng đang diễn ra — khổ điện thoại 390 dp, dữ liệu mẫu.
//
//   flutter test test_thu_cong/ghi_chu_dao_tao_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/ghi_chu_dao_tao_*.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/daotao/controllers/training_controller.dart';
import 'package:kpi_mobile/features/daotao/views/the_buoi_hoc.dart';
import 'package:kpi_mobile/features/daotao/views/training_detail_view.dart';

class _AuthGia extends AuthController {
  _AuthGia() {
    currentUser.value = {'userId': 1, 'role': 'SALE', 'fullName': 'Nguyễn Văn A'};
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _DaoTaoGia extends TrainingController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  Future<void> reloadRoomDetails(int roomId) async {}
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

Future<void> _cho(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(_napPhong);
  tearDown(Get.reset);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
  });

  testWidgets('lịch sử buổi học có tên buổi và ghi chú', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 820 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final ds = <Map<String, dynamic>>[
      {
        'source': 'NOTE', 'noteStatus': 'PENDING', 'sessionTitle': 'Pháp lý căn hộ chung cư',
        'presenter': 'Anh Hùng', 'trainingType': 'SKILL', 'sessionStartTime': '2026-11-18T02:00:00Z',
        'note': 'Đã học nội dung này rồi (buổi 04/11)',
      },
      {
        'source': 'EXEMPT', 'noteStatus': 'APPROVED', 'sessionTitle': 'Dự án Vinhomes Ocean Park 3',
        'presenter': 'Chị Lan', 'trainingType': 'PROJECT', 'attendedAt': '2026-11-17T02:30:00Z',
        'note': 'Không bán dự án này', 'noteReviewNote': 'Ok em',
      },
      {
        'source': 'NOTE', 'noteStatus': 'REJECTED', 'sessionTitle': 'Telesales: xử lý từ chối',
        'presenter': 'Anh Long', 'trainingType': 'SKILL', 'sessionStartTime': '2026-11-10T07:00:00Z',
        'note': 'Đang đi gặp khách', 'noteReviewNote': 'Buổi này bắt buộc, em học bù tuần sau nhé',
      },
      {
        'source': 'REAL', 'sessionTitle': 'Kỹ năng chốt sale', 'presenter': 'Anh Long',
        'trainingType': 'SKILL', 'attendedAt': '2026-11-04T03:51:00Z',
      },
    ];

    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Lịch sử › Buổi học')),
        body: ListView(padding: const EdgeInsets.all(16), children: [for (final d in ds) TheBuoiHoc(item: d)]),
      ),
    ));
    await _cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/ghi_chu_dao_tao_1_lich_su.png'));
  });

  testWidgets('buổi kỹ năng đang diễn ra: vẫn gửi được ghi chú', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 820 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    Get.put<AuthController>(_AuthGia());
    Get.put<TrainingController>(_DaoTaoGia());

    final bayGio = DateTime.now();
    final buoi = TrainingRoom(
      id: 12, title: 'Pháp lý căn hộ chung cư', description: 'Sổ hồng, hợp đồng mua bán, các bước công chứng.',
      presenter: 'Anh Hùng', roomCode: 'TL_TRAIN_ROOM_8812', dateTime: bayGio.subtract(const Duration(minutes: 10)),
      maxSlots: 0, currentSlots: 0, status: 'UPCOMING', displayStatus: 'ONGOING', trainingType: 'SKILL',
    );

    await tester.pumpWidget(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kieuChuApp(),
      builder: (context, child) => gioiHanCoChu(context, child!),
      home: TrainingDetailView(room: buoi),
    ));
    await _cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/ghi_chu_dao_tao_2_buoi_dang_dien_ra.png'));

    await tester.tap(find.text('Gửi ghi chú cho Admin'));
    await _cho(tester);
    await tester.tap(find.text('Đã học nội dung này rồi'));
    await _cho(tester);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/ghi_chu_dao_tao_3_hop_ghi_chu.png'));
  });
}
