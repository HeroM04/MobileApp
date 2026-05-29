import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class UploadService {
  Future<String?> uploadFile(File file) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path),
      });

      final response = await ApiClient.dio.post(
        '/upload/file',
        data: formData,
      );

      if (response.data['status'] == 'SUCCESS') {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading file: $e');
      throw e;
    }
  }
}
