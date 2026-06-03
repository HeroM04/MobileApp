import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../../data/services/training_service.dart';

class TrainingRoom {
  final int id;
  final String title;
  final String description;
  final String presenter;
  final String roomCode;
  final DateTime dateTime;
  final int maxSlots;
  final int currentSlots;
  final String status;
  final RxList<Map<String, dynamic>> participants;

  TrainingRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.presenter,
    required this.roomCode,
    required this.dateTime,
    required this.maxSlots,
    required this.currentSlots,
    required this.status,
    List<Map<String, dynamic>>? initialParticipants,
  }) : participants = (initialParticipants ?? <Map<String, dynamic>>[]).obs;

  factory TrainingRoom.fromJson(Map<String, dynamic> json) {
    try {
      DateTime parsedDate = DateTime.now();
      try {
        if (json['startTime'] != null) {
          parsedDate = DateTime.parse(json['startTime'].toString());
        }
      } catch (_) {}

      List<Map<String, dynamic>> parsedAttendees = [];
      if (json['attendees'] != null && json['attendees'] is List) {
        for (var e in (json['attendees'] as List)) {
          if (e == null || e is! Map) continue;
          String timeStr = '';
          try {
            if (e['attendedAt'] != null) {
              timeStr = DateTime.parse(e['attendedAt'].toString()).toLocal().toString().substring(11, 16);
            }
          } catch (_) {}
          
          parsedAttendees.add({
            'name': e['fullName']?.toString() ?? 'Ẩn danh',
            'role': e['role']?.toString() ?? '',
            'time': timeStr,
          });
        }
      }

      return TrainingRoom(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        presenter: json['presenter']?.toString() ?? '',
        roomCode: json['roomCode']?.toString() ?? '',
        dateTime: parsedDate,
        maxSlots: json['maxSlots'] is int ? json['maxSlots'] : int.tryParse(json['maxSlots'].toString()) ?? 0,
        currentSlots: json['currentSlots'] is int ? json['currentSlots'] : int.tryParse(json['currentSlots'].toString()) ?? 0,
        status: json['status']?.toString() ?? '',
        initialParticipants: parsedAttendees,
      );
    } catch (e) {
      print("CRITICAL ERROR in TrainingRoom.fromJson: $e");
      return TrainingRoom(
        id: 0,
        title: "Lỗi hiển thị phòng",
        description: "Dữ liệu phòng học bị lỗi định dạng",
        presenter: "Lỗi",
        roomCode: json['roomCode']?.toString() ?? "LỖI",
        dateTime: DateTime.now(),
        maxSlots: 0,
        currentSlots: 0,
        status: "ERROR",
      );
    }
  }
}

class TrainingController extends GetxController {
  final TrainingService _trainingService = TrainingService();

  var rooms = <TrainingRoom>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRooms();
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String date) async {
    try {
      final response = await ApiClient.dio.get('/training-sessions/my-trainings', queryParameters: {'date': date});
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print('Lỗi fetch lịch sử đào tạo: $e');
    }
    return [];
  }

  Future<void> fetchRooms() async {
    try {
      isLoading.value = true;
      final response = await _trainingService.getAllSessions();
      if (response['status'] == 'SUCCESS') {
        final List<dynamic> data = response['data'];
        rooms.value = data.map((e) => TrainingRoom.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching training rooms: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Reload specific room details to get full attendees list
  Future<void> reloadRoomDetails(int roomId) async {
    try {
      final response = await _trainingService.getSessionById(roomId);
      if (response['status'] == 'SUCCESS') {
        final updatedRoom = TrainingRoom.fromJson(response['data']);
        final index = rooms.indexWhere((r) => r.id == roomId);
        if (index != -1) {
          rooms[index] = updatedRoom;
        }
      }
    } catch (e) {
      print('Error reloading room details: $e');
    }
  }

  Future<bool> attendRoomByCode(String code) async {
    try {
      final response = await _trainingService.attendTraining(code);
      if (response['status'] == 'SUCCESS') {
        // Refresh KPI and Room lists
        if (Get.isRegistered<KpiController>()) {
          Get.find<KpiController>().fetchKpiData();
        }
        fetchRooms();
        return true;
      }
      return false;
    } catch (e) {
      print('Error attending room: $e');
      return false;
    }
  }

  /// Tạo phòng đào tạo mới, trả về TrainingRoom nếu thành công (để hiển thị QR ngay).
  Future<TrainingRoom?> createRoom(
    String title,
    String description,
    String presenter,
    String roomCode,
    DateTime dateTime, {
    int maxSlots = 50,
    String location = 'Phòng Đào Tạo',
  }) async {
    try {
      final response = await _trainingService.createSession({
        'title': title,
        'description': description,
        'presenter': presenter,
        'roomCode': roomCode,
        'startTime': dateTime.toUtc().toIso8601String(), // UTC format để backend parse được ZonedDateTime
        'maxSlots': maxSlots,
        'location': location,
      });
      if (response['status'] == 'SUCCESS') {
        fetchRooms();
        return TrainingRoom.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error creating room: $e');
      return null;
    }
  }

  /// Kết thúc buổi đào tạo — chuyển trạng thái sang COMPLETED
  Future<bool> endRoom(int roomId) async {
    try {
      final response = await _trainingService.updateStatus(roomId, 'COMPLETED');
      if (response['status'] == 'SUCCESS') {
        fetchRooms(); // Refresh danh sách
        return true;
      }
      return false;
    } catch (e) {
      print('Error ending room: $e');
      return false;
    }
  }

  Future<bool> submitOneOnOne(String content, String photoUrl) async {
    try {
      final response = await ApiClient.dio.post('/training/1-on-1', data: {
        'content': content,
        'photoUrl': photoUrl,
      });
      if (response.data != null && response.data['status'] == 'SUCCESS') {
        if (Get.isRegistered<KpiController>()) {
          Get.find<KpiController>().fetchKpiData();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting 1-1 training: $e');
      return false;
    }
  }
}
