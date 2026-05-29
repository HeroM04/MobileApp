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
        imageQuality: 70,
      ).timeout(const Duration(seconds: 30));
      
      if (photo != null) {
        isLoading.value = true;
        File imageFile = File(photo.path);
        
        // 1. Google ML Kit Face Detection (Offline)
        bool hasFace = await _detectFace(imageFile);
        if (!hasFace) {
          isLoading.value = false;
          Get.snackbar("Lỗi xác thực", "Không tìm thấy khuôn mặt! Vui lòng chụp rõ mặt bạn.", 
            backgroundColor: Colors.redAccent, colorText: Colors.white);
          return;
        }

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

        // 5. Tính toán khoảng cách (Haversine)
        int allowedRadius = 2000;
        
        double distance = _calculateDistanceToOffice(currentLat, currentLng);
        
        // Debug cho người dùng thấy khoảng cách thực tế
        double officeLat = 20.999042;
        double officeLng = 105.806702;

        Get.snackbar(
          "Thông tin GPS Chi Tiết", 
          "Cách cty: ${distance.toStringAsFixed(0)}m.\nGPS Bạn: $currentLat, $currentLng\nGPS Cty: $officeLat, $officeLng",
          duration: const Duration(seconds: 8),
        );

        if (distance > allowedRadius) {
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

  /// Phát hiện khuôn mặt bằng ML Kit
  Future<bool> _detectFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
    ));
    try {
      final faces = await faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      print("Lỗi Face Detection: $e");
      return false; // Nếu lỗi ML kit (vd emulator ko hỗ trợ) thì vẫn chặn hoặc cho phép tuỳ business. Ở đây chặn.
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

      final watermarkedBytes = img.encodeJpg(image, quality: 80);
      final newPath = originalFile.path.replaceAll('.jpg', '_watermarked.jpg');
      final newFile = File(newPath);
      await newFile.writeAsBytes(watermarkedBytes);
      return newFile;
    } catch (e) {
      print("Lỗi tạo Watermark: $e");
      return originalFile; // Nếu lỗi, dùng ảnh gốc
    }
  }

  /// Tính khoảng cách bằng công thức Haversine trên Mobile
  double _calculateDistanceToOffice(double lat, double lng) {
    double officeLat = 20.999042;
    double officeLng = 105.806702;
    double distance = Geolocator.distanceBetween(lat, lng, officeLat, officeLng);
    return distance;
  }

  /// Gửi dữ liệu lên API
  Future<void> performCheckin(String note) async {
    if (selectedImage.value == null) {
      Get.snackbar("Lỗi", "Chưa có ảnh chân dung hợp lệ!");
      return;
    }

    try {
      isLoading.value = true;

      // Upload Cloudinary
      final uploadService = UploadService();
      String? realImageUrl = await uploadService.uploadFile(selectedImage.value!);
      if (realImageUrl == null) throw "Không thể upload ảnh lên máy chủ";

      // Gọi API Check-in. Backend sẽ tự động quyết định là APPROVED hay PENDING.
      final response = await _service.submitCheckin({
        "latitude": currentLat,
        "longitude": currentLng,
        "address": currentAddress,
        "photoUrl": realImageUrl,
        "note": note,
        "actionType": selectedActionType.value,
      });

      // Reset state
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
      String errorMessage = "Không thể check-in: $e";
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

  // Loại bỏ hàm submitApprovalRequest riêng lẻ vì Backend chỉ cần 1 endpoint submitCheckin
  Future<void> submitApprovalRequest(String reason) async {
    await performCheckin(reason);
  }
}