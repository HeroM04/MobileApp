import '../../core/network/api_client.dart';

class ChotCanService {
  Future<Map<String, dynamic>> submitDeal(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/deals/submit', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getMyDeals() async {
    final response = await ApiClient.dio.get('/deals/my-deals');
    return response.data;
  }
}
