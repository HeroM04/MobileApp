import '../../core/network/api_client.dart';

/// Đơn giới thiệu ứng viên — nhân sự gửi trên app, Admin duyệt trên WebAdmin.
///
/// Admin duyệt là tài khoản của người được giới thiệu được mở luôn. Một tháng
/// sau, nếu người đó vẫn còn làm thì người giới thiệu được +15đ nhóm Lan tỏa.
class ReferralService {
  Future<Map<String, dynamic>> submit({
    required String candidateName,
    required String candidatePhone,
    String? note,
  }) async {
    final response = await ApiClient.dio.post('/referral-submissions', data: {
      'candidateName': candidateName,
      'candidatePhone': candidatePhone,
      'note': note,
    });
    return response.data;
  }

  Future<List<Map<String, dynamic>>> mySubmissions() async {
    final response = await ApiClient.dio.get('/referral-submissions/my');
    final data = response.data?['data'];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final response = await ApiClient.dio.delete('/referral-submissions/$id');
    return response.data;
  }
}
