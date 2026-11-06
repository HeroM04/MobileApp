// Soát giao diện khi người dùng để CỠ CHỮ TO trên điện thoại.
//
// Dựng từng màn hình ở khổ Android phổ biến (360 dp ngang) với nhiều mức phóng
// chữ, đếm chỗ tràn (RenderFlex overflowed…) và chụp ảnh để xem bằng mắt.
// Ảnh dùng phông Roboto thật của Flutter SDK, như trên Android. Bộ điều khiển
// được thay bằng bản giả (không gọi mạng), dữ liệu mẫu đặt sẵn.
//
//   flutter test test_thu_cong/giao_dien_chu_to_test.dart --update-goldens
//   (đặt biến HE_SO=1.0,1.3,2.0 để đổi các mức phóng chữ cần xem)
//
// Ảnh ra ở test_thu_cong/anh/. Không chạy trong `flutter test` mặc định.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/core/theme/giao_dien.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/auth/views/login_view.dart';
import 'package:kpi_mobile/features/baipost/controllers/bai_post_controller.dart';
import 'package:kpi_mobile/features/baipost/views/bai_post_view.dart';
import 'package:kpi_mobile/features/checkin/controllers/checkin_controller.dart';
import 'package:kpi_mobile/features/checkin/controllers/leave_controller.dart';
import 'package:kpi_mobile/features/checkin/views/checkin_view.dart';
import 'package:kpi_mobile/features/checkin/views/leave_request_tab.dart';
import 'package:kpi_mobile/features/chotcan/controllers/chot_can_controller.dart';
import 'package:kpi_mobile/features/chotcan/views/chot_can_view.dart';
import 'package:kpi_mobile/features/daotao/controllers/training_controller.dart';
import 'package:kpi_mobile/features/daotao/views/dao_tao_view.dart';
import 'package:kpi_mobile/features/gieohat/controllers/referral_controller.dart';
import 'package:kpi_mobile/features/gieohat/views/gieo_hat_view.dart';
import 'package:kpi_mobile/features/home/controllers/kpi_controller.dart';
import 'package:kpi_mobile/features/home/views/home_view.dart';
import 'package:kpi_mobile/features/phanhoi/controllers/phan_hoi_controller.dart';
import 'package:kpi_mobile/features/phanhoi/views/phan_hoi_view.dart';
import 'package:kpi_mobile/features/profile/views/profile_view.dart';
import 'package:kpi_mobile/features/shell/controllers/shell_controller.dart';
import 'package:kpi_mobile/features/thongbao/controllers/thong_bao_controller.dart';
import 'package:kpi_mobile/features/thongbao/views/thong_bao_view.dart';
import 'package:kpi_mobile/features/thucchien/controllers/thuc_chien_controller.dart';
import 'package:kpi_mobile/features/thucchien/views/thuc_chien_view.dart';

