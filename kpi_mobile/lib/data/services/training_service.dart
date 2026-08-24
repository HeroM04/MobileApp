import '../../core/network/api_client.dart';

class TrainingService {
  /// Lấy danh sách buổi học đang/sắp diễn ra (từ hôm nay)
  /// Backend tự động ẩn buổi quá ngày cũ
  Future<Map<String, dynamic>> getAllSessions() async {
    final response = await ApiClient.dio.get('/training-sessions/active');
    return response.data;
  }

  /// Lấy toàn bộ lịch sử (dùng cho admin xem lại)
  Future<Map<String, dynamic>> getAllSessionsHistory() async {
    final response = await ApiClient.dio.get('/training-sessions');
    return response.data;
  }

  Future<Map<String, dynamic>> getSessionById(int id) async {
    final response = await ApiClient.dio.get('/training-sessions/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> attendTraining(String roomCode) async {
    final response = await ApiClient.dio.post('/training-sessions/attend', data: {
      'roomCode': roomCode,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/training-sessions', data: data);
    return response.data;
  }

  /// Cập nhật trạng thái buổi đào tạo (UPCOMING, ONGOING, COMPLETED, CANCELLED)
  Future<Map<String, dynamic>> updateStatus(int id, String status) async {
    final response = await ApiClient.dio.put(
      '/training-sessions/$id/status',
      queryParameters: {'status': status},
    );
    return response.data;
  }

  /// Lấy danh sách buổi đào tạo ĐÃ KẾT THÚC (status = COMPLETED) kèm videoUrl.
  /// Dùng cho màn hình "Kho Tài Liệu Đào Tạo" trên Mobile App.
  Future<Map<String, dynamic>> getCompletedSessions() async {
    final response = await ApiClient.dio.get('/training-sessions/completed');
    return response.data;
  }

  /// Admin cập nhật thông tin sau buổi học: tóm tắt nội dung và link video YouTube.
  Future<Map<String, dynamic>> updateVideoUrl(int id, String videoUrl) async {
    final response = await ApiClient.dio.put(
      '/training-sessions/$id',
      data: {'videoUrl': videoUrl},
    );
    return response.data;
  }

  // ── Đào tạo dự án: đăng ký tham gia hay xin vắng ─────────────────────────

  /// Trả lời sẽ tham gia buổi đào tạo. Vẫn phải quét mã ở buổi học mới là
  /// điểm danh — đây chỉ là lời hứa có mặt.
  Future<Map<String, dynamic>> dangKyThamGia(int sessionId) async {
    final response = await ApiClient.dio.post(
      '/training-sessions/$sessionId/rsvp',
      data: {'choice': 'JOIN'},
    );
    return response.data;
  }

  /// Xin không tham gia kèm lý do — Admin duyệt xong mới được tính điểm danh.
  Future<Map<String, dynamic>> xinVangDaoTao(int sessionId, String lyDo) async {
    final response = await ApiClient.dio.post(
      '/training-sessions/$sessionId/rsvp',
      data: {'choice': 'DECLINE', 'reason': lyDo},
    );
    return response.data;
  }

  /// Câu trả lời hiện tại của mình cho buổi này; null nghĩa là chưa trả lời.
  Future<Map<String, dynamic>?> traLoiCuaToi(int sessionId) async {
    final response = await ApiClient.dio.get('/training-sessions/$sessionId/rsvp/my');
    final d = response.data?['data'];
    return d is Map<String, dynamic> ? d : null;
  }
}
