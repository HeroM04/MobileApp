import '../../core/network/api_client.dart';

class CheckinService {
  // Hàm gọi API Check-in thông thường
  Future<Map<String, dynamic>> submitCheckin(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/attendance/checkin', data: data);
    return response.data;
  }

  // Hàm mới: Gửi yêu cầu xét duyệt khi ở ngoài phạm vi
  Future<Map<String, dynamic>> submitApproval(Map<String, dynamic> data) async {
    // Endpoint này cần khớp với @PostMapping("/request-approval") ở Backend
    final response = await ApiClient.dio.post('/attendance/request-approval', data: data);
    return response.data;
  }
}