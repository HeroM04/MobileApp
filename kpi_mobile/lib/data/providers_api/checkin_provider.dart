import '../../core/network/api_client.dart';

class CheckinProvider {
  Future<dynamic> postCheckin(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/attendance/checkin', data: data);
    return response.data;
  }
}