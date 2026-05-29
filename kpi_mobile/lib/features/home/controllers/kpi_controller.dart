import 'package:get/get.dart';
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

  final _kpiService = KpiService();

  @override
  void onInit() {
    super.onInit();
    fetchKpiData();
    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().currentUser;
      if (user != null && user['userId'] != null) {
        WebSocketService().connect(user['userId']);
      }
    }
  }

  @override
  void onClose() {
    WebSocketService().disconnect();
    super.onClose();
  }

  Future<void> fetchKpiData() async {
    try {
      final response = await _kpiService.getMyKpiScore();
      if (response['status'] == 'SUCCESS') {
        final kpi = response['data'] ?? {};
        
        // Calculate dynamic KPI Target based on number of Mondays in the month
        final now = DateTime.now();
        int mondays = 0;
        int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          if (DateTime(now.year, now.month, i).weekday == DateTime.monday) {
            mondays++;
          }
        }
        kpiTarget.value = mondays * 100.0;

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
    }
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
    kpiPoints.value = 0.0;
    attendancePoints.value = 0;
    fieldBattleCount.value = 0;
    socialPostCount.value = 0;
    trainingAttendanceCount.value = 0;
    totalDealsClosed.value = 0;
    departmentMembers.clear(); // Xóa danh sách phòng ban khi logout/reset
  }
}
