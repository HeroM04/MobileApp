import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/shell/controllers/shell_controller.dart';
import '../../features/thongbao/controllers/thong_bao_controller.dart';

/// Xử lý thông báo đẩy Firebase khi ứng dụng đang chạy nền hoặc đã đóng.
///
/// Phải là hàm top-level và có @pragma để iOS/Android gọi được từ một luồng
/// riêng, không dính vào widget nào.
@pragma('vm:entry-point')
Future<void> _xuLyNen(RemoteMessage message) async {
  // Không cần làm gì ở đây: hệ điều hành đã tự hiện thông báo lên màn hình.
  // Chỉ cần có hàm này để đăng ký thì thông báo nền mới hoạt động.
}

/// Kết nối ứng dụng với dịch vụ thông báo đẩy.
///
/// Thông báo đẩy hiện thẳng trên màn hình điện thoại kể cả khi nhân sự không mở
/// app — khác với mục Thông báo trong app vốn chỉ thấy khi đang dùng. Máy chủ
/// gửi khi có buổi đào tạo mới, đơn xin vắng cần duyệt, hay điểm KPI thay đổi.
class PushService {
  static final PushService _instance = PushService._();
  factory PushService() => _instance;
  PushService._();

  // KHÔNG lấy FirebaseMessaging.instance ngay lúc dựng lớp: nếu Firebase chưa
  // khởi tạo (bản build thiếu GoogleService-Info.plist / google-services.json)
  // thì dòng đó ném [core/no-app] ngay tại chỗ gọi PushService() — tức là ở
  // giữa hàm đăng nhập — và cả việc đăng nhập đổ theo. Thông báo đẩy là phụ,
  // không được làm hỏng đăng nhập. Firebase không có thì mọi việc ở đây bỏ qua.
  FirebaseMessaging? _fcmCache;
  FirebaseMessaging? get _fcm {
    if (_fcmCache != null) return _fcmCache;
    if (Firebase.apps.isEmpty) return null;
    return _fcmCache = FirebaseMessaging.instance;
  }

  /// Firebase có sẵn để dùng không.
  bool get sanSang => _fcm != null;
  final _local = FlutterLocalNotificationsPlugin();

  bool _daKhoiTao = false;

  /// Kênh thông báo Android — bắt buộc từ Android 8 trở lên, không có thì
  /// thông báo lúc app đang mở sẽ không hiện.
  static const _kenh = AndroidNotificationChannel(
    'kpi_default',
    'Thông báo KPI',
    description: 'Đào tạo, duyệt đơn và biến động điểm KPI',
    importance: Importance.high,
  );

  /// Gọi một lần sau khi đăng nhập xong. Xin quyền, lấy mã thiết bị và gửi lên
  /// máy chủ để về sau máy chủ biết đẩy thông báo tới đúng máy này.
  Future<void> khoiDong() async {
    if (!sanSang) {
      if (kDebugMode) print('[Push] Firebase chưa khởi tạo — bỏ qua thông báo đẩy');
      return;
    }
    if (_daKhoiTao) {
      await _guiTokenLenMayChu(); // đăng nhập lại thì gắn token vào tài khoản mới
      return;
    }
    _daKhoiTao = true;

    try {
      // iOS bắt buộc hỏi quyền; Android 13+ cũng hỏi. Người dùng từ chối thì
      // vẫn chạy bình thường, chỉ là không nhận được thông báo đẩy.
      await _fcm!.requestPermission(alert: true, badge: true, sound: true);

      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_kenh);

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (resp) => _moManHinhThongBao(),
      );

      FirebaseMessaging.onBackgroundMessage(_xuLyNen);

      // App đang mở: hệ điều hành không tự hiện, phải tự vẽ để người dùng thấy.
      FirebaseMessaging.onMessage.listen(_hienKhiDangMo);

      // Người dùng bấm vào thông báo để mở app.
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _moManHinhThongBao());

      // Mã thiết bị đổi thì gửi lại ngay.
      _fcm!.onTokenRefresh.listen((token) => _guiToken(token));

      await _guiTokenLenMayChu();
    } catch (e) {
      if (kDebugMode) print('[Push] Khởi động thất bại: $e');
    }
  }

  Future<void> _guiTokenLenMayChu() async {
    try {
      // iOS cần có APNs token trước khi lấy được FCM token.
      final token = await _fcm?.getToken();
      if (token != null) await _guiToken(token);
    } catch (e) {
      if (kDebugMode) print('[Push] Không lấy được token: $e');
    }
  }

  Future<void> _guiToken(String token) async {
    try {
      await ApiClient.dio.post('/devices/register', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      if (kDebugMode) print('[Push] Không gửi được token lên máy chủ: $e');
    }
  }

  void _hienKhiDangMo(RemoteMessage m) {
    // Tin nền "hồ sơ đổi": không hiện gì, chỉ tải lại hồ sơ cho khớp máy chủ.
    if (m.data['type'] == 'HO_SO_DOI') {
      if (Get.isRegistered<AuthController>()) Get.find<AuthController>().dongBoHoSo();
      return;
    }
    final n = m.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kenh.id, _kenh.name,
          channelDescription: _kenh.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    // Cập nhật huy hiệu đỏ trong app luôn cho khớp.
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().capNhatSoThongBao();
    }
  }

  /// Bấm vào thông báo thì mở thẳng mục Thông báo trong app.
  void _moManHinhThongBao() {
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().changeMenuIndex(ShellController.mucThongBao);
    }
    if (Get.isRegistered<ThongBaoController>()) {
      Get.find<ThongBaoController>().tai();
    }
  }

  /// Gỡ mã thiết bị khi đăng xuất, để máy chủ thôi gửi thông báo tới máy này.
  ///
  /// [dio] là Dio do nơi gọi đưa vào — lúc đăng xuất phải dùng Dio KHÔNG có
  /// interceptor, vì token hết hạn thì interceptor sẽ đi làm mới rồi lại gọi
  /// logout, lồng vào chính việc đăng xuất đang dở. Không đưa thì dùng Dio chung.
  ///
  /// Mọi bước đều có giới hạn thời gian: lấy mã FCM có thể treo trên máy không
  /// có dịch vụ Google, còn máy chủ ngủ thì gọi mạng chờ tới cả phút. Đăng xuất
  /// là việc của người dùng, không được để họ đứng chờ vì mấy thứ này.
  Future<void> huyDangKy({Dio? dio}) async {
    try {
      final fcm = _fcm;
      if (fcm == null) return;
      final token = await fcm.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await (dio ?? ApiClient.dio)
            .delete('/devices/register', data: {'token': token})
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Đăng xuất không nên vì lỗi này mà kẹt lại.
    }
  }
}
