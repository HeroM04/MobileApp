import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Khuôn mặt trong ảnh (toạ độ điểm ảnh của chính ảnh đang xử lý).
///
/// Lấy từ ML Kit lúc kiểm tra ảnh chấm công có mặt người. Tách khỏi kiểu của
/// ML Kit để phần làm đẹp chạy được trong test và trong isolate.
class KhuonMat {
  final double trai, tren, rong, cao;

  /// Các điểm viền NGOÀI của môi (viền trên môi trên + viền dưới môi dưới).
  /// Rỗng = không tô môi.
  final List<math.Point<double>> vienMoi;

  /// Các điểm viền TRONG của môi (khe miệng). Có thì không tô vào răng khi cười.
  final List<math.Point<double>> trongMieng;

  const KhuonMat({
    required this.trai,
    required this.tren,
    required this.rong,
    required this.cao,
    this.vienMoi = const [],
    this.trongMieng = const [],
  });

  /// Cùng khuôn mặt sau khi ảnh bị thu nhỏ / phóng to [k] lần.
  KhuonMat theoTiLe(double k) => KhuonMat(
        trai: trai * k,
        tren: tren * k,
        rong: rong * k,
        cao: cao * k,
        vienMoi: [for (final p in vienMoi) math.Point(p.x * k, p.y * k)],
        trongMieng: [for (final p in trongMieng) math.Point(p.x * k, p.y * k)],
      );

  /// Cùng khuôn mặt sau khi ảnh rộng [rongAnh] bị lật ngang.
  KhuonMat latNgang(int rongAnh) => KhuonMat(
        trai: rongAnh - trai - rong,
        tren: tren,
        rong: rong,
        cao: cao,
        vienMoi: [for (final p in vienMoi) math.Point(rongAnh - p.x, p.y)],
        trongMieng: [for (final p in trongMieng) math.Point(rongAnh - p.x, p.y)],
      );
}

/// Ảnh selfie chấm công có cần lật ngang cho giống lúc soi camera không.
///
/// Lúc chụp, camera trước hiện hình như soi gương; iPhone lại LƯU ảnh không lật,
/// nên chụp xong thấy hình "bị lật ngược" so với lúc nhìn. Android: phần lớn
/// máy đã lưu đúng như lúc soi (Samsung, Pixel mặc định "lưu selfie như xem
/// trước") nên không lật thêm — lật nữa là ngược lại.
///
/// iPhone ghi ống kính vào EXIF ("iPhone 13 front camera 2.71mm f/2.2"); ống
/// kính sau thì không lật. Không đọc được EXIF thì coi như camera trước — màn
/// chấm công mở thẳng camera trước.
bool nenLatAnhSelfie({required bool laIOS, String? ongKinh}) {
  if (!laIOS) return false;
  final ok = (ongKinh ?? '').toLowerCase();
  if (ok.isEmpty) return true;
  return ok.contains('front');
}

/// Làm đẹp ảnh chấm công: da mịn, trắng sáng, che khuyết điểm nhỏ, môi hồng.
///
/// Làm NHẸ và chỉ trong vùng khuôn mặt — đây vẫn là ảnh xác thực chấm công:
/// Admin cần nhận ra người, máy chủ còn so ảnh với ảnh đại diện. Không có
/// khuôn mặt thì chỉ sáng nhẹ cả ảnh.
///
/// - Mịn da / che khuyết điểm: trộn với bản làm mờ, chỉ ở điểm ảnh màu da và ở
///   chỗ chênh lệch nhỏ (lỗ chân lông, mụn, vết thâm). Chỗ chênh lớn — mắt, lông
///   mày, viền mặt — giữ nguyên nên ảnh không bị nhoè.
/// - Trắng sáng: nâng độ sáng phần da, ngả hồng rất nhẹ.
/// - Môi hồng: tô hồng trong viền môi ML Kit trả về, mép môi làm mềm, không tô
///   vào răng.
///
/// [muc]: 0 = không làm gì, 1 = mức mặc định.
img.Image lamDepAnh(img.Image goc, KhuonMat? mat, {double muc = 1.0}) {
  final anh = goc.clone();
  if (muc <= 0) return anh;
  if (mat != null && mat.rong > 8 && mat.cao > 8) _lamDepVungMat(anh, mat, muc);
  _sangNhe(anh, muc);
  return anh;
}

