import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/lat_anh_selfie.dart';

/// Ảnh chấm công: lật selfie iPhone cho giống lúc soi camera.
void main() {
  group('lật ảnh selfie', () {
    test('iPhone camera trước → lật (iPhone lưu ảnh ngược so với lúc soi)', () {
      expect(nenLatAnhSelfie(laIOS: true, ongKinh: 'iPhone 13 front camera 2.71mm f/2.2'), isTrue);
    });
    test('iPhone camera sau → không lật', () {
      expect(nenLatAnhSelfie(laIOS: true, ongKinh: 'iPhone 13 back dual wide camera 5.1mm f/1.6'), isFalse);
    });
    test('iPhone không đọc được ống kính → coi là camera trước (màn chấm công mở camera trước)', () {
      expect(nenLatAnhSelfie(laIOS: true, ongKinh: null), isTrue);
      expect(nenLatAnhSelfie(laIOS: true, ongKinh: ''), isTrue);
    });
    test('iPhone camera trước, thẻ xoay thường (6) → lật', () {
      expect(nenLatAnhSelfie(laIOS: true, ongKinh: 'iPhone 13 front camera 2.71mm f/2.2', huongExif: 6), isTrue);
    });
    test('iPhone đã lưu ảnh kiểu gương (thẻ 2/4/5/7) → không lật thêm, kẻo ngược lại', () {
      for (final h in [2, 4, 5, 7]) {
        expect(nenLatAnhSelfie(laIOS: true, ongKinh: 'iPhone 13 front camera 2.71mm f/2.2', huongExif: h), isFalse,
            reason: 'thẻ $h');
      }
    });
    test('Android → không lật (máy đã lưu đúng như lúc soi)', () {
      expect(nenLatAnhSelfie(laIOS: false, ongKinh: 'front'), isFalse);
      expect(nenLatAnhSelfie(laIOS: false, ongKinh: null), isFalse);
    });
  });
}
