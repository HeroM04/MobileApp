import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:kpi_mobile/data/services/checkin_service.dart';
import 'package:kpi_mobile/data/services/upload_service.dart';
import 'package:kpi_mobile/data/services/lich_su_thang.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../../../core/widgets/thong_bao.dart';
import '../../../core/utils/quyen_anh.dart';
import '../../../core/utils/thu_nho_anh.dart';
import '../../../core/utils/dong_dau_anh.dart';

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

  /// Cả tháng ('yyyy-MM'), xếp sớm → muộn — tab Lịch sử chế độ "Theo tháng".
  Future<List<Map<String, dynamic>>> fetchHistoryMonth(String month) =>
      taiLichSuThang('/attendance/my-checkins', month);
  
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
          snack("Lỗi xác thực", "Không tìm thấy khuôn mặt! Vui lòng chụp rõ mặt bạn.",
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
        if (position.isMocked) {
          isLoading.value = false;
          _baoViTriGia();
          return;
        }

        // 3. Trong / ngoài phạm vi văn phòng (tọa độ + bán kính lấy theo phòng ban).
        //    Lấy cấu hình MỚI từ máy chủ trước: Admin đổi bán kính trên web thì
        //    phải có tác dụng ngay, không phải chờ nhân viên đăng xuất đăng nhập lại.
        //    GPS lần đầu lệch nhiều (dưới hầm xe...) thì đọc lại vài giây — xem _xetPhamVi.
        await _taiCauHinhVanPhong();
        final xet = await _xetPhamVi(position, _getOfficeConfig().radius);
        if (xet == null) {
          isLoading.value = false;
          return;
        }
        currentLat = xet.viTri.latitude;
        currentLng = xet.viTri.longitude;
        // Không hiện khoảng cách hay tọa độ công ty cho nhân viên — chỉ báo kết
        // quả chấm công. Số liệu GPS máy chủ vẫn ghi đầy đủ để Admin đối chiếu.

        // 4. Reverse Geocoding theo vị trí cuối cùng
        currentAddress = await _getAddressFromCoordinates(currentLat, currentLng);

        // 5. Vẽ Watermark (Time + Address)
        File watermarkedFile = await _addWatermark(imageFile, currentAddress);
        selectedImage.value = watermarkedFile;

        if (xet.ngoai) {
          isOutOfRange.value = true;
          // UI sẽ tự hiện popup nhập Note nhờ isOutOfRange.value = true
        } else {
          isOutOfRange.value = false;
          // Tự động Check-in luôn nếu khoảng cách <= bán kính
          await performCheckin(""); 
        }
      }
    } catch (e) {
      if (await xuLyLoiQuyenAnh(e)) return;
      snack("Lỗi", "Không thể lấy hình ảnh: $e");
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
      snack("Lỗi", "Hãy bật định vị GPS trên điện thoại!");
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        snack("Lỗi", "Bạn cần cấp quyền vị trí cho ứng dụng!");
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      snack("Lỗi", "Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.");
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

  /// Đóng dấu giờ + địa chỉ lên ảnh chấm công.
  Future<File> _addWatermark(File originalFile, String address) async {
    try {
      final bytes = await originalFile.readAsBytes();
      img.Image? goc = img.decodeImage(bytes);
      if (goc == null) return originalFile;
      // Thu nhỏ TRƯỚC khi đóng dấu: làm sau thì trên ảnh gốc 4000 px chữ bé tí,
      // thu nhỏ xong còn mờ hơn. Nhận diện khuôn mặt đã chạy trên ảnh gốc ở
      // bước trước nên không bị ảnh hưởng.
      // Tách phần mở rộng đúng cách (_writeJpg) — trước đây thay chuỗi '.jpg'
      // cứng, gặp .jpeg hay .png là ghi đè luôn lên ảnh gốc.
      final daThuNho = await _writeJpg(thuNhoAnh(goc), originalFile, 'nho');
      // Vẽ chữ bằng Flutter để đủ dấu tiếng Việt (xem dongDauChamCong)
      return await dongDauChamCong(daThuNho, diaChi: address);
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

  /// Tải hồ sơ MỚI NHẤT (phòng ban → tọa độ + bán kính) từ máy chủ trước khi
  /// đo khoảng cách. Máy chủ không trả lời kịp (3 giây) thì giữ bản cũ — chấm
  /// công không được kẹt vì việc này, và máy chủ vẫn tự kiểm lại bằng số liệu
  /// của nó.
  Future<void> _taiCauHinhVanPhong() async {
    if (!Get.isRegistered<AuthController>()) return;
    await Get.find<AuthController>().dongBoHoSo(choToiDa: const Duration(seconds: 3));
  }

  double _calculateDistanceToOffice(double lat, double lng) {
    final office = _getOfficeConfig();
    return Geolocator.distanceBetween(lat, lng, office.lat, office.lng);
  }

  // ── GPS lệch ──────────────────────────────────────────────────────────────

  /// Sai số GPS (mét) đủ tin để kết luận "ngoài phạm vi" ngay, không đọc lại.
  static const double saiSoTin = 50;

  /// Đọc lại GPS tối đa bao lâu khi lần đầu lệch nhiều.
  static const Duration choDocLaiGps = Duration(seconds: 10);

  /// Dòng nhắc trong hộp nhập lý do khi bị báo ngoài phạm vi; rỗng = không nhắc.
  var goiYViTri = ''.obs;

  /// Máy chỉ cấp vị trí gần đúng cho app (tắt "Vị trí chính xác") → nút mở Cài đặt.
  var viTriGanDung = false.obs;

  void _baoViTriGia() {
    snack("Cảnh báo bảo mật", "Phát hiện phần mềm giả mạo vị trí (Fake GPS). Hành động bị từ chối!",
        backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
  }

  /// Mở trang Cài đặt của app để bật lại "Vị trí chính xác".
  Future<void> moCaiDatViTri() => Geolocator.openAppSettings();

  /// Xét trong / ngoài phạm vi văn phòng.
  ///
  /// Lần đọc đầu ngoài phạm vi mà sai số lớn — dưới hầm xe, trong nhà, điện
  /// thoại chưa bắt được vệ tinh nên đoán theo cột sóng / wifi, lệch cả km —
  /// thì đọc GPS thêm tối đa [choDocLaiGps], lấy lần chính xác nhất rồi mới
  /// kết luận. Người trong phạm vi hoặc GPS đã tốt thì không phải chờ thêm.
  /// Vẫn ngoài phạm vi thì để sẵn dòng nhắc [goiYViTri].
  ///
  /// Trả về null nếu lần đọc lại phát hiện vị trí giả (đã báo người dùng).
  Future<({Position viTri, bool ngoai})?> _xetPhamVi(Position dau, double banKinh) async {
    goiYViTri.value = '';
    viTriGanDung.value = false;
    bool ngoai(Position p) => _calculateDistanceToOffice(p.latitude, p.longitude) > banKinh;

    var viTri = dau;
    if (ngoai(viTri) && viTri.accuracy > saiSoTin) {
      try {
        viTri = await chonViTriTotNhat(viTri, Geolocator.getPositionStream(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.best)));
      } catch (e) {
        print("Lỗi đọc lại GPS: $e");
      }
      if (viTri.isMocked) {
        _baoViTriGia();
        return null;
      }
    }

    final laNgoai = ngoai(viTri);
    if (laNgoai) {
      var ganDung = false;
      try {
        ganDung = await Geolocator.getLocationAccuracy() == LocationAccuracyStatus.reduced;
      } catch (_) {}
      viTriGanDung.value = ganDung;
      goiYViTri.value = goiYNgoaiPhamVi(ganDung: ganDung, saiSo: viTri.accuracy);
    }
    return (viTri: viTri, ngoai: laNgoai);
  }

  /// Đọc thêm từ [doc], giữ lần có sai số nhỏ nhất. Dừng khi sai số ≤ [saiSoDu],
  /// khi hết [cho], hoặc khi gặp lần đọc giả mạo (trả luôn lần đó để chặn).
  static Future<Position> chonViTriTotNhat(Position dau, Stream<Position> doc,
      {Duration cho = choDocLaiGps, double saiSoDu = saiSoTin}) async {
    var tot = dau;
    final het = DateTime.now().add(cho);
    try {
      await for (final p in doc.timeout(cho)) {
        if (p.isMocked) return p;
        if (p.accuracy < tot.accuracy) tot = p;
        if (tot.accuracy <= saiSoDu || !DateTime.now().isBefore(het)) break;
      }
    } on TimeoutException {
      // Không có lần đọc mới trong thời gian chờ — giữ lần tốt nhất đã có
    }
    return tot;
  }

  /// Câu nhắc khi vẫn bị báo ngoài phạm vi. Chỉ nói khi có lý do để nghi GPS sai.
  static String goiYNgoaiPhamVi({required bool ganDung, required double saiSo}) {
    if (ganDung) {
      return 'Điện thoại đang tắt "Vị trí chính xác" cho app nên vị trí có thể lệch vài km. '
          'Nếu bạn đang ở công ty, bật lại rồi chụp lại.';
    }
    if (saiSo > saiSoTin) {
      return 'Tín hiệu GPS đang yếu (sai số khoảng ${saiSo.round()} m). '
          'Nếu bạn đang ở công ty, ra chỗ thoáng rồi chụp lại.';
    }
    return '';
  }

  /// Xử lý lấy toạ độ và Check-out không cần chụp ảnh
  Future<void> handleCheckOut(String note) async {
    try {
      isLoading.value = true;
      Position? position = await _getCurrentLocation();
      if (position == null) { isLoading.value = false; return; }
      
      if (position.isMocked) {
        isLoading.value = false;
        _baoViTriGia();
        return;
      }

      // Trước đây so với 2000m ghi cứng, còn check-in so với bán kính phòng ban —
      // hai cửa hai luật. Giờ cùng một bán kính, cùng cách đọc lại GPS khi lệch.
      await _taiCauHinhVanPhong();
      final xet = await _xetPhamVi(position, _getOfficeConfig().radius);
      if (xet == null) { isLoading.value = false; return; }
      currentLat = xet.viTri.latitude;
      currentLng = xet.viTri.longitude;
      currentAddress = await _getAddressFromCoordinates(currentLat, currentLng);

      if (xet.ngoai) {
        isOutOfRange.value = true;
        isLoading.value = false;
      } else {
        isOutOfRange.value = false;
        await performCheckin(note);
      }
    } catch (e) {
      snack("Lỗi", "Lỗi GPS: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
      isLoading.value = false;
    }
  }

  /// Gửi dữ liệu lên API
  Future<void> performCheckin(String note) async {
    if (selectedImage.value == null) {
      snack("Lỗi", "Chưa có ảnh chân dung hợp lệ!");
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
      snack("Thành công", successMsg, backgroundColor: Colors.green, colorText: Colors.white);
      
    } catch (e) {
      String errorMessage = "Không thể thực hiện: $e";
      if (e is DioException && e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          errorMessage = resData['message'];
        }
      }
      snack("Lỗi", errorMessage, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitApprovalRequest(String reason) async {
    await performCheckin(reason);
  }
}