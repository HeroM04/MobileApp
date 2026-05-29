import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:kpi_mobile/data/services/checkin_service.dart';
import 'package:kpi_mobile/data/services/upload_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class CheckinController extends GetxController {
  var isLoading = false.obs;
  var isOutOfRange = false.obs;
  var selectedImage = Rx<File?>(null);
  
  var historyList = [].obs;
  var isHistoryLoading = false.obs;
  var selectedActionType = 'CHECK_IN'.obs; // 'CHECK_IN' hoặc 'CHECK_OUT'

  @override
  void onInit() {
    super.onInit();
    // Không fetch sẵn - chỉ fetch khi chuyển tab Lịch sử (do HistoryDateListView quản lý)
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String date) async {
    try {
      final response = await ApiClient.dio.get('/attendance/my-checkins', queryParameters: {'date': date});
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print("Lỗi fetch lịch sử checkin: $e");
    }
    return [];
  }
  
  final ImagePicker _picker = ImagePicker();
  final CheckinService _service = CheckinService();

  // Lấy userId hiện tại từ AuthController
  int get currentUserId {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      return auth.currentUser['userId'] ?? 1;
    }
    return 1;
  }

  // Hàm chụp ảnh từ Camera hoặc Gallery tùy chọn (Chống treo trên máy ảo)
  Future<void> takePhoto() async {
    // Nếu chạy trên Desktop, chọn thẳng từ thư viện tệp
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await _pickFromSource(ImageSource.gallery);
      return;
    }

    // Trên di động/máy ảo, hiển thị BottomSheet chọn nguồn để tránh treo camera ảo
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A), // Deep Navy
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Chọn ảnh chân dung xác thực",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD4AF37)),
              title: const Text("Chụp ảnh từ Camera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _pickFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFD4AF37)),
              title: const Text("Chọn từ Thư viện ảnh (Khuyên dùng cho máy ảo)", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _pickFromSource(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Helper hỗ trợ chọn ảnh với timeout
  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      ).timeout(const Duration(seconds: 15)); // Giới hạn 15s tránh treo hệ thống camera
      
      if (photo != null) {
        selectedImage.value = File(photo.path);
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể lấy hình ảnh: $e");
    }
  }

  // Hàm Check-in thông thường
  Future<void> performCheckin(String note) async {
    if (selectedImage.value == null) {
      Get.snackbar("Lỗi", "Vui lòng chụp ảnh chân dung trước khi Check-in!");
      return;
    }

    try {
      isLoading.value = true;

      double latitude = 0.0;
      double longitude = 0.0;

      // Định vị GPS thực tế qua Geolocator (Chỉ chạy trên Mobile)
      if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
              .timeout(const Duration(seconds: 3));
          
          if (!serviceEnabled) {
            Get.snackbar("Lỗi", "Hãy bật định vị GPS trên điện thoại!");
            isLoading.value = false;
            return;
          }

          LocationPermission permission = await Geolocator.checkPermission()
              .timeout(const Duration(seconds: 3));
          
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission()
                .timeout(const Duration(seconds: 5));
            if (permission == LocationPermission.denied) {
              Get.snackbar("Lỗi", "Bạn cần cấp quyền vị trí cho ứng dụng!");
              isLoading.value = false;
              return;
            }
          }

          // Lấy vị trí GPS với giới hạn thời gian 5 giây
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 5));
          
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (gpsErr) {
          print("Lỗi định vị GPS thực tế: $gpsErr. Sử dụng toạ độ mặc định từ profile.");
        }
      }

      // Fallback nếu là Desktop hoặc lỗi/timeout định vị GPS
      if (latitude == 0.0 && longitude == 0.0) {
        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          latitude = auth.currentUser['officeLat'] ?? 21.028511;
          longitude = auth.currentUser['officeLng'] ?? 105.804817;

          
        } else {
          latitude = 21.028511;
          longitude = 105.804817;
        }
      }

      // Upload ảnh lên server thật trước
      final uploadService = UploadService();
      String? realImageUrl = await uploadService.uploadFile(selectedImage.value!);
      if (realImageUrl == null) throw "Không thể upload ảnh lên máy chủ";

      // Gọi API Check-in với actionType
      final response = await _service.submitCheckin({
        "latitude": latitude,
        "longitude": longitude,
        "photoUrl": realImageUrl,
        "note": note,
        "actionType": selectedActionType.value,
      });

      // Xử lý phản hồi từ Backend
      if (response['status'] == 'OUT_OF_RANGE') {
        isOutOfRange.value = true;
        Get.snackbar("Thông báo", "Bạn đang ở ngoài phạm vi, vui lòng nhập lý do!");
      } else {
        isOutOfRange.value = false;
        selectedImage.value = null; // Reset ảnh
        
        // Refresh KPI sau khi điểm danh thành công
        if (Get.isRegistered<KpiController>()) {
          Get.find<KpiController>().fetchKpiData();
        }

        Get.snackbar("Thành công",
            selectedActionType.value == 'CHECK_OUT' ? "Check-out thành công!" : "Check-in thành công!");
      }
      
    } catch (e) {
      String errorMessage = "Không thể check-in: $e";
      if (e is DioException && e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          errorMessage = resData['message'];
        }
      }
      Get.snackbar("Lỗi", errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Hàm gửi yêu cầu xét duyệt khi ở ngoài phạm vi
  Future<void> submitApprovalRequest(String reason) async {
    if (selectedImage.value == null) {
      Get.snackbar("Lỗi", "Vui lòng chụp ảnh xác thực trước khi gửi yêu cầu!");
      return;
    }

    try {
      isLoading.value = true;
      
      double latitude = 0.0;
      double longitude = 0.0;

      if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 5));
          
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (gpsErr) {
          print("Lỗi định vị GPS thực tế: $gpsErr. Sử dụng toạ độ mặc định.");
        }
      }

      // Fallback: nếu lỗi/timeout hoặc chạy Desktop, dùng tọa độ lệch ngoài phạm vi (+0.02) để thực hiện gửi yêu cầu duyệt
      if (latitude == 0.0 && longitude == 0.0) {
        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          latitude = (auth.currentUser['officeLat'] ?? 21.028511) + 0.02;
          longitude = (auth.currentUser['officeLng'] ?? 105.804817) + 0.02;
        } else {
          latitude = 21.028511 + 0.02;
          longitude = 105.804817 + 0.02;
        }
      }
      
      // Upload ảnh lên server thật trước
      final uploadService = UploadService();
      String? realImageUrl = await uploadService.uploadFile(selectedImage.value!);
      if (realImageUrl == null) throw "Không thể upload ảnh lên máy chủ";

      await _service.submitApproval({
        "note": reason,
        "photoUrl": realImageUrl,
        "latitude": latitude,
        "longitude": longitude,
        "actionType": selectedActionType.value,
      });

      // Refresh KPI sau khi gửi duyệt thành công (để đồng bộ nếu backend auto duyệt)
      if (Get.isRegistered<KpiController>()) {
        Get.find<KpiController>().fetchKpiData();
      }

      isOutOfRange.value = false; 
      selectedImage.value = null; // Reset ảnh
      Get.snackbar("Thành công", "Đã gửi yêu cầu cho Admin duyệt!");
      
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể gửi yêu cầu: $e");
    } finally {
      isLoading.value = false;
    }
  }
}