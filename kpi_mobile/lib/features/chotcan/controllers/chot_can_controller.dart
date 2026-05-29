import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/chot_can_service.dart';
import '../../home/controllers/kpi_controller.dart';

class ChotCanController extends GetxController {
  final ChotCanService _chotCanService = ChotCanService();
  final KpiController kpiController = Get.put(KpiController());
  
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String date) async {
    try {
      final response = await ApiClient.dio.get('/deals/my-deals', queryParameters: {'date': date});
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      print('Lỗi fetch lịch sử chốt căn: $e');
    }
    return [];
  }

  Future<bool> submitDeal({
    required String customerName,
    required String customerPhone,
    required String project,
    required String unitCode,
    required double dealValue,
  }) async {
    try {
      isLoading.value = true;
      
      // Giả sử hoa hồng 1%
      double commission = dealValue * 0.01;
      
      final response = await _chotCanService.submitDeal({
        'customerName': customerName,
        'customerPhone': customerPhone,
        'projectName': project,
        'unit': unitCode,
        'price': dealValue,
        'commission': commission,
        'contractPhotoUrl': 'https://dummyimage.com/600x400/000/fff&text=HopDong', // Dummy
      });
      
      if (response['status'] == 'SUCCESS') {
        kpiController.fetchKpiData(); // Sync backend
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting deal: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
