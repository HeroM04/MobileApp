import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Nơi DUY NHẤT đọc/ghi token đăng nhập trong máy.
///
/// Trước đây mỗi chỗ tự tạo kho riêng, và chỗ đọc token cho mọi yêu cầu mạng
/// hễ đọc lỗi một lần là XÓA SẠCH kho rồi đăng xuất. Trên iPhone, app được
/// đánh thức chạy nền lúc máy đang khóa là đọc lỗi (kho mặc định chỉ mở khi máy
/// mở khóa) — người dùng mở app ra thấy bị đăng xuất mà không làm gì cả.
///
/// Giờ: đọc lỗi thì trả null và giữ nguyên kho. Chỉ máy chủ nói rõ phiên hết
/// hiệu lực, hoặc người dùng bấm Đăng xuất, mới xóa token.
class KhoToken {
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';

  static const _kho = FlutterSecureStorage(
    // iPhone: đọc được cả khi máy đang khóa, miễn là đã mở khóa ít nhất một lần
    // từ lúc bật máy. Token cũ lưu theo chế độ mặc định vẫn đọc được; lần làm
    // mới token kế tiếp tự lưu lại theo chế độ này.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  /// Đọc một khóa; lỗi thì thử lại một lần, vẫn lỗi thì null — KHÔNG xóa gì.
  static Future<String?> doc(String khoa) async {
    for (var lan = 0; lan < 2; lan++) {
      try {
        return await _kho.read(key: khoa);
      } catch (_) {
        if (lan == 0) await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    return null;
  }

  static Future<void> ghi(String khoa, String giaTri) => _kho.write(key: khoa, value: giaTri);

  static Future<void> xoa(String khoa) async {
    try {
      await _kho.delete(key: khoa);
    } catch (_) {}
  }
}
