import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class FeedbackService {
  /// Số ảnh đính kèm tối đa — khớp FeedbackService.TOI_DA_ANH bên máy chủ.
  static const toiDaAnh = 5;

  /// Gửi góp ý. Có ảnh thì gửi nội dung + ảnh trong MỘT lượt (multipart): máy
  /// chủ đưa ảnh lên Cloudinary như các phần khác, chỉ lưu link. Không ảnh thì
  /// gửi JSON như cũ.
  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data, {List<File> anh = const []}) async {
    if (anh.isEmpty) {
      final response = await ApiClient.dio.post('/feedbacks', data: data);
      return response.data;
    }
    try {
      final response = await ApiClient.dio.post('/feedbacks', data: await taoForm(data, anh));
      return response.data;
    } on DioException catch (e) {
      // Token hết hạn giữa chừng: bộ chặn đã làm mới token nhưng không gửi lại
      // được form ảnh (form chỉ dùng một lần). Dựng form mới gửi lại một lần.
      if (e.response?.statusCode != 401) rethrow;
      final response = await ApiClient.dio.post('/feedbacks', data: await taoForm(data, anh));
      return response.data;
    }
  }

  /// Form multipart: các trường chữ + các file ảnh cùng tên "images".
  static Future<FormData> taoForm(Map<String, dynamic> data, List<File> anh) async {
    final form = FormData.fromMap({
      for (final e in data.entries)
        if (e.value != null) e.key: e.value.toString(),
    });
    for (final f in anh) {
      form.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(f.path, filename: f.path.split(RegExp(r'[\\/]')).last),
      ));
    }
    return form;
  }

  Future<Map<String, dynamic>> getMyFeedbacks() async {
    final response = await ApiClient.dio.get('/feedbacks/my');
    return response.data;
  }
}
