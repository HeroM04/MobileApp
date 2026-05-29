import '../../core/network/api_client.dart';

class ThucChienService {
  Future<Map<String, dynamic>> submitBattle(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/field-battle/submit', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getMyBattles() async {
    final response = await ApiClient.dio.get('/field-battle/my-battles');
    return response.data;
  }
}
