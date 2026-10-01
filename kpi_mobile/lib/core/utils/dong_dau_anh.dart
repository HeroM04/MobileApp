import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Kết quả lấy vị trí để đóng dấu ảnh.
enum TrangThaiViTri { ok, tatGps, khongQuyen, gia, loi }

class ViTriChup {
  final TrangThaiViTri trangThai;
  final double? lat, lng;
  final String diaChi;
  const ViTriChup(this.trangThai, {this.lat, this.lng, this.diaChi = ''});

  bool get dung => trangThai == TrangThaiViTri.ok;

  /// Câu báo cho người dùng khi không lấy được vị trí hợp lệ.
  String get loiChoNguoiDung => switch (trangThai) {
        TrangThaiViTri.tatGps => 'Hãy bật định vị GPS để gắn địa điểm vào ảnh.',
        TrangThaiViTri.khongQuyen => 'Bạn cần cấp quyền vị trí cho ứng dụng để gắn địa điểm vào ảnh.',
        // Cùng câu với chấm công
        TrangThaiViTri.gia => 'Phát hiện phần mềm giả mạo vị trí (Fake GPS). Không thể dùng ảnh này!',
        TrangThaiViTri.loi => 'Không xác định được vị trí. Ra chỗ thoáng hoặc bật lại GPS rồi thử lại.',
        TrangThaiViTri.ok => '',
      };
}

/// "Số 12 Tố Hữu, Nam Từ Liêm, Hà Nội" — bỏ phần trống, giống Thực chiến.
String ghepDiaChi({String? duong, String? quanHuyen, String? tinh}) => [duong, quanHuyen, tinh]
    .where((s) => s != null && s.trim().isNotEmpty)
    .map((s) => s!.trim())
    .join(', ');

/// Lấy vị trí hiện tại + địa chỉ để đóng dấu ảnh.
///
/// Như chấm công: tắt GPS, chưa cấp quyền, hay đang dùng ứng dụng giả vị trí
/// thì KHÔNG trả vị trí — nơi gọi không nhận ảnh. Địa chỉ dịch từ tọa độ lỗi
/// (mất mạng) thì vẫn trả tọa độ làm địa chỉ, ảnh vẫn có nơi chụp.
Future<ViTriChup> layViTriChup() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return const ViTriChup(TrangThaiViTri.tatGps);
    var quyen = await Geolocator.checkPermission();
    if (quyen == LocationPermission.denied) quyen = await Geolocator.requestPermission();
    if (quyen == LocationPermission.denied || quyen == LocationPermission.deniedForever) {
      return const ViTriChup(TrangThaiViTri.khongQuyen);
    }
    final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    if (p.isMocked) return const ViTriChup(TrangThaiViTri.gia);

    var diaChi = '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
    try {
      final ds = await placemarkFromCoordinates(p.latitude, p.longitude).timeout(const Duration(seconds: 6));
      if (ds.isNotEmpty) {
        final s = ghepDiaChi(duong: ds.first.street, quanHuyen: ds.first.subAdministrativeArea, tinh: ds.first.administrativeArea);
        if (s.isNotEmpty) diaChi = s;
      }
    } catch (_) {}
    return ViTriChup(TrangThaiViTri.ok, lat: p.latitude, lng: p.longitude, diaChi: diaChi);
  } catch (_) {
    return const ViTriChup(TrangThaiViTri.loi);
  }
}

/// Điểm ảnh RGBA (đầu ra của Flutter) → JPEG chất lượng 85. Tách riêng để test
/// được: môi trường test không có card đồ họa nên không vẽ ảnh thật được.
List<int> rgbaSangJpg(ByteBuffer buffer, int rong, int cao) => img.encodeJpg(
      img.Image.fromBytes(width: rong, height: cao, bytes: buffer, numChannels: 4, order: img.ChannelOrder.rgba),
      quality: 85,
    );

const _thu = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];

