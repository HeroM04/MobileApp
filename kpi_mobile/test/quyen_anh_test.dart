import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/quyen_anh.dart';

/// Lỗi bị từ chối quyền camera/ảnh phải được nhận ra để hiện hướng dẫn bật
/// quyền thay cho chuỗi PlatformException khó hiểu; lỗi khác vẫn báo như cũ.
void main() {
  test('nhận ra lỗi từ chối quyền camera và thư viện ảnh', () {
    expect(laLoiThieuQuyenAnh(PlatformException(code: 'camera_access_denied')), isTrue);
    expect(laLoiThieuQuyenAnh(PlatformException(code: 'photo_access_denied')), isTrue);
  });

  test('lỗi khác không bị nhận nhầm', () {
    expect(laLoiThieuQuyenAnh(PlatformException(code: 'no_available_camera')), isFalse);
    expect(laLoiThieuQuyenAnh(Exception('mất mạng')), isFalse);
    expect(laLoiThieuQuyenAnh('camera_access_denied'), isFalse);
  });
}
