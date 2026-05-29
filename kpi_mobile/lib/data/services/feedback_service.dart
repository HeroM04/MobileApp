import '../../core/network/api_client.dart';

class FeedbackService {
  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/feedbacks', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getMyFeedbacks() async {
    final response = await ApiClient.dio.get('/feedbacks/my');
    return response.data;
  }
}
