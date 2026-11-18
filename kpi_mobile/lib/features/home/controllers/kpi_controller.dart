import 'dart:async';

import 'package:get/get.dart';
import '../../../core/utils/dong_bo.dart';
import '../../../data/services/kpi_service.dart';
import '../../../data/services/websocket_service.dart';
import '../../auth/controllers/auth_controller.dart';

class KpiController extends GetxController {
  // Live KPI points and performance statistics
  var kpiPoints = 0.0.obs;
  var kpiTarget = 100.0.obs;
  var kpiWeeklyPoints = 0.0.obs;
  var kpiWeeklyTarget = 100.0.obs;

  var attendancePoints = 0.obs;
  var fieldBattleCount = 0.obs;
  var socialPostCount = 0.obs;
  var trainingAttendanceCount = 0.obs;

  var totalDealsClosed = 0.obs;

  var departmentMembers = <Map<String, dynamic>>[].obs;
  var isLoadingDepartment = false.obs;

  /// Đã nhận được điểm từ máy chủ ít nhất một lần chưa.
  ///
  /// Trước đây tải hỏng (mạng yếu, không kết nối được máy chủ) thì lỗi bị nuốt,
  /// các số giữ nguyên giá trị khởi tạo 0 → Trang chủ hiện "0 / 100 điểm — Cần
  /// cố gắng thêm", trợ lý còn báo "KPI đang ở mức thấp". Nhân sự tưởng mất hết
  /// điểm. Chưa có số liệu thì màn hình phải nói là chưa tải được, không hiện 0.
  var daCoSoLieu = false.obs;

  /// Lần tải gần nhất bị hỏng.
  var taiLoi = false.obs;
  var dangTai = false.obs;

  /// Tải hỏng thì tự thử lại vài lần, cách nhau dần ra — sóng chập chờn thường
  /// tự hết sau ít phút, không bắt nhân sự phải biết kéo xuống để tải lại.
  static const List<Duration> _henThuLai = [Duration(seconds: 15), Duration(seconds: 45), Duration(minutes: 2)];
  int _lanThuLai = 0;
  Timer? _hen;

  final _kpiService = KpiService();
  void Function()? _huyDongBo;

  /// Chỉ tiêu tháng = số thứ Hai của THÁNG KPI × 100. Tháng KPI là tháng của
  /// thứ Hai đầu tuần (như máy chủ): 1–4/10/2026 vẫn là KPI tháng 9, nên lấy
  /// tháng của thứ Hai tuần này chứ không lấy tháng dương lịch.
  static double chiTieuThang(DateTime homNay) {
    final thuHai = DateTime(homNay.year, homNay.month, homNay.day - (homNay.weekday - 1));
    final soNgay = DateTime(thuHai.year, thuHai.month + 1, 0).day;
    var soThuHai = 0;
    for (var i = 1; i <= soNgay; i++) {
      if (DateTime(thuHai.year, thuHai.month, i).weekday == DateTime.monday) soThuHai++;
    }
    return soThuHai * 100.0;
  }

