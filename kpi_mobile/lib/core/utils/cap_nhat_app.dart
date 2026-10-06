import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TỰ CẬP NHẬT APP ANDROID (không qua Play Store).
///
/// Mỗi lần Codemagic build xong, nó đăng một bản phát hành lên GitHub Releases
/// của kho [khoPhatHanh] gồm file APK và `phien-ban.json` ({soBuild, ten,
/// linkApk, ghiChu, batBuoc}). App đọc file json của bản MỚI NHẤT; số build lớn
/// hơn bản đang chạy thì hỏi "Cập nhật / Để sau", bấm Cập nhật thì tự tải APK
/// (có thanh tiến trình) rồi mở trình cài đặt của Android.
///
/// APK mới ký cùng khóa release.jks nên Android cài đè, giữ nguyên dữ liệu và
/// đăng nhập. Android luôn bắt người dùng bấm xác nhận cài — không bỏ được với
/// app ngoài Play Store. iOS cập nhật qua TestFlight nên bỏ qua.

/// Số build của bản đang chạy — Codemagic truyền lúc build
/// (`--dart-define=SO_BUILD=...`). Build ở máy dev không truyền → 0 → không hỏi.
const int soBuildHienTai = int.fromEnvironment('SO_BUILD');

/// Kho GitHub CÔNG KHAI chứa các bản phát hành (chỉ để chứa APK, không có code).
const String khoPhatHanh =
    String.fromEnvironment('KHO_PHAT_HANH', defaultValue: 'HeroM04/kpi-trilong-app');

const _navy = Color(0xFF0F2C59);

class BanMoi {
  final int soBuild;
  final String ten;
  final String linkApk;
  final String ghiChu;
  final bool batBuoc;

  const BanMoi({
    required this.soBuild,
    required this.ten,
    required this.linkApk,
    this.ghiChu = '',
    this.batBuoc = false,
  });
}

/// Đọc `phien-ban.json`. Thiếu số build hay link APK thì coi như không có bản mới.
BanMoi? docBanMoi(dynamic json) {
  if (json is String) {
    try {
      json = jsonDecode(json);
    } catch (_) {
      return null;
    }
  }
  if (json is! Map) return null;
  final so = int.tryParse('${json['soBuild'] ?? ''}');
  final link = '${json['linkApk'] ?? ''}'.trim();
  if (so == null || so <= 0 || !link.startsWith('https://')) return null;
  return BanMoi(
    soBuild: so,
    ten: '${json['ten'] ?? ''}'.trim(),
    linkApk: link,
    ghiChu: '${json['ghiChu'] ?? ''}'.trim(),
    batBuoc: json['batBuoc'] == true || json['batBuoc'] == 'true',
  );
}

/// Có nên hỏi cập nhật không. Bản bắt buộc thì luôn hỏi; còn lại thì không hỏi
/// lại đúng bản người dùng vừa bấm "Để sau" cho tới [hoanDenLuc].
bool canHoiCapNhat({
  required int hienTai,
  required BanMoi ban,
  required DateTime bayGio,
  int? hoanBuild,
  DateTime? hoanDenLuc,
}) {
  if (hienTai <= 0 || ban.soBuild <= hienTai) return false;
  if (ban.batBuoc) return true;
  final dangHoan = hoanBuild == ban.soBuild && hoanDenLuc != null && bayGio.isBefore(hoanDenLuc);
  return !dangHoan;
}

class CapNhatApp {
  CapNhatApp._();

  /// "Để sau" thì không hỏi lại bản đó trong khoảng này.
  static const hoanSau = Duration(hours: 12);

  /// Không gọi GitHub dày hơn mức này (app hay bị kéo ra/vào nền cả ngày).
  static const giuaHaiLan = Duration(hours: 2);

  static const _kHoanBuild = 'cap_nhat_hoan_build';
  static const _kHoanDen = 'cap_nhat_hoan_den';

  static bool _dangChay = false;
  static DateTime? _lanCuoi;

  static String get _linkThongTin => 'https://github.com/$khoPhatHanh/releases/latest/download/phien-ban.json';

  /// Gọi khi vào màn hình chính và khi app quay lại từ nền. Im lặng hoàn toàn
  /// nếu lỗi mạng hay chưa có bản phát hành nào — không bao giờ chặn người dùng.
  static Future<void> kiemTra() async {
    if (!Platform.isAndroid || soBuildHienTai <= 0 || _dangChay) return;
    final now = DateTime.now();
    if (_lanCuoi != null && now.difference(_lanCuoi!) < giuaHaiLan) return;
    _dangChay = true;
    _lanCuoi = now;
    try {
      final res = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.plain,
      )).get('$_linkThongTin?t=${now.millisecondsSinceEpoch}');
      final ban = docBanMoi(res.data);
      if (ban == null) return;

      final prefs = await SharedPreferences.getInstance();
      final hoanDen = prefs.getInt(_kHoanDen);
      if (!canHoiCapNhat(
        hienTai: soBuildHienTai,
        ban: ban,
        bayGio: now,
        hoanBuild: prefs.getInt(_kHoanBuild),
        hoanDenLuc: hoanDen == null ? null : DateTime.fromMillisecondsSinceEpoch(hoanDen),
      )) {
        return;
      }

