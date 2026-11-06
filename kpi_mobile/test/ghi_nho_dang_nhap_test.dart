import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/network/kho_token.dart';
import 'package:kpi_mobile/features/auth/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthController giả: bỏ phần đọc phiên / gọi mạng lúc khởi tạo.
class _AuthGia extends AuthController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// Ô "Ghi nhớ đăng nhập" và nút "Quên mật khẩu?" ở màn đăng nhập.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kenh = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> kho;

  setUp(() {
    kho = {};
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kenh, (c) async {
      final args = (c.arguments as Map?) ?? const {};
      final khoa = args['key'] as String?;
      switch (c.method) {
        case 'read':
          return kho[khoa];
        case 'write':
          kho[khoa!] = args['value'] as String;
          return null;
        case 'delete':
          kho.remove(khoa);
          return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kenh, null);
  });

  test('máy cài bản cũ (chưa từng chọn) → coi như có ghi nhớ, đúng cách app chạy trước nay', () async {
    final g = await _AuthGia().docGhiNho();
    expect(g.ghiNho, isTrue);
    expect(await _AuthGia().phienTamDaHet(), isFalse);
  });

  test('tích ghi nhớ → lần sau điền sẵn số điện thoại + mật khẩu', () async {
    final auth = _AuthGia();
    await auth.luuGhiNho(true, '0912345678', 'mk-cua-toi');

    final g = await auth.docGhiNho();
    expect(g.ghiNho, isTrue);
    expect(g.sdt, '0912345678');
    expect(g.matKhau, 'mk-cua-toi');
  });

  test('bỏ tích → xóa số điện thoại + mật khẩu đã lưu', () async {
    final auth = _AuthGia();
    await auth.luuGhiNho(true, '0912345678', 'mk-cua-toi');
    await auth.luuGhiNho(false, '0912345678', 'mk-cua-toi');

    final g = await auth.docGhiNho();
    expect(g.ghiNho, isFalse);
    expect(kho.containsKey(KhoToken.ghiNhoSdt), isFalse);
    expect(kho.containsKey(KhoToken.ghiNhoMatKhau), isFalse);
  });

  test('bỏ tích: rời app chưa tới 10 phút (mở camera chấm công) vẫn giữ phiên, quá 10 phút thì hết', () async {
    final auth = _AuthGia();
    await auth.luuGhiNho(false, '0912345678', 'x');

    SharedPreferences.setMockInitialValues({
      'roiAppLuc': DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch,
    });
    expect(await auth.phienTamDaHet(), isFalse);

    SharedPreferences.setMockInitialValues({
      'roiAppLuc': DateTime.now().subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
    });
    expect(await auth.phienTamDaHet(), isTrue);

    // Không rõ rời app lúc nào → coi như đã hết
    SharedPreferences.setMockInitialValues({});
    expect(await auth.phienTamDaHet(), isTrue);
  });

  test('có tích ghi nhớ thì rời app bao lâu cũng giữ phiên', () async {
    final auth = _AuthGia();
    await auth.luuGhiNho(true, '0912345678', 'x');
    SharedPreferences.setMockInitialValues({
      'roiAppLuc': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
    });
    expect(await auth.phienTamDaHet(), isFalse);
  });

  test('quên mật khẩu: để trống số điện thoại → không gọi máy chủ, trả false', () async {
    expect(await _AuthGia().quenMatKhau('   '), isFalse);
  });

  test('phần ghi nhớ không nằm chung chỗ với token (đăng xuất không xóa)', () {
    expect([KhoToken.ghiNhoDangNhap, KhoToken.ghiNhoSdt, KhoToken.ghiNhoMatKhau],
        isNot(contains(anyOf(KhoToken.accessToken, KhoToken.refreshToken))));
  });
}
