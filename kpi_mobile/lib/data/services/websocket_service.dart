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
                final kpiController = Get.put(KpiController());
                kpiController.kpiPoints.value = (kpi['total'] as num?)?.toDouble() ?? 0.0;
                kpiController.attendancePoints.value = (kpi['attendance'] as num?)?.toInt() ?? 0;
                kpiController.fieldBattleCount.value = (kpi['meeting'] as num?)?.toInt() ?? 0;
                kpiController.socialPostCount.value = (kpi['post'] as num?)?.toInt() ?? 0;
                kpiController.totalDealsClosed.value = (kpi['deal'] as num?)?.toInt() ?? 0;
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
