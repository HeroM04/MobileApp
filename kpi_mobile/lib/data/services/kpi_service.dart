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

  // ── Nhật ký điểm KPI (màn hình Thông báo) ────────────────────────────────

  /// Nhật ký một kỳ. [loai] là 'week' hoặc 'month'; [lui] 0 là kỳ hiện tại,
  /// 1 là kỳ liền trước…
  Future<Map<String, dynamic>> layNhatKy({String loai = 'week', int lui = 0}) async {
    final response = await ApiClient.dio.get('/kpi-ledger/my', queryParameters: {
      'type': loai,
      'offset': lui,
    });
    return response.data;
  }

  /// Số khoản điểm mới kể từ lần mở màn hình Thông báo gần nhất.
  Future<int> demChuaDoc() async {
    final response = await ApiClient.dio.get('/kpi-ledger/my/unread');
    return (response.data?['data']?['unread'] as num?)?.toInt() ?? 0;
  }

  Future<void> danhDauDaXem() async {
    await ApiClient.dio.post('/kpi-ledger/my/seen');
  }
}
