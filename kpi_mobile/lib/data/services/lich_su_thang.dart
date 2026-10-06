import '../../core/network/api_client.dart';

/// Tải lịch sử "của tôi" cả tháng ('yyyy-MM') cho chế độ "Theo tháng" ở các
/// tab Lịch sử. Các API /my-* (chấm công, thực chiến, bài đăng, chốt căn, đào
/// tạo, phản hồi) cùng nhận ?month=.
///
/// Lỗi thì ném ra để màn hình biết là lỗi chứ không phải tháng trống.
Future<List<Map<String, dynamic>>> taiLichSuThang(String duongDan, String thang) async {
  final res = await ApiClient.dio.get(duongDan, queryParameters: {'month': thang});
  final data = res.data is Map ? res.data['data'] : null;
  return data is List ? List<Map<String, dynamic>>.from(data) : [];
}
