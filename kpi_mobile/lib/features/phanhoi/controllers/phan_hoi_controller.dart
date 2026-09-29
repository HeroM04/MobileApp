import 'dart:io';

import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../data/services/feedback_service.dart';
import '../../../core/utils/dong_bo.dart';

class PhanHoiController extends GetxController {
  void Function()? _huyDongBo;

  final FeedbackService _feedbackService = FeedbackService();
  var isLoading = false.obs;
  
  var feedbacks = <Map<String, dynamic>>[].obs;
  var isLoadingHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyFeedbacks();
    // Admin sửa trên web thì máy chủ báo, danh sách này tự tải lại
    _huyDongBo = DongBo.dangKy(DongBo.phanHoi, () => fetchMyFeedbacks());
  }

  @override
  void onClose() {
    _huyDongBo?.call();
    super.onClose();
  }

  Future<void> fetchMyFeedbacks() async {
    try {
      isLoadingHistory.value = true;
      final response = await _feedbackService.getMyFeedbacks();
      if (response['status'] == 'SUCCESS') {
        final List<dynamic> data = response['data'] ?? [];
        feedbacks.assignAll(data.map((item) => Map<String, dynamic>.from(item)).toList());
      }
    } catch (e) {
      print('Error fetching feedbacks: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// Gửi góp ý, kèm ảnh nếu có. Trả về null nếu thành công, ngược lại là câu
  /// báo đúng lý do (ảnh không hợp lệ, mất mạng, máy chủ lỗi…).
  Future<String?> submitFeedback({
    required String title,
    required String category,
    required String content,
    required int rating,
    List<File> anh = const [],
  }) async {
    try {
      isLoading.value = true;
      final response = await _feedbackService.submitFeedback({
        'title': title,
        'category': category,
        'content': content,
        'rating': rating,
      }, anh: anh);

      if (response['status'] == 'SUCCESS') {
        fetchMyFeedbacks(); // Refresh history automatically
        return null;
      }
      return response['message']?.toString() ?? 'Máy chủ không nhận góp ý.';
    } catch (e) {
      print('Error submitting feedback: $e');
      return describeApiFailure(e).message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String date) async {
    try {
      final response = await ApiClient.dio.get('/feedbacks/my', queryParameters: {'date': date});
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print('Lỗi fetch lịch sử phản hồi: $e');
    }
    return [];
  }
}
