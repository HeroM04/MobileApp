import 'package:get/get.dart';

import '../../../data/services/kpi_service.dart';
import '../../thongbao/controllers/thong_bao_controller.dart';

class ShellController extends GetxController {
  // Chỉ số tab hiện tại
  var selectedIndex = 0.obs;

  /// Vị trí của mục Thông báo trong [menuItems] — dùng cho huy hiệu đỏ và cho
  /// các nơi khác muốn mở thẳng màn hình này.
  static const int mucThongBao = 8;

  // Danh sách các đề mục trong Sidebar
  final List<String> menuItems = [
    "Trang chủ",
    "Chấm công",
    "Thực chiến",
    "Bài post",
    "Đào tạo",
    "Gieo hạt",
    "Phản hồi",
    "Chốt căn",
    "Thông báo",
    "Trang cá nhân",
  ];

  /// Số khoản điểm KPI mới chưa xem — hiện thành huy hiệu đỏ trên thanh tiêu đề.
  final soThongBaoMoi = 0.obs;

  final _kpiService = KpiService();

  @override
  void onInit() {
    super.onInit();
    capNhatSoThongBao();
  }

  void changeMenuIndex(int index) {
    selectedIndex.value = index;
    if (index != mucThongBao) return;

    // Mở màn hình Thông báo là coi như đã xem hết, tắt huy hiệu ngay cho khỏi
    // phải chờ gọi máy chủ xong.
    soThongBaoMoi.value = 0;

    // Lần đầu vào thì controller chưa tồn tại, onInit của nó tự nạp. Từ lần thứ
    // hai trở đi GetX giữ lại controller cũ nên onInit không chạy nữa — phải
    // gọi tay, không thì người dùng quay lại chỉ thấy dữ liệu cũ.
    if (Get.isRegistered<ThongBaoController>()) {
      final c = Get.find<ThongBaoController>();
      c.tai();
      c.danhDauDaXem();
    }
  }

  Future<void> capNhatSoThongBao() async {
    try {
      soThongBaoMoi.value = await _kpiService.demChuaDoc();
    } catch (_) {
      // Không lấy được thì giữ nguyên, không làm phiền người dùng.
    }
  }
}
