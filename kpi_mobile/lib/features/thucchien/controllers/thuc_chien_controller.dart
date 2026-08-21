import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
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

  /// Dừng bộ dò mạng. Gọi khi app lui vào nền để sóng điện thoại được ngủ.
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Bật lại bộ dò mạng khi người dùng mở lại app.
  void startAutoSync() {
    if (_syncTimer != null) return;
    _startAutoSyncTimer();
  }

  void _startAutoSyncTimer() {
    // Chỉ dò khi còn báo cáo chưa gửi được. Trước đây cứ 15 giây lại gọi máy chủ
    // một lần bất kể có nháp hay không, chạy suốt cả ngày — vừa tốn pin vừa vô
    // ích vì đa số thời gian không có gì để gửi.
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (_checkInFlight) return;
      if (offlineDrafts.isEmpty) return; // không có nháp thì không cần dò mạng
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
      final failure = describeApiFailure(e);

      if (failure.kind == ApiFailureKind.network) hasConnection.value = false;

      // Lỗi mạng hoặc lỗi máy chủ thì giữ nháp vì gửi lại có thể thành công.
      // Lỗi do dữ liệu nhập sai thì gửi lại cũng hỏng như vậy nên không giữ,
      // báo thẳng để nhân viên sửa rồi gửi lại.
      if (failure.worthRetrying) {
        offlineDrafts.add({
          'name': name, 'phone': phone,
          'project': project, 'content': content, 'image': imagePath,
        });
      }

      Get.snackbar(
        failure.worthRetrying ? "${failure.title} — đã lưu nháp" : failure.title,
        failure.worthRetrying
            ? "${failure.message}\nBáo cáo đã được giữ lại và sẽ tự gửi lại."
            : failure.message,
        backgroundColor: failure.isUserFixable ? Colors.orange.shade800 : Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    }
  }


  // Tự động đồng bộ toàn bộ bản nháp lên server
  Future<void> autoSyncDrafts() async {
    isSyncing.value = true;
    final draftsToSync = List<Map<String, String>>.from(offlineDrafts);
    final daGui = <Map<String, String>>[];
    final thucChienService = ThucChienService();

    for (var draft in draftsToSync) {
      try {
        // Tải ảnh kèm theo nếu tệp còn nằm trên máy. Ảnh chụp lưu ở thư mục tạm,
        // máy dọn dẹp hoặc khởi động lại là mất; khi đó vẫn gửi báo cáo nhưng
        // không kèm ảnh, còn hơn để bản nháp kẹt lại vĩnh viễn.
        String? realImageUrl;
        final duongDanAnh = draft['image'];
        if (duongDanAnh != null && duongDanAnh.isNotEmpty && await File(duongDanAnh).exists()) {
          try {
            realImageUrl = await UploadService().uploadFile(File(duongDanAnh));
          } catch (e) {
            print('Không tải được ảnh của bản nháp, gửi báo cáo không kèm ảnh: $e');
          }
        }

        await thucChienService.submitBattle({
          'customerName': draft['name'],
          'customerPhone': draft['phone'],
          'project': draft['project'],
          'content': draft['content'],
          'photoUrl': realImageUrl ?? "",
        });

        daGui.add(draft);
      } catch (e) {
        print("Lỗi đồng bộ bản nháp: $e");
        // Giữ lại để thử gửi lần sau
      }
    }

    // Chỉ xoá đúng những bản đã gửi được.
    //
    // Trước đây dùng removeRange(0, số_bản_thành_công) — xoá mấy bản ĐẦU danh
    // sách chứ không phải mấy bản thật sự gửi được. Nếu bản thứ nhất hỏng còn
    // bản thứ hai gửi xong thì nó xoá mất bản hỏng (mất báo cáo) và giữ lại bản
    // đã gửi (lần sau gửi lại lần nữa, thành hai bản ghi trùng).
    for (final d in daGui) {
      offlineDrafts.remove(d);
    }

    if (daGui.isNotEmpty) {
      kpiController.fetchKpiData();
      Get.snackbar(
        "Tự động đồng bộ",
        "Đã gửi được ${daGui.length} báo cáo thực chiến đang chờ.",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
    isSyncing.value = false;
  }

  /// Xoá toàn bộ bản nháp đang treo.
  ///
  /// Cần có lối thoát cho người dùng: nếu một bản nháp không thể gửi được nữa
  /// (ví dụ dữ liệu bị máy chủ từ chối), nó sẽ nằm lại mãi và dải báo "Đang lưu
  /// ngoại tuyến" hiện hoài dù mọi thứ khác vẫn bình thường.
  void xoaTatCaNhap() {
    final n = offlineDrafts.length;
    offlineDrafts.clear();
    Get.snackbar(
      "Đã xoá bản nháp",
      "Đã bỏ $n báo cáo đang chờ gửi.",
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
    );
  }
}