double _kep01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// 0 khi v ≤ a, 1 khi v ≥ b, chuyển mượt ở giữa.
double _bacThang(double a, double b, double v) {
  final t = _kep01((v - a) / (b - a));
  return t * t * (3 - 2 * t);
}

/// Mức "thuộc khoảng [lo, hi]" mềm ở hai đầu (rộng [mem]).
double _trongKhoang(double v, double lo, double hi, double mem) {
  if (v < lo) return _kep01(1 - (lo - v) / mem);
  if (v > hi) return _kep01(1 - (v - hi) / mem);
  return 1;
}

double _doSang(num r, num g, num b) => 0.299 * r + 0.587 * g + 0.114 * b;

/// Khả năng điểm ảnh là da người (theo YCbCr — đúng cho cả da sáng lẫn ngăm).
double _laDa(double r, double g, double b) {
  final y = _doSang(r, g, b);
  final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
  final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
  final mau = _trongKhoang(cb, 77, 127, 8) * _trongKhoang(cr, 133, 173, 8);
  return mau * _kep01((y - 35) / 30); // vùng quá tối (tóc, bóng) không phải da
}

void _lamDepVungMat(img.Image anh, KhuonMat mat, double muc) {
  final cx = mat.trai + mat.rong / 2;
  final cy = mat.tren + mat.cao / 2;
  // Elip phủ hết mặt, trán và cằm; ra tới mép elip thì nhạt dần để không lộ viền
  final rx = mat.rong * 0.68;
  final ry = mat.cao * 0.75;
  final x0 = math.max(0, (cx - rx).floor());
  final y0 = math.max(0, (cy - ry).floor());
  final x1 = math.min(anh.width, (cx + rx).ceil());
  final y1 = math.min(anh.height, (cy + ry).ceil());
  if (x1 - x0 < 4 || y1 - y0 < 4) return;

  final mo = img.gaussianBlur(
    img.copyCrop(anh, x: x0, y: y0, width: x1 - x0, height: y1 - y0),
    radius: (mat.rong / 46).round().clamp(2, 12),
  );
  final moi = _MatNaMoi.tao(mat, mem: math.max(2.0, mat.rong / 90));

  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final dx = (x - cx) / rx, dy = (y - cy) / ry;
      final f = 1 - _bacThang(0.72, 1.0, math.sqrt(dx * dx + dy * dy));
      if (f <= 0) continue;

      final p = anh.getPixel(x, y);
      var r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final da = _laDa(r, g, b) * f;

      if (da > 0.01) {
        // Mịn da, che khuyết điểm nhỏ: chỉ trộn ở chỗ chênh lệch nhỏ
        final q = mo.getPixel(x - x0, y - y0);
        final chenh = (_doSang(r, g, b) - _doSang(q.r, q.g, q.b)).abs();
        final a = 0.62 * muc * da * (1 - _bacThang(8, 36, chenh));
        r += (q.r - r) * a;
        g += (q.g - g) * a;
        b += (q.b - b) * a;

        // Trắng sáng, ngả hồng rất nhẹ
        final w = 0.26 * muc * da;
        r += (255 - r) * 0.16 * w + 4 * w;
        g += (255 - g) * 0.13 * w;
        b += (255 - b) * 0.13 * w + 1 * w;
      }

      final m = moi.muc(x, y) * 0.5 * muc;
      if (m > 0.005) {
        // Môi hồng: thêm đỏ, bớt xanh lá, chút xanh dương cho ra hồng chứ không cam
        r += (255 - r) * 0.30 * m;
        g -= g * 0.20 * m;
        b += (205 - b) * 0.10 * m;
      }

      anh.setPixelRgba(x, y, r.round().clamp(0, 255), g.round().clamp(0, 255),
          b.round().clamp(0, 255), p.a);
    }
  }
}

