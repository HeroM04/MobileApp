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
///
/// [huongExif]: thẻ Orientation của ảnh. Thẻ kiểu gương (2, 4, 5, 7) nghĩa là
/// máy đã lưu ảnh như soi gương — bật "Phản chiếu camera trước" trong Cài đặt —
/// xoay theo thẻ là ảnh đã giống lúc soi, lật thêm thành ngược lại.
bool nenLatAnhSelfie({required bool laIOS, String? ongKinh, int? huongExif}) {
  if (!laIOS) return false;
  if (const {2, 4, 5, 7}.contains(huongExif)) return false;
  final ok = (ongKinh ?? '').toLowerCase();
  if (ok.isEmpty) return true;
  return ok.contains('front');
}
