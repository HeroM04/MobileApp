// Xem thử bộ lọc làm đẹp ảnh chấm công trên một ảnh thật (chỉ chạy tay).
//
//   ANH_THU=<đường dẫn ảnh> flutter test test_thu_cong/lam_dep_anh_thu_test.dart
//
// Bước 1 (CAT=1): cắt vùng selfie ra test_thu_cong/anh/lam_dep_goc.png để xem toạ độ.
// Bước 2: ghép trước / sau ra test_thu_cong/anh/lam_dep_truoc_sau.png.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpi_mobile/core/utils/lam_dep_anh.dart';

void main() {
  test('xem thử làm đẹp', () {
    final duongDan = Platform.environment['ANH_THU'];
    if (duongDan == null) return;
    final goc = img.decodeImage(File(duongDan).readAsBytesSync())!;
    // Vùng ảnh selfie trong ảnh chụp màn hình (toạ độ theo ảnh gốc)
    final cat = img.copyCrop(goc, x: 40, y: 858, width: 840, height: 408);
    File('test_thu_cong/anh/lam_dep_goc.png').writeAsBytesSync(img.encodePng(cat));
    if (Platform.environment['CAT'] == '1') return;

    final mat = KhuonMat(
      trai: double.parse(Platform.environment['MAT_X']!),
      tren: double.parse(Platform.environment['MAT_Y']!),
      rong: double.parse(Platform.environment['MAT_W']!),
      cao: double.parse(Platform.environment['MAT_H']!),
      vienMoi: _diem(Platform.environment['MOI'] ?? ''),
      trongMieng: _diem(Platform.environment['TRONG'] ?? ''),
    );
    final sw = Stopwatch()..start();
    final dep = lamDepAnh(cat, mat);
    print('Làm đẹp mất ${sw.elapsedMilliseconds} ms trên ${cat.width}x${cat.height}');
    final ghep = img.Image(width: cat.width * 2 + 10, height: cat.height);
    img.fill(ghep, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(ghep, cat);
    img.compositeImage(ghep, dep, dstX: cat.width + 10);
    File('test_thu_cong/anh/lam_dep_truoc_sau.png').writeAsBytesSync(img.encodePng(ghep));
  });
}

List<math.Point<double>> _diem(String s) => [
      for (final cap in s.split(';').where((x) => x.contains(',')))
        math.Point(double.parse(cap.split(',')[0]), double.parse(cap.split(',')[1])),
    ];
