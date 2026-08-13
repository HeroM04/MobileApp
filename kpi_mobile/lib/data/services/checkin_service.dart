import '../../core/network/api_client.dart';

class CheckinService {
  /// Gửi chấm công (dùng chung cho cả trong và ngoài phạm vi văn phòng).
  ///
  /// Backend tự quyết định trạng thái dựa trên khoảng cách tới văn phòng:
  /// - Trong bán kính cho phép  → APPROVED ngay, cộng KPI luôn.
  /// - Ngoài bán kính           → PENDING, chờ Admin/Trưởng phòng duyệt
  ///                              (bắt buộc gửi kèm `note` là lý do).
  Future<Map<String, dynamic>> submitCheckin(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/attendance/checkin', data: data);
    return response.data;
  }
}