/// Đóng dấu "Timemark" lên ảnh: logo, giờ | ngày, thứ, địa chỉ, họ tên, phòng —
/// cùng bố cục và cỡ chữ với ảnh Thực chiến (thuc_chien_view.dart).
///
/// Ảnh ra rộng tối đa 1200 px, lưu JPEG để gửi nhanh (bản Thực chiến lưu PNG,
/// nặng gấp nhiều lần). Lỗi thì trả lại ảnh gốc, không chặn người dùng.
Future<File> dongDauAnh(File goc, {required String diaChi, required String hoTen, required String phong, DateTime? luc}) async {
  try {
    final codec = await ui.instantiateImageCodec(await goc.readAsBytes());
    final anh = (await codec.getNextFrame()).image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    double scale = 1.0;
    if (anh.width > 1200) {
      scale = 1200 / anh.width;
      canvas.scale(scale, scale);
    }
    canvas.drawImage(anh, Offset.zero, Paint());

    final now = luc ?? DateTime.now();
    String hai(int n) => n.toString().padLeft(2, '0');
    final gio = '${hai(now.hour)}:${hai(now.minute)}';
    final ngay = '${hai(now.day)}/${hai(now.month)}/${now.year}';
    final thu = _thu[now.weekday == 7 ? 0 : now.weekday];

    // Cỡ chữ theo cạnh ngắn của ảnh — chữ bằng nhau trên mọi máy (xem Thực chiến)
    final double w = anh.width.toDouble(), h = anh.height.toDouble();
    final double canhNgan = w < h ? w : h;
    double cx(double phanTram) => canhNgan * phanTram;
    final double le = cx(0.022), cach = cx(0.016);
    final bong = [Shadow(color: Colors.black, blurRadius: cx(0.006))];

    final logo = TextPainter(
      text: TextSpan(
        text: 'TRÍ LONG LAND\n',
        style: TextStyle(color: const Color(0xFFD4AF37), fontSize: cx(0.030), fontWeight: FontWeight.bold, shadows: bong),
        children: [
          TextSpan(text: 'KIẾN TẠO SỰ BỀN VỮNG',
              style: TextStyle(color: Colors.white, fontSize: cx(0.015), letterSpacing: cx(0.0012), shadows: bong)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final thoiGian = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: '$gio ', style: TextStyle(color: Colors.white, fontSize: cx(0.052), fontWeight: FontWeight.bold)),
          TextSpan(text: '| ', style: TextStyle(color: const Color(0xFFD4AF37), fontSize: cx(0.042), fontWeight: FontWeight.w300)),
          TextSpan(text: '$ngay\n', style: TextStyle(color: Colors.white, fontSize: cx(0.021))),
          TextSpan(text: '         $thu', style: TextStyle(color: Colors.white, fontSize: cx(0.020))),
        ],
        style: TextStyle(shadows: bong, height: 1.15),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final noiChup = TextPainter(
      text: TextSpan(text: diaChi.isNotEmpty ? diaChi : 'Không xác định vị trí',
          style: TextStyle(color: Colors.white, fontSize: cx(0.022), height: 1.3, shadows: bong)),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: w - le * 2);

    final thongTin = TextPainter(
      text: TextSpan(text: 'Công ty: Trí Long Land\nHọ tên: $hoTen\nPhòng: $phong',
          style: TextStyle(color: Colors.white, fontSize: cx(0.020), height: 1.6, shadows: bong)),
      textDirection: TextDirection.ltr,
    )..layout();

    final double dem = cx(0.020);
    final double tongCao = logo.height + cach + thoiGian.height + cach + noiChup.height + cach + thongTin.height + dem * 2;
    double y = h - tongCao - le;
    if (y < le) y = le;
    final double x = le;

    logo.paint(canvas, Offset(x, y));
    y += logo.height + cach;
    thoiGian.paint(canvas, Offset(x, y));
    y += thoiGian.height + cach;
    noiChup.paint(canvas, Offset(x, y));
    y += noiChup.height + cach;
    canvas.drawRRect(
      RRect.fromLTRBR(x, y, x + thongTin.width + dem * 2, y + thongTin.height + dem, Radius.circular(cx(0.012))),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
    thongTin.paint(canvas, Offset(x + dem, y + dem / 2));

    final tm = TextPainter(
      text: TextSpan(
        text: 'Timemark\n',
        style: TextStyle(color: const Color(0xFFD4AF37), fontSize: cx(0.020), fontWeight: FontWeight.bold, shadows: bong),
        children: [TextSpan(text: '100% Chân thực', style: TextStyle(color: Colors.white, fontSize: cx(0.015), shadows: bong))],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    )..layout();
    tm.paint(canvas, Offset(w - tm.width - le, h - tm.height - le));

    final rong = (anh.width * scale).toInt(), cao = (anh.height * scale).toInt();
    final ra = await recorder.endRecording().toImage(rong, cao);
    final rgba = await ra.toByteData(format: ui.ImageByteFormat.rawRgba);
    final jpg = rgbaSangJpg(rgba!.buffer, rong, cao);

    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/dd_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await out.writeAsBytes(jpg);
    return out;
  } catch (e) {
    debugPrint('[Đóng dấu ảnh] Lỗi: $e');
    return goc;
  }
}
