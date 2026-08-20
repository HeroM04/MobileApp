import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  var currentAddress = ''.obs;
  var currentLat = 0.0;
  var currentLng = 0.0;


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
  bool _checkInFlight = false;

  void _startAutoSyncTimer() {
    // 60 giây một lượt. Trước để 15 giây, mà một lượt dò có thể kéo dài cả phút
    // khi máy chủ đang ngủ dậy, nên các lượt chồng lên nhau.
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (_checkInFlight) return;
      _checkInFlight = true;
      try {
        await checkNetworkAndSync();
      } finally {
        _checkInFlight = false;
      }
    });
  }

  /// Máy chủ chạy trên gói Render miễn phí nên tự ngủ khi không có ai dùng, lần
  /// gọi đầu tiên phải chờ nó thức dậy — thường 30 đến 60 giây. Mọi mốc chờ ở
  /// đây phải rộng hơn khoảng đó, nếu không máy sẽ tưởng là mất mạng.
  static const Duration _wakeUpAllowance = Duration(seconds: 90);

  /// Kiểm tra máy chủ có trả lời không. Chỉ dùng cho bộ đồng bộ nền, KHÔNG dùng
  /// để chặn người dùng gửi báo cáo.
  Future<bool> _testServerConnection() async {
    if (ApiClient.isDebugMode) {
      return true;
    }
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: _wakeUpAllowance,
        receiveTimeout: _wakeUpAllowance,
      ));
      // Dùng đúng endpoint /auth/ping đã được khai báo trong Backend (không cần token)
      final response = await dio.get('${ApiClient.baseUrl}/auth/ping');
      // Bất kỳ phản hồi nào từ server (200, 401, 404...) = CÓ MẠNG
      return response.statusCode != null;
    } catch (e) {
      if (e is DioException && e.response != null) {
        // Server trả về mã lỗi HTTP vẫn = CÓ MẠNG
        return true;
      }
      // Timeout / SocketException = OFFLINE thật sự
      print('[ThucChien] Ping thất bại: $e');
      return false;
    }
  }

  /// Có đúng là hỏng đường truyền không, hay máy chủ đã trả lời nhưng báo lỗi.
  ///
  /// Phân biệt hai loại này mới ra thông báo đúng: hỏng mạng thì lưu nháp gửi
  /// lại sau, còn máy chủ từ chối thì nói thẳng lý do chứ đừng đổ cho mạng.
  bool _isOfflineError(Object e) {
    if (e is SocketException) return true;
    if (e is DioException) {
      if (e.response != null) return false; // máy chủ có trả lời
      return e.type == DioExceptionType.connectionError
          || e.type == DioExceptionType.connectionTimeout
          || e.type == DioExceptionType.sendTimeout
          || e.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  /// Lấy câu giải thích của máy chủ, không có thì mô tả ngắn gọn lỗi.
  String _describeError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      final code = e.response?.statusCode;
      if (code != null) return 'Máy chủ báo lỗi $code';
    }
    return e.toString();
  }

  // Thực hiện kiểm tra và đồng bộ
  Future<void> checkNetworkAndSync() async {
    final connected = await _testServerConnection();
    hasConnection.value = connected;

    if (connected && offlineDrafts.isNotEmpty && !isSyncing.value) {
      await autoSyncDrafts();
    }
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  // Public method để View có thể gọi lấy GPS & địa chỉ
  Future<void> getCurrentLocationAndAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      currentLat = position.latitude;
      currentLng = position.longitude;

      // Reverse geocoding: tọa độ -> tên đường phố
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) p.subAdministrativeArea,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea,
        ];
        currentAddress.value = parts.join(', ');
      }
    } catch (e) {
      print('[ThucChien] Lỗi lấy GPS: $e');
    }
  }

  // ── OPTIMISTIC UI ─────────────────────────────────────────────────────────
  // Phản hồi người dùng NGAY LẬP TỨC (< 1s), sau đó xử lý API ngầm phía sau.
  Future<void> submitMeetingOptimistic({
    required String name,
    required String phone,
    required String project,
    required String content,
    required String imagePath,
    required VoidCallback onSuccess,   // Callback reset form ngay khi ấn nút
  }) async {
    // Lấy GPS và địa chỉ TRƯỚC khi submit
    await getCurrentLocationAndAddress();

    // BƯỚC 1: Phản hồi ngay cho người dùng (< 200ms)
    onSuccess();
    Get.snackbar(
      "Đang ghi nhận...",
      "Báo cáo đang được xử lý và gửi lên hệ thống...",
      backgroundColor: const Color(0xFF0F2C59),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
      margin: const EdgeInsets.all(12),
    );

    // BƯỚC 2: Xử lý upload + gọi API ngầm (không block UI)
    _processInBackground(
        name: name,
        phone: phone,
        project: project,
        content: content,
        imagePath: imagePath,
      );
  }

  // Hàm xử lý ngầm - không await ở UI
  void _processInBackground({
    required String name,
    required String phone,
    required String project,
    required String content,
    required String imagePath,
  }) async {
    // Không ping thử trước nữa. Trước đây có một lượt ping chờ tối đa 8 giây để
    // quyết định còn mạng hay không; máy chủ Render vừa ngủ dậy mất tới cả phút
    // nên lượt ping đó gần như luôn quá hạn, và báo cáo bị đẩy vào nháp kèm
    // thông báo mất mạng dù máy vẫn đầy sóng. Nay gửi thẳng, hỏng thật thì mới
    // rơi vào nhánh xử lý lỗi bên dưới.
    try {
      // Upload ảnh
      final uploadService = UploadService();
      String? realImageUrl;
      if (imagePath.isNotEmpty) {
        realImageUrl = await uploadService.uploadFile(File(imagePath));
        if (realImageUrl == null) throw "Không thể upload ảnh";
      }

      // Gọi API
      final thucChienService = ThucChienService();
      await thucChienService.submitBattle({
        'customerName': name,
        'customerPhone': phone,
        'project': project,
        'content': content,
        'photoUrl': realImageUrl ?? "",
        'location': currentAddress.value.isNotEmpty ? currentAddress.value : 'Không xác định',
        'latitude': currentLat,
        'longitude': currentLng,
      });

      kpiController.fetchKpiData();
      hasConnection.value = true;

      // Thông báo nhỏ xác nhận hoàn tất (không block màn hình)
      Get.snackbar(
        "☁️ Đồng bộ thành công",
        "Báo cáo gặp khách hàng đã được lưu vào hệ thống!",
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      print('[ThucChien] Gửi báo cáo thất bại: $e');

      if (_isOfflineError(e)) {
        // Hỏng đường truyền thật — giữ lại để gửi khi có mạng
        hasConnection.value = false;
        offlineDrafts.add({
          'name': name, 'phone': phone,
          'project': project, 'content': content, 'image': imagePath,
        });
        Get.snackbar(
          "📶 Đã lưu nháp",
          "Không gửi được do mạng. Báo cáo sẽ tự động gửi lại khi có kết nối.",
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Máy chủ có trả lời nhưng từ chối — nói đúng lý do, đừng đổ cho mạng.
      // Lỗi phía máy chủ (5xx) thì giữ nháp vì gửi lại có thể thành công;
      // lỗi do dữ liệu (4xx) thì gửi lại cũng vậy nên không giữ.
      final status = e is DioException ? (e.response?.statusCode ?? 0) : 0;
      final serverFault = status >= 500 || status == 0;
      if (serverFault) {
        offlineDrafts.add({
          'name': name, 'phone': phone,
          'project': project, 'content': content, 'image': imagePath,
        });
      }
      Get.snackbar(
        serverFault ? "Máy chủ đang bận" : "Không gửi được báo cáo",
        serverFault
            ? "${_describeError(e)}. Đã lưu nháp, hệ thống sẽ thử gửi lại."
            : _describeError(e),
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
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
