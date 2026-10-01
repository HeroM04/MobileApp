import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpi_mobile/core/utils/dong_dau_anh.dart';

/// Ảnh đào tạo 1-1 đóng dấu giờ, ngày, địa điểm như ảnh Thực chiến.
///
/// Phần VẼ chữ lên ảnh giống hệt Thực chiến (đã chạy trên máy thật) và không
/// test được ở đây: môi trường test không có card đồ họa, lệnh dựng ảnh của
/// Flutter treo. Test phần mới: ghép địa chỉ, chặn vị trí giả, đổi sang JPEG.
void main() {
  test('ghép địa chỉ bỏ phần trống', () {
    expect(ghepDiaChi(duong: '12 Tố Hữu', quanHuyen: 'Nam Từ Liêm', tinh: 'Hà Nội'), '12 Tố Hữu, Nam Từ Liêm, Hà Nội');
    expect(ghepDiaChi(duong: '', quanHuyen: 'Nam Từ Liêm', tinh: null), 'Nam Từ Liêm');
    expect(ghepDiaChi(), '');
  });

  test('vị trí giả bị từ chối với câu báo như chấm công; vị trí đúng thì không báo gì', () {
    const gia = ViTriChup(TrangThaiViTri.gia);
    expect(gia.dung, isFalse);
    expect(gia.loiChoNguoiDung, contains('Phát hiện phần mềm giả mạo vị trí (Fake GPS)'));
    expect(const ViTriChup(TrangThaiViTri.tatGps).loiChoNguoiDung, contains('bật định vị GPS'));
    expect(const ViTriChup(TrangThaiViTri.khongQuyen).loiChoNguoiDung, contains('quyền vị trí'));
    const dung = ViTriChup(TrangThaiViTri.ok, lat: 20.99, lng: 105.78, diaChi: 'Hà Nội');
    expect(dung.dung, isTrue);
    expect(dung.loiChoNguoiDung, isEmpty);
  });

  test('điểm ảnh RGBA từ Flutter → JPEG đúng kích thước, đúng màu', () {
    const rong = 120, cao = 80;
    final rgba = Uint8List(rong * cao * 4);
    for (var i = 0; i < rong * cao; i++) {
      rgba[i * 4] = 212;      // vàng logo Trí Long (D4AF37)
      rgba[i * 4 + 1] = 175;
      rgba[i * 4 + 2] = 55;
      rgba[i * 4 + 3] = 255;
    }
    final anh = img.decodeJpg(Uint8List.fromList(rgbaSangJpg(rgba.buffer, rong, cao)))!;
    expect(anh.width, rong);
    expect(anh.height, cao);
    final p = anh.getPixel(60, 40);
    // JPEG nén mất mát nhẹ: cho lệch vài đơn vị
    expect((p.r - 212).abs(), lessThan(8));
    expect((p.g - 175).abs(), lessThan(8));
    expect((p.b - 55).abs(), lessThan(8));
  });
}
