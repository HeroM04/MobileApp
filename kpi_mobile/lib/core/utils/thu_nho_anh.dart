import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Cạnh dài tối đa của ảnh chấm công gửi lên máy chủ, tính bằng pixel.
///
/// Camera trước ngày nay chụp 5–12 megapixel, mỗi ảnh vài MB, trong khi ảnh
/// chấm công chỉ cần nhìn rõ mặt và đọc được dòng giờ + địa chỉ đóng trên ảnh.
/// 200 người × 2 lượt/ngày mà gửi nguyên cỡ thì kho ảnh Cloudinary gói miễn phí
/// đầy sau vài tháng, lại tải chậm trên 4G yếu giờ cao điểm.
///
/// Lấy 1280 chứ không nhỏ hơn: ảnh dọc khi đó rộng 960, vừa đủ cho dòng địa chỉ
/// đóng dấu (font cố định 24 px) không bị cắt ở mép phải.
const int canhDaiAnhChamCong = 1280;

/// Thu nhỏ để cạnh dài nhất không quá [canhDai], giữ nguyên tỉ lệ.
/// Ảnh đã nhỏ hơn thì trả lại nguyên ảnh, không phóng to.
img.Image thuNhoAnh(img.Image anh, {int canhDai = canhDaiAnhChamCong}) {
  if (anh.width <= canhDai && anh.height <= canhDai) return anh;
  // Thu nhỏ nhiều lần thì lấy trung bình các điểm ảnh cho mịn, không bị răng cưa
  return anh.width >= anh.height
      ? img.copyResize(anh, width: canhDai, interpolation: img.Interpolation.average)
      : img.copyResize(anh, height: canhDai, interpolation: img.Interpolation.average);
}

/// Ảnh gửi lên (bài đăng, thực chiến, đào tạo...) nặng hơn mức này thì nén lại
/// trên máy trước khi gửi.
const int nguongNenAnhGui = 2 * 1024 * 1024;

/// Ngang tối đa của ảnh gửi lên — đúng cỡ Cloudinary vẫn cắt khi lưu.
const int ngangToiDaAnhGui = 1920;

/// Tổng điểm ảnh tối đa, giống máy chủ: ảnh chụp cuộn rất dài thu theo tỉ lệ.
const int diemAnhToiDaAnhGui = 8000000;

/// Nén ảnh nặng sang JPEG trước khi gửi lên máy chủ.
///
/// Ảnh chụp màn hình là PNG, image_picker không nén được PNG (imageQuality chỉ
/// áp cho JPEG), nên chụp màn hình bài đăng nhiều hình có thể nặng 11 MB:
/// gửi lâu trên 4G, và 08/11/2026 máy chủ 512 MB bị tắt vì phải tự nén một ảnh
/// như vậy. Nén ở điện thoại (dư bộ nhớ) thì ảnh gửi đi chỉ còn 1–3 MB.
///
/// Chạy ở isolate riêng để màn hình không bị đứng. Ảnh nhẹ, định dạng không
/// đọc được (HEIC...) hoặc nén xong không nhẹ hơn thì trả lại file gốc —
/// máy chủ vẫn tự nén ảnh trên 10 MB.
Future<File> nenAnhTruocKhiGui(File file) async {
  try {
    final soByte = await file.length();
    if (soByte <= nguongNenAnhGui) return file;
    final duongDan = file.path;
    final jpeg = await Isolate.run(() => nenJpeg(File(duongDan).readAsBytesSync()));
    if (jpeg == null || jpeg.length >= soByte) return file;
    final cham = duongDan.lastIndexOf('.');
    final goc = cham > duongDan.lastIndexOf(Platform.pathSeparator) ? duongDan.substring(0, cham) : duongDan;
    final ra = File('${goc}_gui.jpg');
    await ra.writeAsBytes(jpeg, flush: true);
    return ra;
  } catch (e) {
    print('Lỗi nén ảnh trước khi gửi: $e');
    return file;
  }
}

/// Giải mã ảnh, xoay đúng chiều theo EXIF, thu về ngang ≤ 1920 px và ≤ 8 MP,
/// nền trắng thay phần trong suốt, mã hóa JPEG chất lượng 85.
/// Không đọc được thì null.
Uint8List? nenJpeg(Uint8List duLieu) {
  final goc = img.decodeImage(duLieu);
  if (goc == null) return null;
  var anh = img.bakeOrientation(goc);
  final tiLe = math.min(1.0, math.min(ngangToiDaAnhGui / anh.width,
      math.sqrt(diemAnhToiDaAnhGui / (anh.width * anh.height))));
  if (tiLe < 1.0) {
    anh = img.copyResize(anh,
        width: math.max(1, (anh.width * tiLe).round()),
        height: math.max(1, (anh.height * tiLe).round()),
        interpolation: img.Interpolation.average);
  }
  if (anh.hasAlpha) {
    // JPEG không có kênh trong suốt: không lót nền thì phần trong suốt thành đen
    final nen = img.Image(width: anh.width, height: anh.height);
    img.fill(nen, color: img.ColorRgb8(255, 255, 255));
    anh = img.compositeImage(nen, anh);
  }
  return img.encodeJpg(anh, quality: 85);
}
