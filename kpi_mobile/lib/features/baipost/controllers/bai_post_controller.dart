import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/post_service.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../../data/services/upload_service.dart';
import 'dart:io';

class BaiPostController extends GetxController {
  final PostService _postService = PostService();
  final KpiController kpiController = Get.put(KpiController());
  
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String date) async {
    try {
      final response = await ApiClient.dio.get('/social-posts/my-posts', queryParameters: {'date': date});
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print('Lỗi fetch lịch sử bài post: $e');
    }
    return [];
  }

  Future<bool> submitPost({
    required String platform,
    required String link,
    required String caption,
    required String screenshotUrl,
  }) async {
    try {
      isLoading.value = true;
      // Upload ảnh thật
      final uploadService = UploadService();
      String? realImageUrl;
      if (screenshotUrl.isNotEmpty) {
        realImageUrl = await uploadService.uploadFile(File(screenshotUrl));
        if (realImageUrl == null) throw "Không thể upload ảnh lên máy chủ";
      }

      final response = await _postService.submitPost({
        'platform': platform,
        'link': link,
        'caption': caption,
        'screenshotUrl': realImageUrl ?? "",
      });

      if (response['status'] == 'SUCCESS') {
        kpiController.fetchKpiData(); // Sync backend KPI points
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting post: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
