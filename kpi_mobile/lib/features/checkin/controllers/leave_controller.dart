import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/leave_service.dart';

/// Quản lý đơn xin vắng của nhân sự đang đăng nhập.
class LeaveController extends GetxController {
  final LeaveService _service = LeaveService();

  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var myRequests = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMyRequests();
  }

  Future<void> loadMyRequests() async {
    try {
      isLoading.value = true;
      myRequests.value = await _service.myRequests();
    } catch (e) {
      // Không chặn màn hình nếu chỉ lỗi tải danh sách
      // ignore: avoid_print
      print('Lỗi tải đơn xin vắng: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Trả về null nếu gửi thành công, ngược lại là thông báo lỗi để hiển thị.
  Future<String?> submit({required DateTime date, required String reason}) async {
    if (reason.trim().isEmpty) return 'Vui lòng nhập lý do xin vắng.';

    final ymd = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    try {
      isSubmitting.value = true;
      final res = await _service.submit(leaveDate: ymd, reason: reason.trim());
      if (res['status'] == 'SUCCESS') {
        await loadMyRequests();
        return null;
      }
      return res['message']?.toString() ?? 'Không gửi được đơn xin vắng.';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Không gửi được đơn xin vắng. Vui lòng thử lại.';
    } catch (e) {
      return 'Không gửi được đơn xin vắng. Vui lòng thử lại.';
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> cancel(int id) async {
    try {
      final res = await _service.cancel(id);
      if (res['status'] == 'SUCCESS') {
        await loadMyRequests();
        return null;
      }
      return res['message']?.toString() ?? 'Không hủy được đơn.';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Không hủy được đơn.';
    } catch (e) {
      return 'Không hủy được đơn.';
    }
  }
}
