import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'package:kpi_mobile/core/stubs/io_stub.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:get/get.dart';
import '../../features/home/controllers/kpi_controller.dart';
import '../../features/shell/controllers/shell_controller.dart';
import '../../features/thongbao/controllers/thong_bao_controller.dart';
import '../../core/constants/api_constants.dart';
import 'dart:convert';
import '../../core/widgets/thong_bao.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? stompClient;
  final _secureStorage = const FlutterSecureStorage();

  String get _wsUrl {
    return ApiConstants.wsUrl;
  }

  void connect(int userId) async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) return;

    if (stompClient != null && stompClient!.isActive) return;

    stompClient = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: (StompFrame frame) => _onConnect(frame, userId),
        onWebSocketError: (dynamic error) => print('WebSocket Error: ${error.toString()}'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},

        // Ba mốc dưới đây trước để mặc định 5 giây, là nguyên nhân chính làm
        // tụt pin: cứ 5 giây lại gửi một gói tin giữ nhịp nên sóng điện thoại
        // không bao giờ được ngủ sâu. Tệ hơn, máy chủ chạy gói Render miễn phí
        // tự ngủ khi vắng người dùng, kết nối rớt là máy thử nối lại 5 giây một
        // lần suốt đêm, mỗi lần là một lượt bắt tay đầy đủ.
        //
        // Đây chỉ là kênh báo điểm KPI đổi theo thời gian thực, chậm vài chục
        // giây không ảnh hưởng gì.
        heartbeatOutgoing: const Duration(seconds: 30),
        heartbeatIncoming: const Duration(seconds: 30),
        reconnectDelay: const Duration(seconds: 30),
      ),
    );
    stompClient?.activate();
  }

  void _onConnect(StompFrame frame, int userId) {
    print('Connected to STOMP WebSocket');
    stompClient?.subscribe(
      destination: '/topic/kpi/$userId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final payload = json.decode(frame.body!);
            if (payload['status'] == 'SUCCESS') {
              final kpi = payload['data'];
              if (Get.isRegistered<KpiController>()) {
                final kpiController = Get.find<KpiController>();
                
                double oldTotal = kpiController.kpiPoints.value;
                int oldAttendance = kpiController.attendancePoints.value;
                int oldMeeting = kpiController.fieldBattleCount.value;
                int oldPost = kpiController.socialPostCount.value;
                int oldDeal = kpiController.totalDealsClosed.value;

                int newAttendance = (kpi['attendance'] as num?)?.toInt() ?? 0;
                int newMeeting = (kpi['meeting'] as num?)?.toInt() ?? 0;
                int newPost = (kpi['post'] as num?)?.toInt() ?? 0;
                int newDeal = (kpi['deal'] as num?)?.toInt() ?? 0;

                kpiController.kpiPoints.value = (kpi['total'] as num?)?.toDouble() ?? 0.0;
                kpiController.attendancePoints.value = newAttendance;
                kpiController.fieldBattleCount.value = newMeeting;
                kpiController.socialPostCount.value = newPost;
                kpiController.totalDealsClosed.value = newDeal;
                
                double rawWeekly = (kpi['weeklyTotal'] as num?)?.toDouble() ?? 0.0;
                if (rawWeekly > kpiController.kpiWeeklyTarget.value) {
                  rawWeekly = kpiController.kpiWeeklyTarget.value;
                }
                kpiController.kpiWeeklyPoints.value = rawWeekly;

                if (oldTotal > 0) { // bỏ qua lần nạp dữ liệu đầu tiên
                  _baoDiemDoi(
                    payload['change'] as Map<String, dynamic>?,
                    congAttendance: newAttendance - oldAttendance,
                    congMeeting: newMeeting - oldMeeting,
                    congPost: newPost - oldPost,
                    congDeal: newDeal - oldDeal,
                  );
                }
              }
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        }
      },
    );
  }

  /// Báo cho nhân sự biết điểm vừa đổi, và cộng vào huy hiệu Thông báo.
  ///
  /// Máy chủ gửi kèm khối `change` mô tả đúng khoản điểm vừa phát sinh, nên
  /// thông báo nói thẳng được lý do ("Admin duyệt: Video xây kênh trên
  /// Facebook") thay vì chỉ nêu con số. Bản ứng dụng cũ chạy với máy chủ mới
  /// hoặc ngược lại thì rơi về cách cũ là so sánh các tổng.
  void _baoDiemDoi(
    Map<String, dynamic>? change, {
    required int congAttendance,
    required int congMeeting,
    required int congPost,
    required int congDeal,
  }) {
    // Huy hiệu đỏ trên chuông Thông báo.
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().soThongBaoMoi.value++;
    }
    // Đang mở màn hình Thông báo thì nạp lại cho thấy khoản mới ngay.
    if (Get.isRegistered<ThongBaoController>()) {
      Get.find<ThongBaoController>().tai();
    }

    final int diem = (change?['effectivePoints'] as num?)?.toInt() ??
        (congAttendance + congMeeting + congPost + congDeal);
    final String? lyDo = change?['reason']?.toString();
    final bool coChotCan =
        congDeal > 0 || (change?['category']?.toString() == 'deal' && diem > 0);

    // Chạm trần: điểm không vào được nhưng vẫn phải nói cho người ta biết, nếu
    // không họ tưởng hệ thống nuốt mất công sức của mình.
    final int quyDinh = (change?['points'] as num?)?.toInt() ?? diem;
    if (diem == 0) {
      if (quyDinh > 0 && lyDo != null) {
        snack(
          'Nhóm điểm này đã đầy',
          '$lyDo\nKhoản ${quyDinh}đ không cộng thêm được vì nhóm đã đạt tối đa của tuần.',
          backgroundColor: const Color(0xFFF59E0B),
          colorText: const Color(0xFF3B2600),
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    final bool duong = diem > 0;
    final String tieuDe = coChotCan
        ? 'Chúc mừng, bạn vừa chốt căn!'
        : (duong ? 'Bạn vừa được cộng ${diem}đ KPI' : 'Bạn vừa bị trừ ${-diem}đ KPI');

    // Không có lý do (máy chủ bản cũ) thì liệt kê theo nhóm như trước.
    String noiDung;
    if (lyDo != null && lyDo.isNotEmpty) {
      noiDung = lyDo;
    } else {
      final khoan = <String>[];
      if (congAttendance != 0) khoan.add('Chuyên cần & Đào tạo ${_dau(congAttendance)}đ');
      if (congMeeting != 0) khoan.add('Thực chiến ${_dau(congMeeting)}đ');
      if (congPost != 0) khoan.add('Lan tỏa ${_dau(congPost)}đ');
      if (congDeal != 0) khoan.add('Chốt căn ${_dau(congDeal)}đ');
      if (khoan.isEmpty) return;
      noiDung = khoan.join('\n');
    }

    snack(
      tieuDe,
      noiDung,
      backgroundColor: coChotCan
          ? const Color(0xFFD4AF37)
          : (duong ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
      colorText: coChotCan ? const Color(0xFF0F2C59) : const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 4),
    );
  }

  String _dau(int n) => n > 0 ? '+$n' : '$n';

  void disconnect() {
    stompClient?.deactivate();
    stompClient = null;
  }
}
