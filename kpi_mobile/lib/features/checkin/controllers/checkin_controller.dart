import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'dart:math' as math;
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
  var selectedActionType = 'CHECK_IN'.obs; 

  // Tọa độ đã quét để tránh quét lại nếu bị outOfRange
  double currentLat = 0.0;
  double currentLng = 0.0;
  String currentAddress = "";

  final ImagePicker _picker = ImagePicker();
  final CheckinService _service = CheckinService();

  int get currentUserId {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      return auth.currentUser['userId'] ?? 1;
    }
    return 1;
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
  
  /// Bước 1: Gọi hàm chụp ảnh (Chỉ Camera)
  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        // Chấm công là chụp ảnh chính mình nên mở thẳng camera trước.
        // Thiếu tham số này máy sẽ mở camera sau như mặc định của hệ thống.
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      ).timeout(const Duration(seconds: 30));

      if (photo != null) {
        isLoading.value = true;
        // Xoay ảnh về đúng chiều trước khi làm gì khác. Ảnh camera trước hay bị
        // ghi kèm thẻ xoay trong EXIF thay vì xoay thật pixel; khi image_picker
        // nén lại (imageQuality) thẻ đó rơi mất, ảnh thành nằm ngang và ML Kit
        // không nhận ra khuôn mặt — đúng triệu chứng cam sau chụp được mà cam
        // trước thì báo không thấy người.
        File imageFile = await _normalizeOrientation(File(photo.path));

        // 1. Google ML Kit Face Detection (Offline)
        final faceResult = await _detectFace(imageFile);
        if (!faceResult.hasFace) {
          isLoading.value = false;
          Get.snackbar("Lỗi xác thực", "Không tìm thấy khuôn mặt! Vui lòng chụp rõ mặt bạn.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
          return;
        }
        // Nếu phải xoay thêm mới thấy mặt thì giữ luôn ảnh đã xoay, để ảnh gửi
        // lên cho Admin duyệt cũng đúng chiều.
        if (faceResult.correctedFile != null) imageFile = faceResult.correctedFile!;

        // 2. Lấy GPS & Check Fake Location
        Position? position = await _getCurrentLocation();
        if (position == null) {
          isLoading.value = false;
          return; // Lỗi đã được show trong _getCurrentLocation
        }
        currentLat = position.latitude;
        currentLng = position.longitude;

        if (position.isMocked) {
          isLoading.value = false;
          Get.snackbar("Cảnh báo bảo mật", "Phát hiện phần mềm giả mạo vị trí (Fake GPS). Hành động bị từ chối!", 
            backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 5));
          return;
        }

        // 3. Reverse Geocoding
        currentAddress = await _getAddressFromCoordinates(currentLat, currentLng);

        // 4. Vẽ Watermark (Time + Address)
        File watermarkedFile = await _addWatermark(imageFile, currentAddress);
        selectedImage.value = watermarkedFile;

        // 5. Tính khoảng cách tới văn phòng (tọa độ + bán kính lấy theo phòng ban)
        final office = _getOfficeConfig();
        double distance = _calculateDistanceToOffice(currentLat, currentLng);

        Get.snackbar(
          "Thông tin GPS Chi Tiết",
          "Cách cty: ${distance.toStringAsFixed(0)}m (cho phép ${office.radius.toStringAsFixed(0)}m)."
          "\nGPS Bạn: $currentLat, $currentLng"
          "\nGPS Cty: ${office.lat}, ${office.lng}",
          duration: const Duration(seconds: 8),
        );

        if (distance > office.radius) {
          isOutOfRange.value = true;
          // UI sẽ tự hiện popup nhập Note nhờ isOutOfRange.value = true
        } else {
          isOutOfRange.value = false;
          // Tự động Check-in luôn nếu khoảng cách <= bán kính
          await performCheckin(""); 
        }
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể lấy hình ảnh: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Xoay ảnh về đúng chiều theo thẻ EXIF, ghi thẳng vào pixel.
  ///
  /// Máy ảnh thường không xoay ảnh thật mà chỉ ghi một thẻ "ảnh này cần xoay
  /// bao nhiêu độ" vào EXIF. Thư viện đọc ảnh nào bỏ qua thẻ đó là thấy ảnh
  /// nằm ngang. Hàm này nướng phép xoay vào pixel nên mọi bước sau — nhận diện
  /// khuôn mặt, đóng dấu, gửi lên máy chủ — đều nhận ảnh đúng chiều.
  Future<File> _normalizeOrientation(File file) async {
    try {
      final decoded = img.decodeImage(await file.readAsBytes());
      if (decoded == null) return file;
      final upright = img.bakeOrientation(decoded);
      return _writeJpg(upright, file, 'upright');
    } catch (e) {
      print("Lỗi xoay ảnh: $e");
      return file;
    }
  }

  /// Ghi ảnh ra file JPEG cạnh file gốc, đặt tên theo hậu tố cho dễ lần.
  Future<File> _writeJpg(img.Image image, File source, String suffix) async {
    final dot = source.path.lastIndexOf('.');
    final base = dot > 0 ? source.path.substring(0, dot) : source.path;
    final out = File('${base}_$suffix.jpg');
    await out.writeAsBytes(img.encodeJpg(image, quality: 85));
    return out;
  }

  Future<bool> _hasFaceIn(File file, FaceDetector detector) async {
    try {
      final faces = await detector.processImage(InputImage.fromFile(file));
      return faces.isNotEmpty;
    } catch (e) {
      print("Lỗi Face Detection: $e");
      return false;
    }
  }

  /// Phát hiện khuôn mặt bằng ML Kit.
  ///
  /// Thử ảnh nguyên trạng trước; không thấy mặt thì xoay lần lượt 90, 180, 270
  /// độ rồi thử lại. Có máy vẫn ghi sai chiều ảnh dù đã nướng EXIF, xoay thử
  /// như vậy tránh chặn oan người chấm công. Vẫn phải thật sự có khuôn mặt mới
  /// qua được, nên không nới lỏng khâu xác thực.
  Future<({bool hasFace, File? correctedFile})> _detectFace(File imageFile) async {
    final faceDetector = FaceDetector(options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
      enableContours: false,
      enableClassification: false,
    ));
    try {
      if (await _hasFaceIn(imageFile, faceDetector)) {
        return (hasFace: true, correctedFile: null);
      }

      final decoded = img.decodeImage(await imageFile.readAsBytes());
      if (decoded == null) return (hasFace: false, correctedFile: null);

      for (final angle in [90, 180, 270]) {
        final rotated = await _writeJpg(
          img.copyRotate(decoded, angle: angle), imageFile, 'rot$angle');
        if (await _hasFaceIn(rotated, faceDetector)) {
          print("Tìm thấy khuôn mặt sau khi xoay $angle độ");
          return (hasFace: true, correctedFile: rotated);
        }
      }
      return (hasFace: false, correctedFile: null);
    } finally {
      faceDetector.close();
    }
  }

  /// Lấy GPS
  Future<Position?> _getCurrentLocation() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return null;
    }
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Lỗi", "Hãy bật định vị GPS trên điện thoại!");
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Lỗi", "Bạn cần cấp quyền vị trí cho ứng dụng!");
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Lỗi", "Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.");
      return null;
    }
    return await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  /// Reverse Geocoding
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}";
        return address.replaceAll(RegExp(r'^,\s*'), ''); // Xóa dấu phẩy thừa ở đầu
      }
    } catch (e) {
      print("Lỗi Geocoding: $e");
    }
    return "$lat, $lng";
  }

  /// Vẽ Watermark (Sử dụng Image library)
  Future<File> _addWatermark(File originalFile, String address) async {
    try {
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return originalFile;

      String timestamp = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
      String watermarkText = "$timestamp\n$address";

      // Chọn font (dùng font zip mặc định)
      img.BitmapFont font = img.arial24;
      
      // Vẽ viền đen cho chữ để dễ đọc
      img.drawString(image, watermarkText, font: font, x: 21, y: image.height - 80 + 1, color: img.ColorRgb8(0, 0, 0));
      img.drawString(image, watermarkText, font: font, x: 19, y: image.height - 80 - 1, color: img.ColorRgb8(0, 0, 0));
      // Vẽ chữ trắng
      img.drawString(image, watermarkText, font: font, x: 20, y: image.height - 80, color: img.ColorRgb8(255, 255, 255));

      // Tách phần mở rộng đúng cách. Trước đây thay chuỗi '.jpg' cứng, gặp file
      // .jpeg hay .png là không đổi được tên nên ghi đè luôn lên ảnh gốc.
      return _writeJpg(image, originalFile, 'watermarked');
    } catch (e) {
      print("Lỗi tạo Watermark: $e");
      return originalFile; // Nếu lỗi, dùng ảnh gốc
    }
  }

  /// Tính khoảng cách bằng công thức Haversine trên Mobile
  // ── Cấu hình văn phòng ────────────────────────────────────────────────────
  // Giá trị mặc định chỉ dùng khi máy chủ chưa trả về (tránh chặn chấm công).
  static const double _defaultOfficeLat = 20.999042;
  static const double _defaultOfficeLng = 105.806702;
  static const double _defaultRadius = 2000;

  /// Lấy tọa độ + bán kính văn phòng từ thông tin đăng nhập.
  ///
  /// Backend trả các giá trị này theo phòng ban của nhân viên, nên khi công ty
  /// đổi địa điểm chỉ cần sửa trên Web Admin — KHÔNG phải cập nhật lại app.
  ({double lat, double lng, double radius}) _getOfficeConfig() {
    double lat = _defaultOfficeLat;
    double lng = _defaultOfficeLng;
    double radius = _defaultRadius;

    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().currentUser;
      final srvLat = (user['officeLat'] as num?)?.toDouble();
      final srvLng = (user['officeLng'] as num?)?.toDouble();
      final srvRadius = (user['allowedRadius'] as num?)?.toDouble();

      // Chỉ dùng khi máy chủ có dữ liệu thật (khác null và khác 0)
      if (srvLat != null && srvLng != null && srvLat != 0 && srvLng != 0) {
        lat = srvLat;
        lng = srvLng;
      }
      if (srvRadius != null && srvRadius > 0) {
        radius = srvRadius;
      }
    }

    return (lat: lat, lng: lng, radius: radius);
  }

  double _calculateDistanceToOffice(double lat, double lng) {
    final office = _getOfficeConfig();
    return Geolocator.distanceBetween(lat, lng, office.lat, office.lng);
  }

  /// Xử lý lấy toạ độ và Check-out không cần chụp ảnh
  Future<void> handleCheckOut(String note) async {
    try {
      isLoading.value = true;
      Position? position = await _getCurrentLocation();
      if (position == null) { isLoading.value = false; return; }
      
      currentLat = position.latitude;
      currentLng = position.longitude;
      
      if (position.isMocked) {
        isLoading.value = false;
        Get.snackbar("Cảnh báo", "Phát hiện Fake GPS.", backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }

      currentAddress = await _getAddressFromCoordinates(currentLat, currentLng);
      double distance = _calculateDistanceToOffice(currentLat, currentLng);
      
      Get.snackbar("GPS", "Cách công ty: ${distance.toStringAsFixed(0)}m");

      if (distance > 2000) {
        isOutOfRange.value = true;
        isLoading.value = false;
      } else {
        isOutOfRange.value = false;
        await performCheckin(note);
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Lỗi GPS: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
      isLoading.value = false;
    }
  }

  /// Gửi dữ liệu lên API
  Future<void> performCheckin(String note) async {
    if (selectedImage.value == null) {
      Get.snackbar("Lỗi", "Chưa có ảnh chân dung hợp lệ!");
      return;
    }

    try {
      isLoading.value = true;
      String? realImageUrl = "";

      // Nếu có ảnh (Check-in), thì upload
      if (selectedImage.value != null) {
        final uploadService = UploadService();
        realImageUrl = await uploadService.uploadFile(selectedImage.value!);
        if (realImageUrl == null) throw "Không thể upload ảnh lên máy chủ";
      }

      final response = await _service.submitCheckin({
        "latitude": currentLat,
        "longitude": currentLng,
        "address": currentAddress,
        "photoUrl": realImageUrl,
        "note": note,
        "actionType": selectedActionType.value,
      });

      isOutOfRange.value = false;
      selectedImage.value = null; 
      
      if (Get.isRegistered<KpiController>()) {
        Get.find<KpiController>().fetchKpiData();
      }

      String successMsg = selectedActionType.value == 'CHECK_OUT' ? "Check-out thành công!" : "Check-in thành công!";
      if (response != null && response['data'] != null) {
         if (response['data']['status'] == 'PENDING') {
           successMsg += " Yêu cầu đang chờ duyệt.";
         }
      }
      Get.snackbar("Thành công", successMsg, backgroundColor: Colors.green, colorText: Colors.white);
      
    } catch (e) {
      String errorMessage = "Không thể thực hiện: $e";
      if (e is DioException && e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          errorMessage = resData['message'];
        }
      }
      Get.snackbar("Lỗi", errorMessage, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitApprovalRequest(String reason) async {
    await performCheckin(reason);
  }
}