      final deSau = await Get.dialog<bool>(
        _HopCapNhat(ban: ban),
        barrierDismissible: false,
      );
      if (deSau == true) {
        await prefs.setInt(_kHoanBuild, ban.soBuild);
        await prefs.setInt(_kHoanDen, now.add(hoanSau).millisecondsSinceEpoch);
      }
    } catch (_) {
      // Mất mạng, GitHub chậm, chưa có bản phát hành… — lần sau thử lại.
    } finally {
      _dangChay = false;
    }
  }
}

/// Hộp "Có bản mới". Trả về true nếu người dùng chọn "Để sau".
class _HopCapNhat extends StatefulWidget {
  final BanMoi ban;
  const _HopCapNhat({required this.ban});

  @override
  State<_HopCapNhat> createState() => _HopCapNhatState();
}

class _HopCapNhatState extends State<_HopCapNhat> {
  double? _tienDo; // null = chưa tải; 0..1 = đang tải
  String? _loi;
  String? _fileDaTai;
  CancelToken? _huy;

  Future<void> _capNhat() async {
    setState(() {
      _loi = null;
      _tienDo = 0;
    });
    try {
      var duongDan = _fileDaTai;
      if (duongDan == null || !File(duongDan).existsSync()) {
        final thuMuc = Directory('${(await getTemporaryDirectory()).path}/cap-nhat');
        if (thuMuc.existsSync()) thuMuc.deleteSync(recursive: true); // bỏ APK của lần trước
        thuMuc.createSync(recursive: true);
        duongDan = '${thuMuc.path}/kpi-trilong-${widget.ban.soBuild}.apk';
        _huy = CancelToken();
        await Dio().download(
          widget.ban.linkApk,
          duongDan,
          cancelToken: _huy,
          onReceiveProgress: (nhan, tong) {
            if (mounted && tong > 0) setState(() => _tienDo = nhan / tong);
          },
        );
        _fileDaTai = duongDan;
      }
      if (!mounted) return;
      setState(() => _tienDo = 1);

      final kq = await OpenFilex.open(duongDan, type: 'application/vnd.android.package-archive');
      if (!mounted) return;
      if (kq.type != ResultType.done) {
        setState(() {
          _tienDo = null;
          _loi = 'Không mở được trình cài đặt (${kq.message}). Bấm "Cập nhật" để thử lại.';
        });
        return;
      }
      // Trình cài đặt của Android đã mở. Người dùng bấm "Cập nhật" ở đó là app
      // được thay bằng bản mới. Lần đầu Android hỏi "Cho phép cài ứng dụng từ
      // nguồn này" — bật lên, quay lại là cài tiếp. Lỡ thoát ra thì hộp này vẫn
      // còn, bấm Cập nhật lần nữa là mở lại ngay, không tải lại.
      setState(() => _tienDo = null);
    } on DioException catch (e) {
      if (!mounted || CancelToken.isCancel(e)) return;
      setState(() {
        _tienDo = null;
        _loi = 'Tải bản mới không thành công. Kiểm tra mạng rồi bấm "Cập nhật" lần nữa.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tienDo = null;
        _loi = 'Có lỗi khi cập nhật. Bấm "Cập nhật" để thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _huy?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ban = widget.ban;
    final dangTai = _tienDo != null;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: _navy),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ban.ten.isEmpty ? 'Đã có bản mới' : 'Đã có bản ${ban.ten}',
                style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ban.batBuoc
                  ? 'Bản này bắt buộc để app tiếp tục hoạt động đúng. Vui lòng cập nhật.'
                  : 'Cập nhật để dùng các tính năng và bản sửa lỗi mới nhất. Dữ liệu và đăng nhập được giữ nguyên.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            if (ban.ghiChu.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ban.ghiChu, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ],
            if (dangTai) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: _tienDo == 0 ? null : _tienDo,
                color: _navy,
                backgroundColor: const Color(0xFFE2E8F0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 6),
              Text(
                _tienDo == 1 ? 'Đang mở trình cài đặt…' : 'Đang tải… ${((_tienDo ?? 0) * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (_loi != null) ...[
              const SizedBox(height: 10),
              Text(_loi!, style: const TextStyle(fontSize: 12.5, color: Colors.red)),
            ],
            if (_fileDaTai != null && !dangTai && _loi == null) ...[
              const SizedBox(height: 10),
              const Text(
                'Nếu Android hỏi "Cho phép cài ứng dụng từ nguồn này", hãy bật lên rồi quay lại bấm Cập nhật.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
            ],
          ],
        ),
        actions: [
          if (!ban.batBuoc)
            TextButton(
              onPressed: dangTai
                  ? null
                  : () {
                      _huy?.cancel();
                      Get.back(result: true);
                    },
              child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
            ),
          ElevatedButton(
            onPressed: dangTai ? null : _capNhat,
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cập nhật', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
