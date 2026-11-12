import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/shared/widgets/the_lich_su.dart';

/// Admin "Chỉ tính công" lượt chấm công vào (12/11/2026): Lịch sử hiện dòng cam
/// kèm lý do, bấm vào xem chi tiết.
void main() {
  test('nhãn theo chế độ; lượt tính điểm bình thường thì không có', () {
    expect(chiTinhCongCua({'chiTinhCong': 'KHONG_DIEM'}), contains('không cộng điểm đúng giờ'));
    expect(chiTinhCongCua({'chiTinhCong': 'DI_MUON'}), contains('tính là đi muộn'));
    expect(chiTinhCongCua({'chiTinhCong': null}), isNull);
    expect(chiTinhCongCua({}), isNull);
  });

  testWidgets('dòng cam có lý do; bấm mở hộp xem đủ lý do', (tester) async {
    final item = {
      'chiTinhCong': 'DI_MUON',
      'chiTinhCongLyDo': 'Chấm công ở cửa lúc 08:45, lên tới công ty đã muộn',
    };
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (_) => InkWell(
            onTap: () => xemChiTinhCong(tieuDe: 'Chấm công vào', thongTin: const [MapEntry('Lúc', '08:45')], item: item),
            child: DongChiTinhCong(item),
          ),
        ),
      ),
    ));
    expect(find.text('Admin chỉ tính công — tính là đi muộn: Chấm công ở cửa lúc 08:45, lên tới công ty đã muộn'),
        findsOneWidget);

    await tester.tap(find.byType(DongChiTinhCong));
    await tester.pumpAndSettle();
    expect(find.text('ADMIN CHỈ TÍNH CÔNG'), findsOneWidget);
    expect(find.textContaining('Lý do: Chấm công ở cửa'), findsOneWidget);
  });

  testWidgets('lượt bình thường: không vẽ gì', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DongChiTinhCong({'status': 'APPROVED'}))));
    expect(find.byType(Text), findsNothing);
  });
}
