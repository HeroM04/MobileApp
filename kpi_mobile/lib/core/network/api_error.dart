import 'dart:io';
import 'package:dio/dio.dart';

/// Nguồn gốc của một lỗi khi gọi máy chủ.
enum ApiFailureKind {
  /// Đứt đường truyền, sóng yếu, wifi rớt — thử lại khi có mạng là được.
  network,

  /// Máy chủ nhận được yêu cầu nhưng hỏng ở phía nó (5xx), hoặc đang ngủ dậy.
  server,

  /// Người dùng nhập thiếu hoặc sai (4xx) — phải sửa nội dung rồi gửi lại.
  user,

  /// Hết hạn đăng nhập.
  auth,
}

/// Một lỗi đã được dịch sang lời người dùng đọc hiểu được.
class ApiFailure {
  final ApiFailureKind kind;
  final String title;
  final String message;

  const ApiFailure(this.kind, this.title, this.message);

  /// Lỗi do người dùng thì nhân viên tự sửa được, còn lại phải báo kỹ thuật.
  bool get isUserFixable => kind == ApiFailureKind.user;

  /// Có nên giữ lại để gửi lại sau không.
  bool get worthRetrying => kind == ApiFailureKind.network || kind == ApiFailureKind.server;
}

/// Dịch một lỗi bất kỳ thành thông báo nói rõ hỏng ở đâu.
///
/// Trước đây mọi màn hình đều bắt lỗi rồi hiện chung một câu kiểu "không gửi
/// được, thử lại sau". Nhân viên đọc xong không biết là mình nhập sai hay hệ
/// thống hỏng, còn người sửa thì không có manh mối nào. Hàm này tách rõ bốn
/// nguồn để thông báo nói đúng việc cần làm.
ApiFailure describeApiFailure(Object e, {String action = 'gửi'}) {
  if (e is SocketException) {
    return ApiFailure(ApiFailureKind.network, 'Không có mạng',
        'Máy không kết nối được Internet. Kiểm tra wifi hoặc 4G rồi $action lại.');
  }

  if (e is DioException) {
    final res = e.response;

    // Máy chủ chưa kịp trả lời
    if (res == null) {
      switch (e.type) {
        case DioExceptionType.connectionError:
          return ApiFailure(ApiFailureKind.network, 'Không có mạng',
              'Không kết nối được tới máy chủ. Kiểm tra wifi hoặc 4G rồi $action lại.');
        case DioExceptionType.connectionTimeout:
          return ApiFailure(ApiFailureKind.network, 'Mạng quá chậm',
              'Chờ mãi không kết nối được. Thử đổi sang wifi hoặc 4G rồi $action lại.');
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiFailure(ApiFailureKind.server, 'Máy chủ phản hồi chậm',
              'Máy chủ chưa trả lời kịp, thường gặp ở lần gửi đầu trong ngày. Chờ một lát rồi $action lại.');
        case DioExceptionType.cancel:
          return ApiFailure(ApiFailureKind.network, 'Đã hủy',
              'Yêu cầu bị hủy giữa chừng.');
        default:
          return ApiFailure(ApiFailureKind.network, 'Không $action được',
              'Lỗi kết nối: ${e.message ?? e.type.name}');
      }
    }

    final code = res.statusCode ?? 0;
    final data = res.data;
    final serverMsg = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : null;

    if (code == 401 || code == 403) {
      return ApiFailure(ApiFailureKind.auth, 'Phiên đăng nhập hết hạn',
          serverMsg ?? 'Vui lòng đăng xuất rồi đăng nhập lại.');
    }
    if (code == 413) {
      return ApiFailure(ApiFailureKind.user, 'Ảnh quá nặng',
          'Máy chủ từ chối vì tệp quá lớn. Chụp lại ảnh nhỏ hơn rồi $action lại.');
    }
    if (code >= 400 && code < 500) {
      return ApiFailure(ApiFailureKind.user, 'Thông tin chưa hợp lệ',
          serverMsg ?? 'Máy chủ từ chối dữ liệu (lỗi $code). Kiểm tra lại các ô đã nhập.');
    }
    if (code >= 500) {
      return ApiFailure(ApiFailureKind.server, 'Máy chủ đang lỗi',
          serverMsg ?? 'Máy chủ gặp sự cố (lỗi $code). Đây là lỗi hệ thống, báo lại bộ phận kỹ thuật.');
    }
    return ApiFailure(ApiFailureKind.server, 'Không $action được',
        serverMsg ?? 'Máy chủ trả về mã $code.');
  }

  // Lỗi do chính app ném ra (ví dụ upload ảnh trả về rỗng)
  return ApiFailure(ApiFailureKind.server, 'Không $action được', e.toString());
}
