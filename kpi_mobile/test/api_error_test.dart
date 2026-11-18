import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/network/api_error.dart';

/// Dịch lỗi gọi máy chủ sang lời nhân viên hiểu được.
///
/// Phân loại sai thì câu báo sai việc cần làm: báo "mất mạng" khi thật ra nhập
/// sai, nhân viên cứ đổi wifi rồi gửi lại mãi; báo "nhập sai" khi máy chủ hỏng,
/// họ sửa đi sửa lại một nội dung vốn đúng.
DioException loiCo(int code, {Object? data}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: code, data: data),
    type: DioExceptionType.badResponse,
  );
}

DioException loiKhongPhanHoi(DioExceptionType loai) =>
    DioException(requestOptions: RequestOptions(path: '/x'), type: loai);

void main() {
  test('mất mạng hẳn (SocketException) → network, nên thử lại', () {
    final f = describeApiFailure(const SocketException('Failed host lookup'));
    expect(f.kind, ApiFailureKind.network);
    expect(f.worthRetrying, isTrue);
  });

  test('không kết nối được / kết nối quá chậm → network', () {
    expect(describeApiFailure(loiKhongPhanHoi(DioExceptionType.connectionError)).kind, ApiFailureKind.network);
    expect(describeApiFailure(loiKhongPhanHoi(DioExceptionType.connectionTimeout)).kind, ApiFailureKind.network);
  });

  test('đã kết nối nhưng máy chủ trả lời chậm (Render đang dậy) → server, không phải mất mạng', () {
    final f = describeApiFailure(loiKhongPhanHoi(DioExceptionType.receiveTimeout));
    expect(f.kind, ApiFailureKind.server);
    expect(f.worthRetrying, isTrue);
  });

  test('401/403 → hết phiên đăng nhập', () {
    expect(describeApiFailure(loiCo(401)).kind, ApiFailureKind.auth);
    expect(describeApiFailure(loiCo(403)).kind, ApiFailureKind.auth);
  });

  test('400 → lỗi người dùng, dùng nguyên câu máy chủ báo', () {
    final f = describeApiFailure(loiCo(400, data: {'message': 'Mật khẩu không chính xác'}));
    expect(f.kind, ApiFailureKind.user);
    expect(f.isUserFixable, isTrue);
    expect(f.worthRetrying, isFalse);
    expect(f.message, 'Mật khẩu không chính xác');
  });

  test('413 → ảnh quá nặng, bảo chụp lại', () {
    final f = describeApiFailure(loiCo(413));
    expect(f.kind, ApiFailureKind.user);
    expect(f.title, 'Ảnh quá nặng');
  });

  test('500 không kèm lời → câu mặc định có mã lỗi để báo kỹ thuật', () {
    final f = describeApiFailure(loiCo(500));
    expect(f.kind, ApiFailureKind.server);
    expect(f.message, contains('500'));
  });

  test('động từ trong câu đổi theo việc đang làm', () {
    final f = describeApiFailure(loiKhongPhanHoi(DioExceptionType.connectionError), action: 'đăng nhập');
    expect(f.message, contains('đăng nhập lại'));
  });

  test('lỗi do chính app ném ra → server, giữ nguyên nội dung để tra', () {
    final f = describeApiFailure(Exception('upload trả về rỗng'));
    expect(f.kind, ApiFailureKind.server);
    expect(f.message, contains('upload trả về rỗng'));
  });

  // ── Lỗi trên chính điện thoại: không được in mã kỹ thuật ra màn hình ──────
  // Nhân viên từng thấy "PlatformException(camera_access_denied, ...)",
  // "DioException [connection timeout]..." mà không biết phải làm gì.

  /// Không câu nào lộ tên lớp lỗi hay chuỗi tiếng Anh của thư viện.
  void khongLoMa(ApiFailure f) {
    for (final chu in [f.title, f.message]) {
      expect(chu, isNot(contains('Exception')));
      expect(chu, isNot(contains('access_denied')));
      expect(chu, isNot(contains('The user')));
    }
  }

  test('bị chặn quyền camera / ảnh → chỉ chỗ bật trong Cài đặt', () {
    final cam = describeApiFailure(PlatformException(code: 'camera_access_denied', message: 'The user did not allow camera access.'), action: 'chấm công');
    expect(cam.kind, ApiFailureKind.device);
    expect(cam.isUserFixable, isTrue);
    expect(cam.worthRetrying, isFalse);
    expect(cam.message, contains('Camera'));
    khongLoMa(cam);
    final anh = describeApiFailure(PlatformException(code: 'photo_access_denied', message: 'The user did not allow photo access.'));
    expect(anh.title, 'Chưa cho phép truy cập ảnh');
    khongLoMa(anh);
  });

  test('bấm camera hai lần / camera đang bận → nói rõ, không in mã', () {
    final f = describeApiFailure(PlatformException(code: 'already_active', message: 'Image picker is already active'));
    expect(f.title, 'Camera đang mở');
    khongLoMa(f);
    khongLoMa(describeApiFailure(PlatformException(code: 'no_available_camera', message: 'No cameras available')));
  });

  test('lỗi điện thoại lạ → lời dễ hiểu, chỉ kèm mã ngắn ở cuối để tra', () {
    final f = describeApiFailure(PlatformException(code: 'xyz', message: 'Something native broke'), action: 'chụp ảnh');
    expect(f.kind, ApiFailureKind.device);
    expect(f.message, startsWith('Điện thoại báo lỗi khi chụp ảnh'));
    expect(f.message, isNot(contains('Something native broke')));
  });

  test('GPS: tắt định vị, chưa cấp quyền, chưa bắt được sóng', () {
    expect(describeApiFailure(const LocationServiceDisabledException()).title, 'Chưa bật Định vị');
    final quyen = describeApiFailure(const PermissionDeniedException('denied'));
    expect(quyen.message, contains('Vị trí'));
    khongLoMa(quyen);
    expect(describeApiFailure(const PositionUpdateException('x')).kind, ApiFailureKind.device);
  });

  test('chờ quá lâu (TimeoutException) → không in "TimeoutException after 0:00:30"', () {
    final f = describeApiFailure(TimeoutException('x', const Duration(seconds: 30)), action: 'chấm công');
    expect(f.title, 'Chờ quá lâu');
    expect(f.message, contains('chấm công lần nữa'));
    khongLoMa(f);
  });

  test('lời tiếng Việt app tự ném ra → giữ nguyên', () {
    expect(describeApiFailure('Không thể upload ảnh lên máy chủ').message, 'Không thể upload ảnh lên máy chủ');
  });

  test('lỗi lạ hẳn → không in toàn bộ chuỗi lỗi', () {
    final f = describeApiFailure(StateError('Bad state: internal detail'));
    expect(f.message, isNot(contains('internal detail')));
    expect(f.message, contains('bộ phận kỹ thuật'));
  });

  test('mạng đứt giữa chừng / wifi chặn → không in câu tiếng Anh của Dio', () {
    final dut = describeApiFailure(DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.unknown,
        message: 'HttpException: Connection closed before full header was received'));
    expect(dut.kind, ApiFailureKind.network);
    expect(dut.message, isNot(contains('HttpException')));
    expect(describeApiFailure(loiKhongPhanHoi(DioExceptionType.badCertificate)).message, contains('4G'));
  });
}
