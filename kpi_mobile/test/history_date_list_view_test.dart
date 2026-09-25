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
