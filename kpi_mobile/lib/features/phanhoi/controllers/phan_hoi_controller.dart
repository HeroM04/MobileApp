import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
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

  Future<bool> submitFeedback({
    required String title,
    required String category,
    required String content,
    required int rating,
  }) async {
    try {
      isLoading.value = true;
      final response = await _feedbackService.submitFeedback({
        'title': title,
        'category': category,
        'content': content,
        'rating': rating,
      });

      if (response['status'] == 'SUCCESS') {
        fetchMyFeedbacks(); // Refresh history automatically
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
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
