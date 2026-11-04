import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/moc_khoan_diem.dart';

// Giờ địa phương, không kèm múi — test chạy ở máy nào cũng ra cùng chuỗi
void main() {
  test('hiện lúc ghi, không phải lúc phát sinh', () {
    expect(mocKhoanDiem({'createdAt': '2026-11-04T09:12:00', 'occurredAt': '2026-11-04T08:41:00'}),
        '09:12 · 04/11');
  });

  test('ghi vào ngày khác ngày được tính thì nói rõ ngày được tính', () {
    expect(mocKhoanDiem({'createdAt': '2026-11-04T09:12:00', 'occurredAt': '2026-11-03T08:40:00'}),
        '09:12 · 04/11 · cho ngày 03/11');
  });

  test('thiếu lúc ghi (dữ liệu cũ) thì quay về lúc phát sinh', () {
    expect(mocKhoanDiem({'occurredAt': '2026-11-03T20:26:00'}), '20:26 · 03/11');
    expect(mocKhoanDiem({}), '');
  });
}
