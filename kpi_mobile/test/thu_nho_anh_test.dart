import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpi_mobile/core/utils/thu_nho_anh.dart';

/// Ảnh chấm công thu nhỏ trước khi gửi: đủ nhìn mặt, đọc được dấu giờ + địa
/// chỉ, nhưng không còn nặng vài MB mỗi tấm.
void main() {
  img.Image anh(int rong, int cao) => img.Image(width: rong, height: cao);

  test('ảnh ngang 4000×3000 → 1280×960, giữ tỉ lệ', () {
    final kq = thuNhoAnh(anh(4000, 3000));
    expect(kq.width, 1280);
    expect(kq.height, 960);
  });

  test('ảnh dọc (selfie) 3000×4000 → 960×1280', () {
    final kq = thuNhoAnh(anh(3000, 4000));
    expect(kq.width, 960);
    expect(kq.height, 1280);
  });

  test('ảnh đã nhỏ thì giữ nguyên, không phóng to', () {
    final nho = anh(800, 600);
    expect(identical(thuNhoAnh(nho), nho), isTrue);
    final vuaKhit = anh(960, 1280);
    expect(identical(thuNhoAnh(vuaKhit), vuaKhit), isTrue);
  });

  test('dung lượng JPEG giảm hẳn so với ảnh gốc', () {
    // Ảnh có chi tiết (không phải ảnh trơn) để nén JPEG ra cỡ giống ảnh thật
    final goc = anh(2448, 3264);
    for (final p in goc) {
      p.r = (p.x * 7 + p.y * 3) % 256;
      p.g = (p.x * p.y) % 256;
      p.b = (p.y * 5) % 256;
    }
    final truoc = img.encodeJpg(goc, quality: 85).length;
    final sau = img.encodeJpg(thuNhoAnh(goc), quality: 85).length;
    expect(sau, lessThan(truoc ~/ 3));
  });

  test('dòng địa chỉ đóng dấu không bị cắt trên ảnh dọc đã thu nhỏ', () {
    // Địa chỉ dài cỡ thật, font và lề trái 20 px như _addWatermark
    const diaChi = 'So 12 Duong Trung Van, Quan Nam Tu Liem, Thanh pho Ha Noi';
    final rongChu = diaChi.split('').fold<int>(0, (s, c) => s + img.arial24.characterXAdvance(c));
    final rongAnhDoc = thuNhoAnh(anh(3000, 4000)).width;
    expect(20 + rongChu, lessThanOrEqualTo(rongAnhDoc));
  });
}
