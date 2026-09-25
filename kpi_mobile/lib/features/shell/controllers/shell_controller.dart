import 'package:get/get.dart';

import '../../../core/utils/dong_bo.dart';
import '../../../data/services/kpi_service.dart';
import '../../auth/controllers/auth_controller.dart';
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

  /// Chỉ số các mục được hiện trong menu, theo vai trò.
  ///
  /// Văn phòng (Back-Office) và Admin không thuộc diện chấm KPI — họ chỉ chấm
  /// công. Sáu mục còn lại (Thực chiến, Bài post, Đào tạo, Gieo hạt, Chốt căn,
  /// Thông báo điểm) đều là nghiệp vụ KPI, mở ra chỉ để thấy trống hoặc gửi báo
  /// cáo rồi chờ điểm không bao giờ tới.
  ///
  /// Trả về CHỈ SỐ chứ không phải danh sách mới: chỉ số chính là tham số của
  /// [changeMenuIndex] và quyết định màn hình nào hiện ra, cắt bớt danh sách là
  /// lệch hết.
  List<int> get mucHienThi {
    final vaiTro = Get.isRegistered<AuthController>()
        ? (Get.find<AuthController>().currentUser['role']?.toString() ?? 'SALE')
        : 'SALE';
    final chamKpi = vaiTro == 'SALE' || vaiTro == 'TRUONG_PHONG';
    if (chamKpi) return List.generate(menuItems.length, (i) => i);
    return const [0, 1, 6, 9]; // Trang chủ · Chấm công · Phản hồi · Trang cá nhân
  }

  /// Số khoản điểm KPI mới chưa xem — hiện thành huy hiệu đỏ trên thanh tiêu đề.
  final soThongBaoMoi = 0.obs;

  final _kpiService = KpiService();
  void Function()? _huyDongBo;

  @override
  void onInit() {
    super.onInit();
    capNhatSoThongBao();
    _huyDongBo = DongBo.dangKy(DongBo.kpi, () => capNhatSoThongBao());
  }

  @override
  void onClose() {
    _huyDongBo?.call();
    super.onClose();
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
