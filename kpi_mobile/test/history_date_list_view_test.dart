import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/dong_bo.dart';
import 'package:kpi_mobile/shared/widgets/history_date_list_view.dart';

/// Danh sách lịch sử dùng chung cho chấm công, bài đăng, thực chiến, chốt căn,
/// đào tạo, phản hồi. Đây là nơi nhân sự nhìn thấy kết quả Admin duyệt trên web.
void main() {
  setUp(DongBo.datLai);

  Future<List<String>> dungManHinh(WidgetTester tester, {required String trangThai, String? loai}) async {
    final ngayDaHoi = <String>[];
    var trangThaiHienTai = trangThai;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          return HistoryDateListView(
            loaiDongBo: loai,
            onFetchHistory: (ngay) async {
              ngayDaHoi.add(ngay);
              return [
                {'ten': 'Bài đăng Vista', 'status': trangThaiHienTai},
              ];
            },
            itemBuilder: (item, i) => Text('${item['ten']} — ${statusLabel(item['status'])}'),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    // Cho test đổi dữ liệu "trên máy chủ" rồi báo đồng bộ
    _doiTrangThai = (moi) => trangThaiHienTai = moi;
    return ngayDaHoi;
  }

  testWidgets('Admin duyệt trên web → máy chủ báo → danh sách tự hiện "Đã duyệt"', (tester) async {
    final daHoi = await dungManHinh(tester, trangThai: 'PENDING', loai: DongBo.baiDang);
    expect(find.text('Bài đăng Vista — Đang chờ'), findsOneWidget);

    _doiTrangThai('APPROVED');            // Admin bấm Duyệt trên web
    DongBo.bao(DongBo.baiDang);           // máy chủ nhắn qua WebSocket
    await tester.pump(DongBo.gom + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Bài đăng Vista — Đã duyệt'), findsOneWidget);
    expect(daHoi.length, 2);
    expect(daHoi.last, daHoi.first, reason: 'tải lại đúng ngày đang xem');
  });

  testWidgets('tin của loại khác không làm danh sách này tải lại', (tester) async {
    final daHoi = await dungManHinh(tester, trangThai: 'PENDING', loai: DongBo.baiDang);

    DongBo.bao(DongBo.chamCong);
    await tester.pump(DongBo.gom + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(daHoi.length, 1);
  });

  testWidgets('không khai loại đồng bộ thì giữ nguyên cách cũ (chỉ tải khi mở)', (tester) async {
    final daHoi = await dungManHinh(tester, trangThai: 'PENDING');

    DongBo.baoTatCa();
    await tester.pump(DongBo.gom + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(daHoi.length, 1);
  });

  testWidgets('đóng màn hình rồi thì tin tới sau không làm gì (không lỗi setState)', (tester) async {
    final daHoi = await dungManHinh(tester, trangThai: 'PENDING', loai: DongBo.baiDang);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    DongBo.bao(DongBo.baiDang);
    await tester.pump(DongBo.gom + const Duration(milliseconds: 50));

    expect(daHoi.length, 1);
    expect(tester.takeException(), isNull);
  });

  group('xem theo tháng (lịch sử chấm công)', () {
    String iso(int ngay, int gio) => DateTime(2026, 10, ngay, gio).toIso8601String();

    test('gom theo ngày: ngày mới nhất trước, trong ngày sớm → muộn, bỏ mục không có giờ', () {
      final nhom = nhomTheoNgay([
        {'id': 1, 't': iso(2, 8)},
        {'id': 2, 't': iso(5, 17)},
        {'id': 3, 't': iso(5, 8)},
        {'id': 4, 't': null},
      ], (m) => m['t'] as String?);

      expect(nhom.map((e) => e.key), [DateTime(2026, 10, 5), DateTime(2026, 10, 2)]);
      expect(nhom.first.value.map((m) => m['id']), [3, 2]);
      expect(nhom.last.value.map((m) => m['id']), [1]);
    });

    test('tiêu đề ngày tiếng Việt', () {
      expect(tenNgay(DateTime(2026, 10, 5)), 'Thứ Hai, 05/10');
      expect(tenNgay(DateTime(2026, 10, 4)), 'Chủ nhật, 04/10');
    });

    testWidgets('bấm "Theo tháng" → tải cả tháng, hiện tiêu đề từng ngày và từng lượt', (tester) async {
      final thangDaHoi = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HistoryDateListView(
            onFetchHistory: (ngay) async => [],
            onFetchMonth: (thang) async {
              thangDaHoi.add(thang);
              return [
                {'loai': 'Check-in', 't': iso(5, 8)},
                {'loai': 'Check-out', 't': iso(5, 17)},
                {'loai': 'Check-in', 't': iso(2, 8)},
              ];
            },
            thoiDiemCua: (m) => m['t'] as String?,
            itemBuilder: (item, i) => Text('${item['loai']} ${DateTime.parse(item['t']).day}'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(thangDaHoi, isEmpty, reason: 'mặc định vẫn xem theo ngày');

      await tester.tap(find.text('Theo tháng'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(thangDaHoi, ['${now.year}-${now.month.toString().padLeft(2, '0')}']);
      expect(find.text('Thứ Hai, 05/10'), findsOneWidget);
      expect(find.text('Thứ Sáu, 02/10'), findsOneWidget);
      expect(find.text('Check-in 5'), findsOneWidget);
      expect(find.text('Check-out 5'), findsOneWidget);
      expect(find.text('2 ngày · 3 lượt'), findsOneWidget);
    });

    testWidgets('không truyền onFetchMonth thì không có nút chuyển (các tab khác giữ nguyên)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HistoryDateListView(onFetchHistory: (_) async => [], itemBuilder: (_, _) => const SizedBox()),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Theo tháng'), findsNothing);
    });
  });

  group('nhãn và định dạng', () {
    test('trạng thái hiện tiếng Việt, không lộ mã', () {
      expect(statusLabel('APPROVED'), 'Đã duyệt');
      expect(statusLabel('pending'), 'Đang chờ');
      expect(statusLabel('REJECTED'), 'Từ chối');
      expect(statusLabel(null), 'Không rõ');
    });

    test('ngày giờ ISO → dd/MM/yyyy HH:mm theo giờ máy', () {
      final dt = DateTime(2026, 9, 23, 8, 5);
      expect(formatIsoDate(dt.toIso8601String()), '23/09/2026 08:05');
      expect(formatIsoDate(null), 'Không rõ');
      expect(formatIsoDate('không phải ngày'), 'không phải ngày');
    });
  });
}

late void Function(String) _doiTrangThai;
