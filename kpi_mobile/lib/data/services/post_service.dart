import '../../core/network/api_client.dart';

class PostService {
  Future<Map<String, dynamic>> submitPost(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/social-posts/submit', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getMyPosts() async {
    final response = await ApiClient.dio.get('/social-posts/my-posts');
    return response.data;
  }

  Future<Map<String, dynamic>> getAllPosts() async {
    final response = await ApiClient.dio.get('/social-posts');
    return response.data;
  }
}
