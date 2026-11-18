import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:geolocator/geolocator.dart';

/// Nguồn gốc của một lỗi khi gọi máy chủ.
enum ApiFailureKind {
  /// Lỗi trên chính điện thoại: chưa cấp quyền camera / ảnh / vị trí, tắt GPS,
  /// camera đang bận — người dùng tự bật lại được, không phải lỗi hệ thống.
  device,

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
  bool get isUserFixable => kind == ApiFailureKind.user || kind == ApiFailureKind.device;

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
        case DioExceptionType.badCertificate:
          // Hay gặp ở wifi quán cà phê, sảnh tòa nhà: wifi chặn lại đòi đăng nhập
          return ApiFailure(ApiFailureKind.network, 'Wifi đang chặn kết nối',
              'Wifi này cần đăng nhập hoặc không an toàn. Đổi sang 4G rồi $action lại.');
        default:
          // Đứt giữa chừng (mạng chập chờn, đổi wifi sang 4G lúc đang gửi)
          return ApiFailure(ApiFailureKind.network, 'Mạng bị ngắt',
              'Đường truyền bị ngắt giữa chừng. Kiểm tra wifi hoặc 4G rồi $action lại.');
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

  final mayBao = describeDeviceFailure(e, action: action);
  if (mayBao != null) return mayBao;

  // Lỗi do chính app ném ra bằng lời tiếng Việt (ví dụ "Không thể upload ảnh")
  if (e is String) return ApiFailure(ApiFailureKind.server, 'Không $action được', e);
  final chu = e.toString();
  if (e is Exception && chu.startsWith('Exception: ')) {
    return ApiFailure(ApiFailureKind.server, 'Không $action được', chu.substring('Exception: '.length));
  }

  // Còn lại là lỗi lạ: nói lời dễ hiểu, kèm tên lỗi ngắn để bộ phận kỹ thuật tra
  return ApiFailure(ApiFailureKind.server, 'Không $action được',
      'Có lỗi không mong muốn. Thử lại; nếu vẫn lỗi, chụp màn hình gửi bộ phận kỹ thuật. (Mã: ${e.runtimeType})');
}

/// Lỗi phát sinh trên điện thoại (quyền, GPS, camera, chờ quá lâu); không phải
/// loại này thì trả null.
///
/// Trước đây các màn chụp ảnh, chấm công in thẳng `PlatformException(...)`,
/// `TimeoutException after 0:00:30...` ra màn hình. Nhân viên không biết phải
/// bật gì ở đâu.
ApiFailure? describeDeviceFailure(Object e, {String action = 'gửi'}) {
  if (e is PlatformException) {
    switch (e.code) {
      case 'camera_access_denied':
        return const ApiFailure(ApiFailureKind.device, 'Chưa cho phép dùng camera',
            'Vào Cài đặt → Trí Long Land → bật Camera, rồi quay lại thử lần nữa.');
      case 'photo_access_denied':
        return const ApiFailure(ApiFailureKind.device, 'Chưa cho phép truy cập ảnh',
            'Vào Cài đặt → Trí Long Land → Ảnh → chọn "Tất cả ảnh", rồi quay lại thử lần nữa.');
      case 'already_active':
      case 'multiple_request':
        return const ApiFailure(ApiFailureKind.device, 'Camera đang mở',
            'Lần bấm trước chưa xong. Chờ màn hình camera đóng hẳn rồi bấm lại.');
      case 'no_available_camera':
        return const ApiFailure(ApiFailureKind.device, 'Không mở được camera',
            'Ứng dụng khác đang dùng camera (gọi video, Zalo...). Tắt ứng dụng đó rồi thử lại.');
      case 'invalid_image':
      case 'invalid_source':
        return const ApiFailure(ApiFailureKind.device, 'Không đọc được ảnh',
            'Ảnh này không mở được. Chụp lại hoặc chọn ảnh khác.');
    }
    return ApiFailure(ApiFailureKind.device, 'Không $action được',
        'Điện thoại báo lỗi khi $action. Thử lại; nếu vẫn lỗi, tắt hẳn app rồi mở lại. (Mã: ${e.code})');
  }
  if (e is LocationServiceDisabledException) {
    return const ApiFailure(ApiFailureKind.device, 'Chưa bật Định vị',
        'Bật Định vị (GPS) trên điện thoại rồi thử lại.');
  }
  if (e is PermissionDeniedException) {
    return const ApiFailure(ApiFailureKind.device, 'Chưa cho phép lấy vị trí',
        'Vào Cài đặt → Trí Long Land → Vị trí → chọn "Khi dùng ứng dụng" và bật "Vị trí chính xác", rồi thử lại.');
  }
  if (e is PermissionRequestInProgressException) {
    return const ApiFailure(ApiFailureKind.device, 'Đang hỏi quyền vị trí',
        'Trả lời hộp hỏi quyền vị trí trên màn hình trước rồi thử lại.');
  }
  if (e is PositionUpdateException) {
    return const ApiFailure(ApiFailureKind.device, 'Chưa bắt được GPS',
        'Ra chỗ thoáng, bật wifi để định vị nhanh hơn, rồi thử lại.');
  }
  if (e is TimeoutException) {
    return ApiFailure(ApiFailureKind.device, 'Chờ quá lâu',
        'Thao tác chờ quá lâu nên đã dừng. Bấm lại để $action lần nữa.');
  }
  if (e is FileSystemException) {
    return const ApiFailure(ApiFailureKind.device, 'Không lưu được ảnh',
        'Điện thoại không đọc hoặc ghi được ảnh, thường do bộ nhớ đầy. Xóa bớt ảnh, video rồi thử lại.');
  }
  return null;
}
