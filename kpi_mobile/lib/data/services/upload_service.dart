import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/thu_nho_anh.dart';

class UploadService {
  Future<String?> uploadFile(File goc) async {
    try {
      // Ảnh trên 2 MB (thường là ảnh chụp màn hình PNG) nén sang JPEG trên máy trước
      final file = await nenAnhTruocKhiGui(goc);
      final fileName = file.path.split('/').last;
      
      print('--- UPLOAD API LOG ---');
      print('Endpoint: ${ApiClient.baseUrl}/upload/image');
      print('File to upload: $fileName');
      
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await ApiClient.dio.post(
        '/upload/image', // Sửa từ /upload/file sang /upload/image để khớp với Spring Boot
        data: formData,
      );

      print('Upload success: \${response.data}');
      if (response.data['status'] == 'SUCCESS') {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      print('--- UPLOAD API ERROR LOG ---');
      if (e is DioException) {
        print('DioException URL: ${e.requestOptions.uri}');
        print('DioException Status: ${e.response?.statusCode}');
        print('DioException Data: ${e.response?.data}');
        print('DioException Headers: ${e.response?.headers}');
      } else {
        print('Unknown Error: $e');
      }
      throw e;
    }
  }
}
