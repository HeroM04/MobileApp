import 'package:intl/intl.dart';

DateTime? _doc(Object? iso) {
  if (iso == null || iso.toString().isEmpty) return null;
  return DateTime.tryParse(iso.toString())?.toLocal();
}

String _gioNgay(DateTime d) => DateFormat('HH:mm · dd/MM').format(d);

/// Mốc hiện cạnh một khoản điểm trên màn Thông báo.
///
/// Là lúc khoản đó được GHI — cùng mốc máy chủ dùng để xếp, nên đọc từ trên
/// xuống thì giờ lùi dần. Trước đây hiện lúc phát sinh: Admin thu hồi hay thêm
/// chấm công tay mang giờ của lượt chấm công cũ, nhìn như xếp lộn xộn.
/// Khoản ghi vào một ngày khác ngày nó được tính (Admin duyệt muộn, thêm tay
/// cho hôm trước) thì ghi thêm ngày được tính.
String mocKhoanDiem(Map<dynamic, dynamic> khoan) {
  final ghi = _doc(khoan['createdAt']);
  final phatSinh = _doc(khoan['occurredAt']);
  if (ghi == null) return phatSinh == null ? '' : _gioNgay(phatSinh);
  final cungNgay = phatSinh == null ||
      (ghi.year == phatSinh.year && ghi.month == phatSinh.month && ghi.day == phatSinh.day);
  if (cungNgay) return _gioNgay(ghi);
  return '${_gioNgay(ghi)} · cho ngày ${DateFormat('dd/MM').format(phatSinh)}';
}
