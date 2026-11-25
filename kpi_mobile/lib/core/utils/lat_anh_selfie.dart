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
