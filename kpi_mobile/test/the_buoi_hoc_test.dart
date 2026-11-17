import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/features/daotao/views/the_buoi_hoc.dart';

/// Lịch sử → Buổi học: hiện đúng tên buổi và trạng thái ghi chú vắng.
void main() {
  group('tên buổi', () {
    test('máy chủ mới gửi sessionTitle', () {
      expect(tenBuoiHoc({'sessionTitle': 'Kỹ năng chốt sale'}), 'Kỹ năng chốt sale');
    });
    test('bản cũ lồng trong session', () {
      expect(tenBuoiHoc({'session': {'title': 'Telesales cơ bản'}}), 'Telesales cơ bản');
    });
    test('không có tên (buổi đã xoá, máy chủ cũ) thì ghi chung', () {
      expect(tenBuoiHoc({}), 'Buổi đào tạo');
      expect(tenBuoiHoc({'sessionTitle': '  '}), 'Buổi đào tạo');
    });
  });

  test('xếp ngày: lúc điểm danh, chưa được tính thì theo ngày buổi học', () {
    expect(thoiDiemBuoiHoc({'attendedAt': '2026-11-04T03:51:00Z', 'sessionStartTime': '2026-11-04T03:00:00Z'}),
        '2026-11-04T03:51:00Z');
    expect(thoiDiemBuoiHoc({'attendedAt': null, 'sessionStartTime': '2026-11-17T02:00:00Z'}), '2026-11-17T02:00:00Z');
  });

  group('trạng thái', () {
    test('có mặt thật', () {
      final t = trangThaiBuoiHoc({'source': 'REAL', 'attendedAt': '2026-11-04T03:51:00Z'});
      expect(t.daTinh, isTrue);
      expect(t.chu, startsWith('Có mặt lúc 04/11/2026'));
    });
    test('máy chủ cũ không gửi source thì coi như có mặt', () {
      expect(trangThaiBuoiHoc({'attendedAt': '2026-11-04T03:51:00Z'}).chu, startsWith('Có mặt'));
    });
    test('được miễn nhờ ghi chú đã duyệt', () {
      final t = trangThaiBuoiHoc({'source': 'EXEMPT', 'noteStatus': 'APPROVED'});
      expect(t.daTinh, isTrue);
      expect(t.chu, contains('ghi chú đã được duyệt'));
    });
    test('tự tính theo nhóm kỹ năng', () {
      expect(trangThaiBuoiHoc({'source': 'SKILL_GROUP'}).daTinh, isTrue);
    });
    test('ghi chú chờ duyệt / bị từ chối: chưa được tính', () {
      final cho = trangThaiBuoiHoc({'source': 'NOTE', 'noteStatus': 'PENDING'});
      expect(cho.daTinh, isFalse);
      expect(cho.chu, 'Ghi chú đang chờ Admin duyệt');
      final tuChoi = trangThaiBuoiHoc({'source': 'NOTE', 'noteStatus': 'REJECTED'});
      expect(tuChoi.daTinh, isFalse);
      expect(tuChoi.chu, contains('bị từ chối'));
    });
  });
}
