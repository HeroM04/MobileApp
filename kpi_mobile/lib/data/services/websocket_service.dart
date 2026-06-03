import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'package:kpi_mobile/core/stubs/io_stub.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:get/get.dart';
import '../../features/home/controllers/kpi_controller.dart';
import '../../core/constants/api_constants.dart';
import 'dart:convert';

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

                // Notifications
                if (oldTotal > 0) { // Don't show notification on initial load
                  if (newAttendance > oldAttendance) {
                    Get.snackbar(
                      'Hoàn thành Chấm công / Đào tạo',
                      'Bạn vừa được duyệt và cộng ${newAttendance - oldAttendance} điểm KPI!',
                      backgroundColor: const Color(0xFF4CAF50),
                      colorText: const Color(0xFFFFFFFF),
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(10),
                    );
                  }
                  if (newMeeting > oldMeeting) {
                    Get.snackbar(
                      'Thực chiến / Đào tạo 1-1',
                      'Bạn vừa được cộng ${newMeeting - oldMeeting} điểm KPI!',
                      backgroundColor: const Color(0xFF4CAF50),
                      colorText: const Color(0xFFFFFFFF),
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(10),
                    );
                  }
                  if (newPost > oldPost) {
                    Get.snackbar(
                      'Bài đăng MXH đã duyệt',
                      'Bạn vừa được cộng ${newPost - oldPost} điểm KPI lan tỏa dự án!',
                      backgroundColor: const Color(0xFF4CAF50),
                      colorText: const Color(0xFFFFFFFF),
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(10),
                    );
                  }
                  if (newDeal > oldDeal) {
                    Get.snackbar(
                      'Chốt căn thành công!',
                      'Chúc mừng! Bạn vừa được cộng ${newDeal - oldDeal} điểm KPI chốt căn!',
                      backgroundColor: const Color(0xFFD4AF37),
                      colorText: const Color(0xFF0F2C59),
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(10),
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
