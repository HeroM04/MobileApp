import 'package:url_launcher/url_launcher.dart';

/// Trang hướng dẫn sử dụng (GitHub Pages của kho kpi-trilong-app). Nội dung sửa
/// trên web, không cần phát hành lại app.
const String linkHuongDan = String.fromEnvironment(
  'LINK_HUONG_DAN',
  defaultValue: 'https://herom04.github.io/kpi-trilong-app/',
);

/// Mục trong trang hướng dẫn ứng với từng màn hình — khóa là chỉ số trong
/// ShellController.menuItems. Đổi thứ tự menu thì sửa cả ở đây.
const Map<int, String> mucHuongDanTheoManHinh = {
  0: 'bat-dau', // Trang chủ
  1: 'cham-cong',
  2: 'thuc-chien',
  3: 'bai-post',
  4: 'dao-tao',
  5: 'gieo-hat',
  6: 'phan-hoi',
  7: 'chot-can',
  8: 'thong-bao',
  9: 'ca-nhan',
};

/// Link tới đúng mục của màn hình đang xem; không rõ màn hình thì mở đầu trang.
String linkMucHuongDan([int? manHinh]) {
  final muc = manHinh == null ? null : mucHuongDanTheoManHinh[manHinh];
  return muc == null ? linkHuongDan : '$linkHuongDan#$muc';
}

/// Mở hướng dẫn trong trình duyệt ngay trong app (Custom Tabs / Safari View),
/// máy không hỗ trợ thì mở trình duyệt ngoài.
Future<void> moHuongDan([int? manHinh]) async {
  final uri = Uri.parse(linkMucHuongDan(manHinh));
  try {
    if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return;
  } catch (_) {}
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
