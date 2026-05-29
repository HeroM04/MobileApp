import '../../core/network/api_client.dart';

class KpiService {
  Future<Map<String, dynamic>> getMyKpiScore() async {
    final response = await ApiClient.dio.get('/kpi-scores/my');
    return response.data;
  }

  /// Lấy KPI nhân sự trong phòng mình — backend tự đọc departmentId từ JWT token.
  /// Không truyền departmentId từ cache phía app để tránh hiển thị sai phòng ban.
  Future<Map<String, dynamic>> getMyDepartmentKpis() async {
    final response = await ApiClient.dio.get('/kpi-scores/my-department');
    return response.data;
  }

  /// Lấy KPI toàn công ty, lọc theo phòng ban — dành cho Admin/Web (ít dùng trên Mobile).
  Future<Map<String, dynamic>> getDepartmentKpis(int departmentId) async {
    final response = await ApiClient.dio.get('/kpi-scores', queryParameters: {
      'departmentId': departmentId,
    });
    return response.data;
  }
}
