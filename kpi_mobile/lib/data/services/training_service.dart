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
}
