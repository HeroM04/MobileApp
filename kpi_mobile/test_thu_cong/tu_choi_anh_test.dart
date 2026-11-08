// Chụp màn: gửi bài chọn Facebook / TikTok / Zalo, Lịch sử lọc "Bị từ chối"
// và hộp xem lý do — khổ điện thoại 390 dp, dữ liệu mẫu, không gọi mạng.
//
//   flutter test test_thu_cong/tu_choi_anh_test.dart --update-goldens
//
// Ảnh ra ở test_thu_cong/anh/tu_choi_*.png. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/baipost/controllers/bai_post_controller.dart';
import 'package:kpi_mobile/features/baipost/views/bai_post_view.dart';
import 'package:kpi_mobile/features/home/controllers/kpi_controller.dart';
import 'package:kpi_mobile/shared/widgets/history_date_list_view.dart';
import 'package:kpi_mobile/shared/widgets/the_lich_su.dart';

class _AuthGia extends AuthController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _KpiGia extends KpiController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _BaiPostGia extends BaiPostController {
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

  void dungKhung(WidgetTester tester, double cao) {
    tester.view.physicalSize = Size(390 * 2, cao * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
  }

  Widget app(Widget man) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kieuChuApp(),
        builder: (context, child) => gioiHanCoChu(context, child!),
        home: Scaffold(body: man),
      );

  testWidgets('gửi bài: chọn nền tảng', (tester) async {
    dungKhung(tester, 1000);
    Get.put<AuthController>(_AuthGia());
    Get.put<KpiController>(_KpiGia());
    Get.put<BaiPostController>(_BaiPostGia());
    await tester.pumpWidget(app(const BaiPostView()));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/tu_choi_1_gui_bai_facebook.png'));

    await tester.tap(find.text('Zalo'));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/tu_choi_2_gui_bai_zalo.png'));
  });

  testWidgets('lịch sử: lọc bị từ chối, xem lý do', (tester) async {
    dungKhung(tester, 844);
    final now = DateTime.now();
    String luc(int ngay, int gio) => DateTime(now.year, now.month, ngay, gio, 15).toIso8601String();
    final ds = <Map<String, dynamic>>[
      {'status': 'APPROVED', 'contentType': 'VIDEO', 'platform': 'TIKTOK', 'link': 'https://www.tiktok.com/@trilong/video/7431', 'caption': 'Review căn hộ mẫu Park City', 'submittedAt': luc(1, 9)},
      {'status': 'REJECTED', 'contentType': 'POST', 'platform': 'FACEBOOK', 'link': 'https://facebook.com/trilong/posts/1', 'caption': 'Mở bán đợt 2 The Manor', 'submittedAt': luc(1, 14), 'rejectReason': 'Ảnh chụp không thấy tên dự án và hashtag #trilongland — chụp lại cả bài rồi gửi lại.'},
      {'status': 'PENDING', 'contentType': 'POST', 'platform': 'ZALO', 'link': '', 'caption': 'Chia sẻ nhóm Zalo khách quan tâm', 'submittedAt': luc(1, 16)},
    ];
    Widget the(Map<String, dynamic> item) {
      final loai = item['contentType'] == 'VIDEO' ? 'Video xây kênh' : 'Bài đăng';
      final status = item['status'].toString();
      return TheLichSu(
        anh: null,
        bieuTuong: item['contentType'] == 'VIDEO' ? Icons.videocam_rounded : Icons.article_rounded,
        tieuDe: '$loai · ${tenNenTang(item['platform']?.toString())}',
        phu: item['link']?.toString(),
        noiDung: item['caption']?.toString(),
        submittedAt: item['submittedAt'],
        trangThai: status,
        lyDoTuChoi: lyDoTuChoiCua(item),
        onTap: () => xemChiTietLichSu(
          tieuDe: loai,
          submittedAt: item['submittedAt'],
          trangThai: status,
          nhomDiem: 'Lan tỏa',
          thongTin: [MapEntry('Nền tảng', tenNenTang(item['platform']?.toString()))],
          noiDung: item['caption']?.toString(),
          link: item['link']?.toString(),
          lyDoTuChoi: lyDoTuChoiCua(item),
        ),
      );
    }

    await tester.pumpWidget(app(HistoryDateListView(
      locTuChoi: true,
      onFetchHistory: (_) async => ds,
      onFetchMonth: (_) async => ds,
      thoiDiemCua: (i) => i['submittedAt']?.toString(),
      itemBuilder: (item, _) => the(item),
    )));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/tu_choi_3_lich_su_tat_ca.png'));

    await tester.tap(find.text('Bị từ chối (1)'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/tu_choi_4_loc_bi_tu_choi.png'));

    await tester.tap(find.textContaining('Bài đăng · Facebook'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/tu_choi_5_xem_ly_do.png'));
  });
}
