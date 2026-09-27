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
