import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kpi_mobile/features/baipost/views/bai_post_view.dart';
import 'package:kpi_mobile/shared/widgets/history_date_list_view.dart';
import 'package:kpi_mobile/shared/widgets/the_lich_su.dart';

/// Bài đăng chọn Zalo / Facebook / TikTok; Lịch sử lọc yêu cầu bị từ chối và
/// hiện lý do Admin ghi (08/11/2026).
void main() {
  group('Link bài đăng theo nền tảng', () {
    test('Facebook, TikTok bắt buộc link; Zalo để trống được', () {
      expect(kiemTraLink('FACEBOOK', ''), contains('Facebook'));
      expect(kiemTraLink('TIKTOK', '   '), contains('TikTok'));
      expect(kiemTraLink('ZALO', ''), isNull);
    });

    test('có dán thì phải là link http', () {
      expect(kiemTraLink('ZALO', 'zalo.me/abc'), isNotNull);
      expect(kiemTraLink('TIKTOK', 'https://www.tiktok.com/@a/video/1'), isNull);
      expect(kiemTraLink('FACEBOOK', 'HTTPS://FB.COM/x'), isNull);
    });

    test('tên hiển thị của mã nền tảng; bài đời cũ OTHER là "Khác"', () {
      expect(tenNenTang('FACEBOOK'), 'Facebook');
      expect(tenNenTang('TIKTOK'), 'TikTok');
      expect(tenNenTang('ZALO'), 'Zalo');
      expect(tenNenTang('OTHER'), 'Khác');
      expect(tenNenTang(null), 'Khác');
    });
  });

  group('Lý do từ chối', () {
    test('đọc rejectReason, đơn đời cũ đọc reviewNote; chỉ khi bị từ chối', () {
      expect(lyDoTuChoiCua({'status': 'REJECTED', 'rejectReason': ' Ảnh mờ '}), 'Ảnh mờ');
      expect(lyDoTuChoiCua({'status': 'REJECTED', 'reviewNote': 'Sai ngày'}), 'Sai ngày');
      expect(lyDoTuChoiCua({'status': 'APPROVED', 'reviewNote': 'Ok'}), isNull);
      expect(lyDoTuChoiCua({'status': 'REJECTED'}), isNull);
    });
  });

  testWidgets('Lịch sử: bấm "Bị từ chối" chỉ còn mục bị từ chối, thấy lý do', (tester) async {
    final hom = DateTime.now().toIso8601String();
    final ds = [
      {'id': 1, 'status': 'APPROVED', 'tieuDe': 'Bài A', 'submittedAt': hom},
      {'id': 2, 'status': 'REJECTED', 'tieuDe': 'Bài B', 'submittedAt': hom, 'rejectReason': 'Ảnh không thấy tên dự án'},
      {'id': 3, 'status': 'PENDING', 'tieuDe': 'Bài C', 'submittedAt': hom},
    ];
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: HistoryDateListView(
          locTuChoi: true,
          onFetchHistory: (_) async => ds,
          onFetchMonth: (_) async => ds,
          thoiDiemCua: (i) => i['submittedAt']?.toString(),
          itemBuilder: (item, _) => TheLichSu(
            anh: null,
            bieuTuong: Icons.article,
            tieuDe: item['tieuDe'].toString(),
            submittedAt: item['submittedAt'],
            trangThai: item['status'].toString(),
            lyDoTuChoi: lyDoTuChoiCua(item),
            onTap: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Bài A'), findsOneWidget);
    expect(find.text('Bài C'), findsOneWidget);
    expect(find.text('Bị từ chối (1)'), findsOneWidget);

    await tester.tap(find.text('Bị từ chối (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Bài A'), findsNothing);
    expect(find.text('Bài C'), findsNothing);
    expect(find.text('Bài B'), findsOneWidget);
    expect(find.text('Lý do từ chối: Ảnh không thấy tên dự án'), findsOneWidget);
    expect(find.textContaining('bị từ chối'), findsWidgets); // đầu tháng: "1 bị từ chối"
  });
}
