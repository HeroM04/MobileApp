import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../../data/services/thuc_chien_service.dart';
import '../../../data/services/upload_service.dart';

class ThucChienController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final KpiController kpiController = Get.put(KpiController());

  var isLoading = false.obs;
  var isSyncing = false.obs;
  var offlineDrafts = <Map<String, String>>[].obs;
  var hasConnection = true.obs;


  Timer? _syncTimer;

  @override
  void onInit() {
    super.onInit();
    // Bắt đầu bộ giám sát kiểm tra mạng và đồng bộ tự động mỗi 15 giây
    _startAutoSyncTimer();
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String date) async {
    try {
      final response = await ApiClient.dio.get('/field-battle/my-battles', queryParameters: {'date': date});
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print('Lỗi fetch lịch sử thực chiến: $e');
    }
    return [];
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }

  // Khởi động Timer định kỳ kiểm tra mạng
  void _startAutoSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await checkNetworkAndSync();
    });
  }

  // Kiểm tra trạng thái mạng thực tế bằng cách gọi nhanh lên server
  Future<bool> _testServerConnection() async {
    if (ApiClient.isDebugMode) {
      // Trong chế độ debug, coi như mạng tốt
      return true;
    }
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ));
      // Gọi thử một endpoint cơ bản của backend
      final response = await dio.get('${ApiClient.baseUrl}/auth/check-status').timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      // Bất kỳ lỗi mạng nào (SocketException, Timeout, v.v.)
      return false;
    }
  }

  // Thực hiện kiểm tra và đồng bộ
  Future<void> checkNetworkAndSync() async {
    final connected = await _testServerConnection();
    hasConnection.value = connected;

    if (connected && offlineDrafts.isNotEmpty && !isSyncing.value) {
      await autoSyncDrafts();
    }
  }

  // Gửi báo cáo gặp mặt
  Future<void> submitMeeting({
    required String name,
    required String phone,
    required String project,
    required String content,
    required String imagePath,
  }) async {
    isLoading.value = true;

    final connected = await _testServerConnection();
    hasConnection.value = connected;

    if (!connected) {
      // Mất kết nối -> Tự động lưu nháp
      offlineDrafts.add({
        'name': name,
        'phone': phone,
        'project': project,
        'content': content,
        'image': imagePath,
      });

      Get.snackbar(
        "Mất kết nối",
        "Mạng yếu hoặc không có kết nối. Đã tự động lưu nháp cuộc gặp. Hệ thống sẽ tự động đồng bộ khi có mạng trở lại.",
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      isLoading.value = false;
      return;
    }

    try {
      // Upload ảnh thật
      final uploadService = UploadService();
      String? realImageUrl;
      if (imagePath.isNotEmpty) {
        realImageUrl = await uploadService.uploadFile(File(imagePath));
        if (realImageUrl == null) throw "Không thể upload ảnh lên máy chủ";
      }

      // Gọi API gửi cuộc gặp lên backend thực tế
      final thucChienService = ThucChienService();
      await thucChienService.submitBattle({
        'customerName': name,
        'customerPhone': phone,
        'project': project,
        'content': content,
        'photoUrl': realImageUrl ?? "", 
      });

      kpiController.fetchKpiData(); // Refresh KPI data to sync with backend

      Get.defaultDialog(
        title: "Thành công",
        middleText: "Đã gửi báo cáo gặp khách hàng thành công chờ phê duyệt.",
        textConfirm: "Đồng ý",
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF0F2C59),
        onConfirm: () => Get.back(),
      );

    } catch (e) {
      // Nếu gọi API bị lỗi do kết nối mạng đột ngột
      offlineDrafts.add({
        'name': name,
        'phone': phone,
        'project': project,
        'content': content,
        'image': imagePath,
      });

      Get.snackbar(
        "Lỗi kết nối",
        "Có lỗi xảy ra khi kết nối máy chủ. Đã tự động lưu bản nháp để đồng bộ sau.",
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Tự động đồng bộ toàn bộ bản nháp lên server
  Future<void> autoSyncDrafts() async {
    isSyncing.value = true;
    final List<Map<String, String>> draftsToSync = List.from(offlineDrafts);
    int successCount = 0;
    final thucChienService = ThucChienService();

    for (var draft in draftsToSync) {
      try {
        // Upload ảnh thật trước khi sync
        final uploadService = UploadService();
        String? realImageUrl;
        if (draft['image'] != null && draft['image']!.isNotEmpty) {
           realImageUrl = await uploadService.uploadFile(File(draft['image']!));
        }
        
        await thucChienService.submitBattle({
          'customerName': draft['name'],
          'customerPhone': draft['phone'],
          'project': draft['project'],
          'content': draft['content'],
          'photoUrl': realImageUrl ?? "", 
        });
        
        successCount++;
      } catch (e) {
        print("Lỗi đồng bộ bản nháp: $e");
        // Nếu lỗi tiếp tục thì giữ lại để thử đồng bộ lần sau
      }
    }

    if (successCount > 0) {
      kpiController.fetchKpiData(); // Refresh KPI data
    }

    // Xoá các bản nháp đã đồng bộ thành công
    offlineDrafts.removeRange(0, successCount);
    isSyncing.value = false;

    if (successCount > 0) {
      Get.snackbar(
        "Tự động đồng bộ",
        "Đã tự động đồng bộ thành công $successCount báo cáo thực chiến ngoại tuyến!",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
