import 'dart:io';

import 'package:dio/dio.dart';
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
}
