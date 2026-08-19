import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../data/services/referral_service.dart';
import '../../home/controllers/kpi_controller.dart';

/// Quản lý đơn giới thiệu nhân sự mới của người đang đăng nhập.
class ReferralController extends GetxController {
  final ReferralService _service = ReferralService();

  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var mySubmissions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMine();
  }

  Future<void> loadMine() async {
    try {
      isLoading.value = true;
      mySubmissions.value = await _service.mySubmissions();
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi tải đơn giới thiệu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Trả về null nếu gửi thành công, ngược lại là thông báo lỗi để hiển thị.
  Future<String?> submit({
    required String name,
    required String phone,
    String? note,
  }) async {
    if (name.trim().isEmpty) return 'Vui lòng nhập họ tên người được giới thiệu.';
    if (phone.trim().isEmpty) return 'Vui lòng nhập số điện thoại.';
    final cleanPhone = phone.trim().replaceAll(' ', '');
    if (!RegExp(r'^0\d{8,10}$').hasMatch(cleanPhone)) {
      return 'Số điện thoại không hợp lệ (bắt đầu bằng 0, 9–11 số).';
    }

    try {
      isSubmitting.value = true;
      final res = await _service.submit(
        candidateName: name.trim(),
        candidatePhone: cleanPhone,
        note: note?.trim(),
      );
      if (res['status'] == 'SUCCESS') {
        await loadMine();
        if (Get.isRegistered<KpiController>()) {
          Get.find<KpiController>().fetchKpiData();
        }
        return null;
      }
      return res['message']?.toString() ?? 'Không gửi được đơn giới thiệu.';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Không gửi được đơn giới thiệu. Vui lòng thử lại.';
    } catch (e) {
      return 'Không gửi được đơn giới thiệu. Vui lòng thử lại.';
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> cancel(int id) async {
    try {
      final res = await _service.cancel(id);
      if (res['status'] == 'SUCCESS') {
        await loadMine();
        return null;
      }
      return res['message']?.toString() ?? 'Không rút được đơn.';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Không rút được đơn.';
    } catch (e) {
      return 'Không rút được đơn.';
    }
  }
}
