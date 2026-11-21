import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpi_mobile/core/utils/lam_dep_anh.dart';

/// Ảnh chấm công: lật selfie cho giống lúc soi camera, làm đẹp nhẹ vùng mặt.
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
    test('Android → không lật (máy đã lưu đúng như lúc soi)', () {
      expect(nenLatAnhSelfie(laIOS: false, ongKinh: 'front'), isFalse);
      expect(nenLatAnhSelfie(laIOS: false, ongKinh: null), isFalse);
    });
  });

  group('khuôn mặt theo ảnh', () {
    const mat = KhuonMat(trai: 100, tren: 50, rong: 200, cao: 240,
        vienMoi: [math.Point(180, 250), math.Point(220, 250), math.Point(200, 260)]);

    test('thu nhỏ ảnh → khung mặt và viền môi thu theo', () {
      final k = mat.theoTiLe(0.5);
      expect([k.trai, k.tren, k.rong, k.cao], [50, 25, 100, 120]);
      expect(k.vienMoi.first, const math.Point(90.0, 125.0));
    });

    test('lật ngang ảnh rộng 600 → mặt sang phía đối xứng', () {
      final l = mat.latNgang(600);
      expect(l.trai, 300);   // 600 - 100 - 200
      expect(l.vienMoi.first, const math.Point(420.0, 250.0));
    });
  });

  group('làm đẹp', () {
    // Ảnh 200x200: nền xanh dương, giữa là "mặt" màu da có lấm tấm (khuyết điểm),
    // một vệt lông mày tối, đôi môi màu hồng nhạt, khe miệng trắng (răng).
    const da = [205, 160, 135];
    img.Image taoAnh() {
      final a = img.Image(width: 200, height: 200);
      final rnd = math.Random(7);
      for (var y = 0; y < 200; y++) {
        for (var x = 0; x < 200; x++) {
          final trongMat = math.pow((x - 100) / 60, 2) + math.pow((y - 100) / 75, 2) <= 1;
          if (!trongMat) {
            a.setPixelRgb(x, y, 40, 80, 200);
            continue;
          }
          final n = rnd.nextInt(17) - 8;            // lỗ chân lông
          final dom = (x - 80) * (x - 80) + (y - 90) * (y - 90) < 9 ? -18 : 0;   // nốt thâm
          a.setPixelRgb(x, y, da[0] + n + dom, da[1] + n + dom, da[2] + n + dom);
        }
      }
      for (var x = 70; x < 95; x++) {
        for (var y = 68; y < 71; y++) {
          a.setPixelRgb(x, y, 45, 35, 30);           // lông mày
        }
      }
      for (var y = 140; y < 156; y++) {
        for (var x = 82; x < 118; x++) {
          a.setPixelRgb(x, y, 190, 120, 115);        // môi
        }
      }
      for (var x = 90; x < 110; x++) {
        a.setPixelRgb(x, 147, 240, 240, 235);        // răng
        a.setPixelRgb(x, 148, 240, 240, 235);
      }
      return a;
    }

    const mat = KhuonMat(
      trai: 40, tren: 25, rong: 120, cao: 150,
      vienMoi: [math.Point(82, 140), math.Point(100, 138), math.Point(118, 140),
                math.Point(118, 156), math.Point(100, 158), math.Point(82, 156)],
      trongMieng: [math.Point(88, 146), math.Point(112, 146), math.Point(112, 149), math.Point(88, 149)],
    );

    double doSang(img.Pixel p) => 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

    double doLechVung(img.Image a, int x0, int y0, int w, int h) {
      final ds = [for (var y = y0; y < y0 + h; y++) for (var x = x0; x < x0 + w; x++) doSang(a.getPixel(x, y))];
      final tb = ds.reduce((a, b) => a + b) / ds.length;
      return math.sqrt(ds.map((v) => (v - tb) * (v - tb)).reduce((a, b) => a + b) / ds.length);
    }

    test('da mịn hơn: lấm tấm trên má giảm rõ', () {
      final goc = taoAnh();
      final dep = lamDepAnh(goc, mat);
      expect(doLechVung(dep, 110, 95, 30, 30), lessThan(doLechVung(goc, 110, 95, 30, 30) * 0.6));
    });

    test('che nốt thâm: nốt mờ đi so với da xung quanh', () {
      final goc = taoAnh();
      final dep = lamDepAnh(goc, mat);
      double tuongPhan(img.Image a) => doSang(a.getPixel(80, 98)) - doSang(a.getPixel(80, 90));
      expect(tuongPhan(dep).abs(), lessThan(tuongPhan(goc).abs()));
    });

    test('da sáng hơn', () {
      final goc = taoAnh();
      final dep = lamDepAnh(goc, mat);
      expect(doSang(dep.getPixel(120, 110)), greaterThan(doSang(goc.getPixel(120, 110)) + 5));
    });

    test('lông mày (đường nét tối) vẫn giữ — không bị nhoè vào da', () {
      final goc = taoAnh();
      final dep = lamDepAnh(goc, mat);
      expect(doSang(dep.getPixel(82, 69)), lessThan(80));
    });

    test('môi hồng hơn (đỏ tăng, xanh lá giảm), răng không bị tô hồng', () {
      final goc = taoAnh();
      final dep = lamDepAnh(goc, mat);
      final m0 = goc.getPixel(100, 153), m1 = dep.getPixel(100, 153);
      expect(m1.r - m1.g, greaterThan(m0.r - m0.g + 10));
      final r1 = dep.getPixel(100, 147);
      expect((r1.r - r1.g).abs(), lessThan(12));
    });

    test('ngoài khuôn mặt (nền) chỉ sáng nhẹ, không đổi màu', () {
      final goc = taoAnh();
      final dep = lamDepAnh(goc, mat);
      final a = goc.getPixel(5, 5), b = dep.getPixel(5, 5);
      expect(b.b, greaterThanOrEqualTo(a.b));
      expect((b.b - a.b).abs(), lessThan(12));
      expect((b.r - a.r).abs(), lessThan(12));
    });

    test('không có khuôn mặt → chỉ sáng nhẹ cả ảnh; mức 0 → giữ nguyên', () {
      final goc = taoAnh();
      final khongMat = lamDepAnh(goc, null);
      expect(doLechVung(khongMat, 110, 95, 30, 30), closeTo(doLechVung(goc, 110, 95, 30, 30), 2));
      final khongLam = lamDepAnh(goc, mat, muc: 0);
      expect(khongLam.getPixel(120, 110).r, goc.getPixel(120, 110).r);
    });

    test('không sửa ảnh gốc truyền vào', () {
      final goc = taoAnh();
      final truoc = goc.getPixel(120, 110).r;
      lamDepAnh(goc, mat);
      expect(goc.getPixel(120, 110).r, truoc);
    });
  });
}
