import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
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

  /// Gửi bài lan tỏa lên máy chủ.
  ///
  /// Trả về null khi thành công, ngược lại là mô tả lỗi đã phân loại rõ hỏng ở
  /// đâu. Trước đây hàm này chỉ trả về true/false rồi nuốt nguyên nhân vào một
  /// dòng print, nên màn hình chỉ hiện được câu chung chung "không gửi được" —
  /// nhân viên không biết mình nhập sai hay hệ thống hỏng.
  Future<ApiFailure?> submitPost({
    required String platform,
    required String link,
    required String caption,
    required String screenshotUrl,
    String contentType = 'POST',
  }) async {
    try {
      isLoading.value = true;

      // Upload ảnh chụp màn hình trước
      final uploadService = UploadService();
      String? realImageUrl;
      if (screenshotUrl.isNotEmpty) {
        try {
          realImageUrl = await uploadService.uploadFile(File(screenshotUrl));
        } catch (e) {
          final f = describeApiFailure(e, action: 'tải ảnh');
          return ApiFailure(f.kind, 'Không tải được ảnh lên', f.message);
        }
        if (realImageUrl == null) {
          return const ApiFailure(ApiFailureKind.server, 'Không tải được ảnh lên',
              'Máy chủ nhận ảnh nhưng không trả về đường dẫn. Đây là lỗi hệ thống, báo lại bộ phận kỹ thuật.');
        }
      }

      final response = await _postService.submitPost({
        'platform': platform,
        'contentType': contentType,
        'link': link,
        'caption': caption,
        'screenshotUrl': realImageUrl ?? "",
      });

      if (response['status'] == 'SUCCESS') {
        kpiController.fetchKpiData(); // Sync backend KPI points
        return null;
      }
      return ApiFailure(ApiFailureKind.server, 'Không gửi được bài',
          response['message']?.toString() ?? 'Máy chủ trả về kết quả không hợp lệ.');
    } catch (e) {
      print('Lỗi gửi bài lan tỏa: $e');
      return describeApiFailure(e);
    } finally {
      isLoading.value = false;
    }
  }
}