/// Sáng nhẹ cả ảnh (nâng vùng tối-trung bình, giữ vùng sáng không bị cháy).
void _sangNhe(img.Image anh, double muc) {
  final bang = List<int>.generate(256, (v) {
    final t = v / 255.0;
    final len = math.pow(t, 1 - 0.07 * muc).toDouble();
    return (len * 255).round().clamp(0, 255);
  });
  for (final p in anh) {
    p
      ..r = bang[p.r.toInt().clamp(0, 255)]
      ..g = bang[p.g.toInt().clamp(0, 255)]
      ..b = bang[p.b.toInt().clamp(0, 255)];
  }
}

/// Mặt nạ vùng môi, mép mềm, trừ khe miệng.
class _MatNaMoi {
  final List<math.Point<double>> ngoai;
  final List<math.Point<double>> trong;
  final double mem;
  final double x0, y0, x1, y1;

  _MatNaMoi(this.ngoai, this.trong, this.mem, this.x0, this.y0, this.x1, this.y1);

  static _MatNaMoi tao(KhuonMat mat, {required double mem}) {
    final ngoai = _sapTheoGoc(mat.vienMoi);
    if (ngoai.length < 3) return _MatNaMoi(const [], const [], mem, 0, 0, -1, -1);
    final xs = ngoai.map((p) => p.x), ys = ngoai.map((p) => p.y);
    return _MatNaMoi(
      ngoai,
      _sapTheoGoc(mat.trongMieng),
      mem,
      xs.reduce(math.min) - mem,
      ys.reduce(math.min) - mem,
      xs.reduce(math.max) + mem,
      ys.reduce(math.max) + mem,
    );
  }

  /// Xếp các điểm theo góc quanh tâm → ra đa giác đúng thứ tự dù ML Kit trả
  /// môi trên, môi dưới theo hai chiều khác nhau.
  static List<math.Point<double>> _sapTheoGoc(List<math.Point<double>> ds) {
    if (ds.length < 3) return const [];
    final tx = ds.map((p) => p.x).reduce((a, b) => a + b) / ds.length;
    final ty = ds.map((p) => p.y).reduce((a, b) => a + b) / ds.length;
    return [...ds]..sort((a, b) => math.atan2(a.y - ty, a.x - tx).compareTo(math.atan2(b.y - ty, b.x - tx)));
  }

  /// 0..1 — 1 là giữa môi, mờ dần ra mép trong khoảng [mem] điểm ảnh.
  double muc(int x, int y) {
    if (x < x0 || x > x1 || y < y0 || y > y1) return 0;
    final px = x + 0.5, py = y + 0.5;
    final ngoaiMuc = _kep01(0.5 + _khoangCachCoDau(ngoai, px, py) / (2 * mem));
    if (ngoaiMuc <= 0) return 0;
    if (trong.length < 3) return ngoaiMuc;
    final trongMuc = _kep01(0.5 + _khoangCachCoDau(trong, px, py) / (2 * mem));
    return ngoaiMuc * (1 - trongMuc);
  }

  /// Khoảng cách tới viền đa giác: dương nếu ở trong, âm nếu ở ngoài.
  static double _khoangCachCoDau(List<math.Point<double>> dg, double x, double y) {
    var trongDg = false;
    var gan = double.infinity;
    for (var i = 0, j = dg.length - 1; i < dg.length; j = i++) {
      final a = dg[i], b = dg[j];
      if ((a.y > y) != (b.y > y) && x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
        trongDg = !trongDg;
      }
      final vx = b.x - a.x, vy = b.y - a.y;
      final dd = vx * vx + vy * vy;
      final t = dd == 0 ? 0.0 : _kep01(((x - a.x) * vx + (y - a.y) * vy) / dd);
      final hx = a.x + t * vx - x, hy = a.y + t * vy - y;
      gan = math.min(gan, math.sqrt(hx * hx + hy * hy));
    }
    return trongDg ? gan : -gan;
  }
}
