import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/features/daotao/views/qr_scanner_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Màn quét QR điểm danh khi không mở được camera: trước đây thư viện chỉ hiện
/// màn đen + biểu tượng lỗi, không chữ nào.
void main() {
  Future<void> dung(WidgetTester tester, MobileScannerErrorCode ma) =>
      tester.pumpWidget(GetMaterialApp(home: Scaffold(body: LoiCameraQuetMa(maLoi: ma))));

  testWidgets('chưa cấp quyền camera → hướng dẫn + nút Mở Cài đặt', (tester) async {
    await dung(tester, MobileScannerErrorCode.permissionDenied);
    expect(find.text('Chưa cho phép dùng camera'), findsOneWidget);
    expect(find.textContaining('Cài đặt → Trí Long Land → bật Camera'), findsOneWidget);
    expect(find.text('Mở Cài đặt'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.textContaining('permission'), findsNothing);
  });

  testWidgets('lỗi camera khác → không có nút Cài đặt, nói cách xử lý', (tester) async {
    await dung(tester, MobileScannerErrorCode.genericError);
    expect(find.text('Không mở được camera'), findsOneWidget);
    expect(find.text('Mở Cài đặt'), findsNothing);
    expect(find.textContaining('unexpected'), findsNothing);
  });

  testWidgets('máy không hỗ trợ → nhờ điểm danh tay', (tester) async {
    await dung(tester, MobileScannerErrorCode.unsupported);
    expect(find.textContaining('điểm danh tay'), findsOneWidget);
  });
}
