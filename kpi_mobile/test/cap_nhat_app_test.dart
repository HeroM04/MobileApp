import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/cap_nhat_app.dart';

/// Tự cập nhật app: đọc phien-ban.json trên GitHub Releases và quyết định có
/// hỏi người dùng hay không. Hỏi sai là làm phiền cả công ty mỗi lần mở app;
/// không hỏi là nhân viên kẹt ở bản cũ.
void main() {
  const link = 'https://github.com/HeroM04/kpi-trilong-app/releases/download/build-25/kpi-trilong.apk';

  group('đọc phien-ban.json', () {
    test('đủ thông tin', () {
      final b = docBanMoi('{"soBuild": 25, "ten": "1.3.0", "linkApk": "$link", "ghiChu": "Lịch sử theo tháng", "batBuoc": false}');
      expect(b, isNotNull);
      expect(b!.soBuild, 25);
      expect(b.ten, '1.3.0');
      expect(b.linkApk, link);
      expect(b.ghiChu, 'Lịch sử theo tháng');
      expect(b.batBuoc, isFalse);
    });

    test('số build dạng chuỗi và batBuoc "true" (do script shell ghi) vẫn đọc được', () {
      final b = docBanMoi({'soBuild': '30', 'linkApk': link, 'batBuoc': 'true'});
      expect(b!.soBuild, 30);
      expect(b.batBuoc, isTrue);
      expect(b.ten, '');
    });

    test('hỏng, thiếu số build, thiếu link hay link không phải https → bỏ qua', () {
      expect(docBanMoi('không phải json'), isNull);
      expect(docBanMoi({'linkApk': link}), isNull);
      expect(docBanMoi({'soBuild': 25}), isNull);
      expect(docBanMoi({'soBuild': 25, 'linkApk': 'http://example.com/a.apk'}), isNull);
      expect(docBanMoi({'soBuild': 0, 'linkApk': link}), isNull);
      expect(docBanMoi(null), isNull);
    });
  });

  group('có hỏi cập nhật không', () {
    final now = DateTime(2026, 10, 6, 9);
    const ban = BanMoi(soBuild: 25, ten: '1.3.0', linkApk: link);
    const banBatBuoc = BanMoi(soBuild: 25, ten: '1.3.0', linkApk: link, batBuoc: true);

    test('bản mới hơn → hỏi; bằng hoặc cũ hơn → không', () {
      expect(canHoiCapNhat(hienTai: 24, ban: ban, bayGio: now), isTrue);
      expect(canHoiCapNhat(hienTai: 25, ban: ban, bayGio: now), isFalse);
      expect(canHoiCapNhat(hienTai: 26, ban: ban, bayGio: now), isFalse);
    });

    test('build ở máy dev (số build 0) → không bao giờ hỏi', () {
      expect(canHoiCapNhat(hienTai: 0, ban: ban, bayGio: now), isFalse);
    });

    test('vừa bấm "Để sau" bản này → không hỏi lại tới hết hạn hoãn', () {
      final den = now.add(CapNhatApp.hoanSau);
      expect(canHoiCapNhat(hienTai: 24, ban: ban, bayGio: now, hoanBuild: 25, hoanDenLuc: den), isFalse);
      expect(canHoiCapNhat(hienTai: 24, ban: ban, bayGio: den.add(const Duration(minutes: 1)), hoanBuild: 25, hoanDenLuc: den), isTrue);
    });

    test('đã hoãn bản cũ mà nay có bản mới hơn nữa → hỏi ngay', () {
      const banSau = BanMoi(soBuild: 26, ten: '1.3.1', linkApk: link);
      expect(canHoiCapNhat(hienTai: 24, ban: banSau, bayGio: now, hoanBuild: 25, hoanDenLuc: now.add(CapNhatApp.hoanSau)), isTrue);
    });

    test('bản bắt buộc → hỏi dù đã hoãn', () {
      expect(canHoiCapNhat(hienTai: 24, ban: banBatBuoc, bayGio: now, hoanBuild: 25, hoanDenLuc: now.add(CapNhatApp.hoanSau)), isTrue);
    });
  });
}
