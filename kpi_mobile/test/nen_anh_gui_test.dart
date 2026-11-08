import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpi_mobile/core/utils/thu_nho_anh.dart';

/// Nén ảnh nặng (ảnh chụp màn hình PNG 11 MB) trên điện thoại trước khi gửi.
void main() {
  late Directory thuMuc;

  setUp(() => thuMuc = Directory.systemTemp.createTempSync('nen_anh_'));
  tearDown(() => thuMuc.deleteSync(recursive: true));

  /// Ảnh nhiễu: PNG không nén được, nặng như ảnh chụp màn hình bài đăng nhiều hình.
  img.Image nhieu(int w, int h) {
    final r = math.Random(7);
    final a = img.Image(width: w, height: h);
    for (final p in a) {
      p.setRgb(r.nextInt(256), r.nextInt(256), r.nextInt(256));
    }
    return a;
  }

  File ghi(String ten, List<int> duLieu) => File('${thuMuc.path}/$ten')..writeAsBytesSync(duLieu);

  bool laJpeg(List<int> b) => b.length > 2 && b[0] == 0xFF && b[1] == 0xD8;

  test('ảnh chụp màn hình PNG trên 2 MB → JPEG nhẹ hơn, giữ cỡ', () async {
    final goc = ghi('chup.png', img.encodePng(nhieu(1290, 2796)));
    expect(goc.lengthSync(), greaterThan(nguongNenAnhGui));

    final ra = await nenAnhTruocKhiGui(goc);

    expect(ra.path, isNot(goc.path));
    expect(ra.path.endsWith('_gui.jpg'), isTrue);
    final b = ra.readAsBytesSync();
    expect(laJpeg(b), isTrue);
    expect(b.length, lessThan(goc.lengthSync()));
    final anh = img.decodeJpg(b)!;
    expect(anh.width, 1290);
    expect(anh.height, 2796);
  });

  test('ảnh nhẹ → gửi nguyên file, không nén lại', () async {
    final goc = ghi('nho.png', img.encodePng(nhieu(300, 200)));
    expect(await nenAnhTruocKhiGui(goc), same(goc));
  });

  test('file không đọc được (HEIC...) → gửi nguyên, để máy chủ lo', () async {
    final rac = Uint8List(nguongNenAnhGui + 10);
    for (var i = 0; i < rac.length; i++) {
      rac[i] = (i * 31) & 0xFF;
    }
    final goc = ghi('anh.heic', rac);
    expect((await nenAnhTruocKhiGui(goc)).path, goc.path);
  });

  test('ảnh ngang quá 1920 px → thu về 1920, giữ tỉ lệ', () {
    final anh = img.decodeJpg(nenJpeg(img.encodePng(img.Image(width: 4000, height: 3000)))!)!;
    expect(anh.width, 1920);
    expect(anh.height, 1440);
  });

  test('ảnh chụp cuộn dài → tối đa 8 MP như máy chủ', () {
    final anh = img.decodeJpg(nenJpeg(img.encodePng(img.Image(width: 1080, height: 14000)))!)!;
    expect(anh.width * anh.height, lessThanOrEqualTo(diemAnhToiDaAnhGui + 20000));
    expect(anh.width, greaterThan(700));
  });

  test('PNG trong suốt → nền trắng, không thành nền đen', () {
    final trongSuot = img.Image(width: 200, height: 100, numChannels: 4);
    img.fillRect(trongSuot, x1: 0, y1: 0, x2: 99, y2: 99, color: img.ColorRgba8(255, 0, 0, 255));
    final anh = img.decodeJpg(nenJpeg(img.encodePng(trongSuot))!)!;
    final phai = anh.getPixel(150, 50);
    final trai = anh.getPixel(50, 50);
    expect(phai.r + phai.g + phai.b, greaterThan(740));
    expect(trai.r, greaterThan(230));
    expect(trai.g, lessThan(30));
  });
}
