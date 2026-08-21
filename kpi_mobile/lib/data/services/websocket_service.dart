import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'package:kpi_mobile/core/stubs/io_stub.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:get/get.dart';
import '../../features/home/controllers/kpi_controller.dart';
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

                // Gộp mọi khoản vừa được cộng vào MỘT thông báo.
                //
                // Trước đây mỗi nhóm điểm bắn ra một thông báo riêng. Khi Admin
                // duyệt liền mấy mục thì bốn thông báo nối đuôi nhau, mỗi cái
                // phải chờ cái trước biến mất — người dùng thấy thông báo cứ trôi
                // xuống chậm rãi mãi không hết.
                if (oldTotal > 0) { // bỏ qua lần nạp dữ liệu đầu tiên
                  final khoan = <String>[];
                  if (newAttendance > oldAttendance) {
                    khoan.add('Chấm công / Đào tạo +${newAttendance - oldAttendance}đ');
                  }
                  if (newMeeting > oldMeeting) {
                    khoan.add('Thực chiến / Đào tạo 1-1 +${newMeeting - oldMeeting}đ');
                  }
                  if (newPost > oldPost) {
                    khoan.add('Lan tỏa +${newPost - oldPost}đ');
                  }
                  if (newDeal > oldDeal) {
                    khoan.add('Chốt căn +${newDeal - oldDeal}đ');
                  }

                  if (khoan.isNotEmpty) {
                    final coChotCan = newDeal > oldDeal;
                    snack(
                      coChotCan ? 'Chúc mừng, bạn vừa chốt căn!' : 'Bạn vừa được cộng điểm KPI',
                      khoan.join('\n'),
                      backgroundColor: coChotCan ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50),
                      colorText: coChotCan ? const Color(0xFF0F2C59) : const Color(0xFFFFFFFF),
                      duration: const Duration(seconds: 4),
                    );
                  }
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

  void disconnect() {
    stompClient?.deactivate();
    stompClient = null;
  }
}