  @override
  void onInit() {
    super.onInit();
    // Chỉ tiêu tính được ngay trên máy, không cần chờ máy chủ
    kpiTarget.value = chiTieuThang(DateTime.now());
    fetchKpiData();
    // Điểm KPI đã có kênh /topic/kpi khi app đang mở; dòng này để khi mở lại
    // app từ nền (kênh có thể đã rớt, tin bị lỡ) điểm vẫn được tải lại.
    _huyDongBo = DongBo.dangKy(DongBo.kpi, () => fetchKpiData());
    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().currentUser;
      if (user != null && user['userId'] != null) {
        WebSocketService().connect(user['userId']);
      }
    }
  }

  @override
  void onClose() {
    _hen?.cancel();
    _huyDongBo?.call();
    WebSocketService().disconnect();
    super.onClose();
  }

  void _henTaiLai() {
    _hen?.cancel();
    if (_lanThuLai >= _henThuLai.length) return;
    _hen = Timer(_henThuLai[_lanThuLai++], () {
      if (!isClosed) fetchKpiData();
    });
  }

  Future<void> fetchKpiData() async {
    var thanhCong = false;
    dangTai.value = true;
    try {
      final response = await _kpiService.getMyKpiScore();
      if (response['status'] == 'SUCCESS') {
        thanhCong = true;
        final kpi = response['data'] ?? {};
        kpiTarget.value = chiTieuThang(DateTime.now());

        attendancePoints.value = (kpi['attendance'] as num?)?.toInt() ?? 0;
        fieldBattleCount.value = (kpi['meeting'] as num?)?.toInt() ?? 0;
        socialPostCount.value = (kpi['post'] as num?)?.toInt() ?? 0;
        totalDealsClosed.value = (kpi['deal'] as num?)?.toInt() ?? 0;
        double rawPoints = (kpi['total'] as num?)?.toDouble() ?? 0.0;
        double rawWeeklyPoints = (kpi['weeklyTotal'] as num?)?.toDouble() ?? 0.0;

        // Cap the display points so it doesn't exceed 100%
        if (rawPoints > kpiTarget.value) rawPoints = kpiTarget.value;
        kpiPoints.value = rawPoints;

        if (rawWeeklyPoints > kpiWeeklyTarget.value) rawWeeklyPoints = kpiWeeklyTarget.value;
        kpiWeeklyPoints.value = rawWeeklyPoints;
        daCoSoLieu.value = true;
      }

      // Lấy danh sách KPI phòng ban nếu là TRUONG_PHONG
      // Đọc role từ currentUser trong memory (đã được set từ login response)
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        final role = authController.currentUser['role'];
        if (role == 'TRUONG_PHONG') {
          await fetchMyDepartmentKpis();
        }
      }
    } catch (e) {
      print('Error fetching KPI data: $e');
    } finally {
      dangTai.value = false;
      taiLoi.value = !thanhCong;
      if (thanhCong) {
        _lanThuLai = 0;
        _hen?.cancel();
      } else {
        _henTaiLai();
      }
    }
  }

  /// Máy chủ đẩy điểm mới qua kênh trực tiếp — cũng tính là đã có số liệu.
  void daNhanDiemTrucTiep() {
    daCoSoLieu.value = true;
    taiLoi.value = false;
  }

  /// Gọi endpoint mới /kpi-scores/my-department.
  /// Backend đọc departmentId từ JWT token → không bao giờ bị sai phòng ban do cache.
  Future<void> fetchMyDepartmentKpis() async {
    try {
      isLoadingDepartment.value = true;
      final response = await _kpiService.getMyDepartmentKpis();
      if (response['status'] == 'SUCCESS') {
        final list = response['data'] as List<dynamic>? ?? [];
        departmentMembers.assignAll(
          List<Map<String, dynamic>>.from(list),
        );
      }
    } catch (e) {
      print('Error fetching department KPIs: $e');
    } finally {
      isLoadingDepartment.value = false;
    }
  }

  /// Giữ lại hàm cũ cho các màn hình Admin/Web dùng (truyền departmentId cụ thể).
  Future<void> fetchDepartmentKpis(int departmentId) async {
    try {
      final response = await _kpiService.getDepartmentKpis(departmentId);
      if (response['status'] == 'SUCCESS') {
        final list = response['data'] as List<dynamic>? ?? [];
        departmentMembers.assignAll(List<Map<String, dynamic>>.from(list));
      }
    } catch (e) {
      print('Error fetching department KPIs: $e');
    }
  }

  void reset() {
    _hen?.cancel();
    _lanThuLai = 0;
    daCoSoLieu.value = false;
    taiLoi.value = false;
    kpiPoints.value = 0.0;
    kpiWeeklyPoints.value = 0.0;
    attendancePoints.value = 0;
    fieldBattleCount.value = 0;
    socialPostCount.value = 0;
    trainingAttendanceCount.value = 0;
    totalDealsClosed.value = 0;
    departmentMembers.clear(); // Xóa danh sách phòng ban khi logout/reset
  }
}
