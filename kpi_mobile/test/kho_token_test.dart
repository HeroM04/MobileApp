import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/network/kho_token.dart';

/// Đọc token lỗi (iPhone đang khóa, kho khóa trục trặc) KHÔNG được xóa token
/// và đăng xuất người dùng — trước đây là vậy, nên thỉnh thoảng mở app lại
/// thấy bị đăng xuất mà không làm gì.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kenh = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final goi = <String>[];

  void giaLap(Future<Object?> Function(MethodCall c) xuLy) {
    goi.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kenh, (c) {
      goi.add(c.method);
      return xuLy(c);
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kenh, null);
  });

  test('đọc được thì trả đúng token', () async {
    giaLap((c) async => c.method == 'read' ? 'jwt-123' : null);
    expect(await KhoToken.doc(KhoToken.accessToken), 'jwt-123');
  });

  test('đọc lỗi → thử lại một lần, vẫn lỗi thì trả null và KHÔNG xóa gì', () async {
    giaLap((c) async {
      if (c.method == 'read') throw PlatformException(code: '-25308', message: 'Keychain bị khóa');
      return null;
    });

    expect(await KhoToken.doc(KhoToken.accessToken), isNull);
    expect(goi.where((m) => m == 'read'), hasLength(2));
    expect(goi, isNot(contains('deleteAll')));
    expect(goi, isNot(contains('delete')));
  });

  test('lần đầu lỗi, lần thử lại đọc được → vẫn giữ đăng nhập', () async {
    var lan = 0;
    giaLap((c) async {
      if (c.method != 'read') return null;
      if (lan++ == 0) throw PlatformException(code: 'tam-thoi');
      return 'jwt-456';
    });
    expect(await KhoToken.doc(KhoToken.refreshToken), 'jwt-456');
  });

  test('xóa lỗi cũng không ném ra ngoài (đăng xuất vẫn chạy tiếp)', () async {
    giaLap((c) async {
      if (c.method == 'delete') throw PlatformException(code: 'loi');
      return null;
    });
    await KhoToken.xoa(KhoToken.accessToken);
  });
}