// ── Bộ điều khiển giả: bỏ phần gọi mạng / hẹn giờ lúc khởi tạo ──────────────
class _AuthGia extends AuthController {
  _AuthGia() {
    currentUser.value = {
      'userId': 1, 'role': 'TRUONG_PHONG', 'fullName': 'Nguyễn Trung Cương',
      'departmentName': 'Phòng Kinh Doanh 1', 'phoneNumber': '0968175189',
    };
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _KpiGia extends KpiController {
  _KpiGia() {
    kpiPoints.value = 186; kpiTarget.value = 400;
    kpiWeeklyPoints.value = 64; kpiWeeklyTarget.value = 100;
    attendancePoints.value = 25; fieldBattleCount.value = 7; socialPostCount.value = 4;
    trainingAttendanceCount.value = 2; totalDealsClosed.value = 1;
    departmentMembers.assignAll([
      {'fullName': 'Trần Thị Thanh Hương', 'total': 92, 'weeklyTotal': 40},
      {'fullName': 'Lê Văn Minh', 'total': 71, 'weeklyTotal': 22},
    ]);
  }
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  // ignore: must_call_super
  void onClose() {}
}

class _ShellGia extends ShellController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _LeaveGia extends LeaveController {
  _LeaveGia() {
    myRequests.assignAll([
      {'id': 1, 'leaveDate': '2026-11-04', 'reason': 'Con ốm, xin nghỉ đưa đi khám bệnh viện Nhi', 'status': 'PENDING', 'kpiPoints': -10},
      {'id': 2, 'leaveDate': '2026-10-24', 'reason': 'Việc gia đình', 'status': 'APPROVED', 'kpiPoints': -10},
      {'id': 3, 'leaveDate': '2026-10-17', 'reason': 'Về quê', 'status': 'APPROVED', 'kpiPoints': 0},
      {'id': 4, 'leaveDate': '2026-10-10', 'reason': 'Hệ thống tự ghi nhận: không chấm công', 'status': 'UNEXCUSED', 'kpiPoints': -15},
    ]);
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _ReferralGia extends ReferralController {
  _ReferralGia() {
    mySubmissions.assignAll([
      {'id': 1, 'candidateName': 'Nguyễn Trung Cương', 'candidatePhone': '0968175189', 'note': 'đồng nghiệp cũ', 'status': 'PENDING'},
      {'id': 2, 'candidateName': 'Phạm Thị Ngọc Ánh', 'candidatePhone': '0912345678', 'note': 'bạn học', 'status': 'APPROVED', 'rewardDate': '2026-11-28', 'rewardGranted': false},
      {'id': 3, 'candidateName': 'Đỗ Minh Khang', 'candidatePhone': '0987654321', 'status': 'REJECTED', 'reviewNote': 'Chưa đủ kinh nghiệm'},
    ]);
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _TrainingGia extends TrainingController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<List<Map<String, dynamic>>> fetchHistory(String date) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchLichSu1Kem1(String date) async => [
        {'id': 3, 'content': 'Kèm em Minh cách tư vấn dự án Metropoli5: chính sách bán hàng, tiến độ thanh toán, cách xử lý khách so sánh giá với dự án bên cạnh', 'status': 'PENDING', 'submittedAt': '2026-11-04T15:20:00+07:00'},
        {'id': 2, 'content': 'Hướng dẫn gọi điện chăm sóc khách cũ', 'status': 'APPROVED', 'submittedAt': '2026-11-04T10:05:00+07:00'},
        {'id': 1, 'content': 'Đào tạo nhanh quy trình ký gửi', 'status': 'REJECTED', 'submittedAt': '2026-11-04T08:50:00+07:00'},
      ];
}

class _PhanHoiGia extends PhanHoiController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _ThongBaoGia extends ThongBaoController {
  _ThongBaoGia() {
    nhanKy.value = 'Tuần 03/11 – 09/11/2026';
    tongCong.value = 45; tongTru.value = 10; diemKy.value = 35; tranKy.value = 100;
    khoanDiem.assignAll([
      {'points': 5, 'effectivePoints': 5, 'reason': 'Chấm công đúng giờ ngày 03/11', 'category': 'attendance', 'createdAt': '2026-11-03T08:31:00+07:00'},
      {'points': 10, 'effectivePoints': 10, 'reason': 'Thực chiến — gặp khách tại dự án Metropoli5', 'category': 'meeting', 'createdAt': '2026-11-03T10:15:00+07:00'},
      {'points': -10, 'effectivePoints': -10, 'reason': 'Nghỉ có phép ngày 04/11 — Admin đã duyệt đơn', 'category': 'attendance', 'createdAt': '2026-11-04T12:00:00+07:00'},
    ]);
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _ThucChienGia extends ThucChienController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  // ignore: must_call_super
  void onClose() {}

  @override
  Future<List<Map<String, dynamic>>> fetchHistory(String date) async => [
        {'id': 2, 'battleType': 'MEETING', 'customerName': 'Anh Tuấn', 'customerPhone': '0912345678', 'project': 'Metropoli5',
         'content': 'Dẫn khách xem căn 2PN tầng 18, khách quan tâm chính sách vay 0% lãi suất 18 tháng', 'location': 'Tố Hữu, Hà Đông',
         'status': 'APPROVED', 'submittedAt': '2026-11-04T10:15:00+07:00'},
        {'id': 1, 'battleType': 'SUPPORT', 'customerName': '', 'project': '', 'content': 'Hỗ trợ khách ký hợp đồng',
         'status': 'PENDING', 'submittedAt': '2026-11-04T08:50:00+07:00'},
      ];
}

class _BaiPostGia extends BaiPostController {
  @override
  Future<List<Map<String, dynamic>>> fetchHistory(String date) async => [
        {'id': 1, 'contentType': 'POST', 'platform': 'FACEBOOK', 'link': 'https://facebook.com/trilongland/posts/123',
         'caption': 'Mở bán đợt 2 dự án Metropoli5 — chiết khấu 5% cho khách đặt cọc trong tuần', 'status': 'PENDING',
         'submittedAt': '2026-11-04T09:30:00+07:00'},
      ];
}

Future<void> _napPhong() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final thuMuc = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> doc(String ten) async => ByteData.view((await File('$thuMuc/$ten').readAsBytes()).buffer);
  // Montserrat / Poppins (logo) không có trong app: điện thoại Android tự thay bằng Roboto — làm y như vậy
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

/// Các màn hình cần soát: tên ảnh → cách dựng.
final Map<String, Widget Function()> _manHinh = {
  'dang_nhap': () => const LoginView(),
  'trang_chu': () => Scaffold(backgroundColor: const Color(0xFFF4F6FA), body: HomeView()),
  'cham_cong': () => Scaffold(body: CheckinView()),
  'don_vang': () => Scaffold(body: LeaveRequestTab()),
  'thuc_chien': () => const Scaffold(body: ThucChienView()),
  'bai_post': () => const Scaffold(body: BaiPostView()),
  'dao_tao': () => const Scaffold(body: DaoTaoView()),
  'gieo_hat': () => const Scaffold(body: GieoHatView()),
  'phan_hoi': () => const Scaffold(body: PhanHoiView()),
  'chot_can': () => const Scaffold(body: ChotCanView()),
  'thong_bao': () => const Scaffold(body: ThongBaoView()),
  'ca_nhan': () => const Scaffold(body: ProfileView()),
};

void _dangKyGia() {
  // Kho bảo mật giả, trống: màn đăng nhập đọc phần "Ghi nhớ đăng nhập" lúc mở.
  // Không giả thì đọc lỗi → KhoToken chờ 300 ms thử lại → hẹn giờ còn treo khi
  // bài thử kết thúc.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
  Get.put<AuthController>(_AuthGia());
  Get.put<ShellController>(_ShellGia());
  Get.put<KpiController>(_KpiGia());
  Get.put<LeaveController>(_LeaveGia());
  Get.put<ReferralController>(_ReferralGia());
  Get.put<TrainingController>(_TrainingGia());
  Get.put<PhanHoiController>(_PhanHoiGia());
  Get.put<ThongBaoController>(_ThongBaoGia());
  Get.put<ThucChienController>(_ThucChienGia());
  Get.put<BaiPostController>(_BaiPostGia());
  Get.put<ChotCanController>(ChotCanController());
  Get.put<CheckinController>(CheckinController());
}

void main() {
  setUpAll(_napPhong);
  tearDown(Get.reset);

  final heSoCanXem = (Platform.environment['HE_SO'] ?? '1.0,1.3').split(',').map(double.parse);
  for (final ten in _manHinh.keys) {
    for (final heSo in heSoCanXem) {
      testWidgets('$ten — chữ x$heSo', (tester) async {
        final tran = <String>[];
        final cu = FlutterError.onError;
        FlutterError.onError = (d) {
          final s = d.exceptionAsString();
          tran.add(s.contains('overflowed') ? s.split('\n').first : 'LỖI KHÁC: ${s.split('\n').first}');
        };

        tester.view.physicalSize = const Size(360 * 2, 1500 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        _dangKyGia();

        await tester.pumpWidget(GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: kieuChuApp(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(heSo)),
            child: gioiHanCoChu(context, child!),
          ),
          home: _manHinh[ten]!(),
        ));
        await tester.pump(const Duration(milliseconds: 100));

        FlutterError.onError = cu;
        // ignore: avoid_print
        print('$ten x$heSo: ${tran.where((t) => !t.startsWith('LỖI')).length} chỗ tràn'
            '${tran.isEmpty ? '' : '\n  - ${tran.toSet().join('\n  - ')}'}');
        await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/${ten}_x$heSo.png'));
      });
    }
  }

  // Tab Lịch sử của Đào tạo → chuyển sang "Đào tạo 1-1": phải bấm qua hai lớp nên dựng riêng
  for (final heSo in heSoCanXem) {
    testWidgets('lich_su_1_kem_1 — chữ x$heSo', (tester) async {
      final tran = <String>[];
      final cu = FlutterError.onError;
      FlutterError.onError = (d) {
        final s = d.exceptionAsString();
        tran.add(s.contains('overflowed') ? s.split('\n').first : 'LỖI KHÁC: ${s.split('\n').first}');
      };
      tester.view.physicalSize = const Size(360 * 2, 1500 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      _dangKyGia();

      await tester.pumpWidget(GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kieuChuApp(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(heSo)),
          child: gioiHanCoChu(context, child!),
        ),
        home: const Scaffold(body: DaoTaoView()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('LỊCH SỬ'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.tap(find.text('Đào tạo 1-1'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      FlutterError.onError = cu;
      // ignore: avoid_print
      print('lich_su_1_kem_1 x$heSo: ${tran.where((t) => !t.startsWith('LỖI')).length} chỗ tràn'
          '${tran.isEmpty ? '' : '\n  - ${tran.toSet().join('\n  - ')}'}');
      expect(find.text('Hướng dẫn gọi điện chăm sóc khách cũ'), findsOneWidget);
      await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/lich_su_1_kem_1_x$heSo.png'));

      // Bấm một báo cáo → hộp xem đủ nội dung và giải thích trạng thái
      await tester.tap(find.text('Hướng dẫn gọi điện chăm sóc khách cũ'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.textContaining('Admin đã duyệt'), findsOneWidget);
      await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/lich_su_1_kem_1_chi_tiet_x$heSo.png'));
    });
  }

  // Lịch sử Thực chiến / Bài đăng: ảnh, nội dung, bấm vào xem chi tiết như Đào tạo 1-1
  final lichSuGui = <(String, Widget Function(), String)>[
    ('lich_su_thuc_chien', () => const Scaffold(body: ThucChienView()), 'Gặp khách · Anh Tuấn'),
    ('lich_su_bai_dang', () => const Scaffold(body: BaiPostView()), 'Bài đăng · Facebook'),
  ];
  for (final (ten, manHinh, mo) in lichSuGui) {
    for (final heSo in heSoCanXem) {
      testWidgets('$ten — chữ x$heSo', (tester) async {
        final tran = <String>[];
        final cu = FlutterError.onError;
        FlutterError.onError = (d) {
          final s = d.exceptionAsString();
          if (s.contains('overflowed')) tran.add(s.split('\n').first);
        };
        tester.view.physicalSize = const Size(360 * 2, 1500 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        _dangKyGia();
        await tester.pumpWidget(GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: kieuChuApp(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(heSo)),
            child: gioiHanCoChu(context, child!),
          ),
          home: manHinh(),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('LỊCH SỬ GỬI'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(find.text(mo), findsOneWidget);
        await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/${ten}_x$heSo.png'));
        await tester.tap(find.text(mo));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        FlutterError.onError = cu;
        // ignore: avoid_print
        print('$ten x$heSo: ${tran.length} chỗ tràn${tran.isEmpty ? '' : '\n  - ${tran.toSet().join('\n  - ')}'}');
        await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('anh/${ten}_chi_tiet_x$heSo.png'));
      });
    }
  }
}
