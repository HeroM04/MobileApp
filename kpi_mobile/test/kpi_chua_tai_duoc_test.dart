import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:kpi_mobile/features/home/controllers/kpi_controller.dart';
import 'package:kpi_mobile/features/home/views/home_view.dart';
import 'package:kpi_mobile/features/shell/controllers/shell_controller.dart';

/// 18/11/2026: máy không kết nối được máy chủ, Trang chủ hiện "0 / 100 điểm —
/// Cần cố gắng thêm" và trợ lý báo "KPI đang ở mức thấp" với người đang có 55
/// điểm. Chưa tải được thì phải nói là chưa tải được.
class _AuthGia extends AuthController {
  _AuthGia() {
    currentUser.value = {'userId': 83, 'role': 'SALE', 'fullName': 'Nguyễn Văn A', 'departmentName': 'Phòng Kinh Doanh 9'};
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
  }

  @override
  Future<void> fetchKpiData() async {}
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (c) async => null);
    Get.put<AuthController>(_AuthGia());
    Get.put<ShellController>(_ShellGia());
  });
  tearDown(Get.reset);

  Future<_KpiGia> dung(WidgetTester tester, void Function(_KpiGia) datTrangThai) async {
    tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final kpi = Get.put<KpiController>(_KpiGia()) as _KpiGia;
    datTrangThai(kpi);
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: HomeView())));
    await tester.pump();
    return kpi;
  }

  testWidgets('chưa tải được lần nào → "—", báo chưa tải được, không hiện 0 hay lời chê', (tester) async {
    await dung(tester, (k) => k.taiLoi.value = true);
    expect(find.textContaining('Chưa tải được điểm KPI'), findsOneWidget);
    expect(find.textContaining('Điểm của bạn không bị mất'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('—'), findsNWidgets(2)); // vòng % của thẻ tuần và thẻ tháng
    expect(find.text('Cần cố gắng thêm'), findsNothing);
    expect(find.text('Trợ Lý Ảo Trí Long AI'), findsNothing);
  });

  testWidgets('đang tải lần đầu → "Đang tải điểm…", chưa có dải báo lỗi', (tester) async {
    await dung(tester, (k) => k.dangTai.value = true);
    expect(find.text('Đang tải điểm…'), findsNWidgets(2));
    expect(find.textContaining('Chưa tải được điểm KPI'), findsNothing);
  });

  testWidgets('đã có điểm → hiện số thật như cũ', (tester) async {
    await dung(tester, (k) {
      k.kpiWeeklyPoints.value = 10;
      k.kpiPoints.value = 55;
      k.daCoSoLieu.value = true;
    });
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('11%'), findsOneWidget); // 55 / 500
    expect(find.text('Trợ Lý Ảo Trí Long AI'), findsOneWidget);
    expect(find.textContaining('Chưa tải được'), findsNothing);
  });

  testWidgets('đã có điểm nhưng lần tải sau hỏng → giữ số cũ + báo chưa cập nhật', (tester) async {
    await dung(tester, (k) {
      k.kpiPoints.value = 55;
      k.daCoSoLieu.value = true;
      k.taiLoi.value = true;
    });
    expect(find.textContaining('Chưa cập nhật được điểm mới'), findsOneWidget);
    expect(find.text('11%'), findsOneWidget);
  });

  test('chỉ tiêu tháng tính trên máy: tháng KPI 11/2026 có 5 thứ Hai → 500', () {
    expect(KpiController.chiTieuThang(DateTime(2026, 11, 18)), 500);
    // 1–4/10/2026 vẫn thuộc tuần bắt đầu thứ Hai 28/9 → KPI tháng 9 (4 thứ Hai)
    expect(KpiController.chiTieuThang(DateTime(2026, 10, 2)), 400);
  });
}
