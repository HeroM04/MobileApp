import '../../core/network/api_client.dart';

/// Đơn xin vắng — nhân sự gửi trên app, Admin duyệt trên WebAdmin.
///
/// Đơn được duyệt: ngày đó tính là vắng có phép (−10đ KPI).
/// Không gửi đơn mà cũng không chấm công: hệ thống tự chấm vắng không phép (−15đ).
class LeaveService {
  Future<Map<String, dynamic>> submit({
    required String leaveDate, // yyyy-MM-dd
    required String reason,
  }) async {
    final response = await ApiClient.dio.post('/leave-requests', data: {
      'leaveDate': leaveDate,
      'reason': reason,
    });
    return response.data;
  }

  Future<List<Map<String, dynamic>>> myRequests() async {
    final response = await ApiClient.dio.get('/leave-requests/my');
    final data = response.data?['data'];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final response = await ApiClient.dio.delete('/leave-requests/$id');
    return response.data;
  }
}
