import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_error.dart';
import '../../core/utils/dong_ho_may.dart';
import '../../core/widgets/thong_bao.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/kpi_controller.dart';
import 'checkin_service.dart';
import 'upload_service.dart';

/// Một lần bấm chấm công, giữ trên máy cho tới khi máy chủ nhận.
class LuotChamCong {
  /// Mã của lần bấm — gửi lại bao nhiêu lần máy chủ cũng chỉ lưu một lượt.
  final String maLuot;
  final int userId;

  /// CHECK_IN hoặc CHECK_OUT.
  final String actionType;

  /// Giờ điện thoại lúc chụp ảnh chấm công.
  final DateTime lucBam;

  /// Đồng hồ tính từ lúc bật máy lúc chụp — để đo thời gian chờ (xem [DongHoMay]).
  final MocMay? mocBam;

  final double lat;
  final double lng;
  final String address;
  final String note;

  /// Ảnh đã đóng dấu, chép vào thư mục riêng của app để không bị dọn mất.
  String anhPath;

  /// Có rồi thì gửi lại không phải tải ảnh lên lần nữa.
  String? photoUrl;

  int soLanGui;

  LuotChamCong({
    required this.maLuot,
    required this.userId,
    required this.actionType,
    required this.lucBam,
    required this.mocBam,
    required this.lat,
    required this.lng,
    required this.address,
    required this.note,
    required this.anhPath,
    this.photoUrl,
    this.soLanGui = 0,
  });

  static String taoMa(int userId) =>
      '$userId-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';

  bool get laVao => actionType != 'CHECK_OUT';

  /// "VÀO lúc 08:44" — dùng trong thông báo.
  String get moTa {
    final t = lucBam.toLocal();
    String hai(int n) => n.toString().padLeft(2, '0');
    return '${laVao ? 'VÀO' : 'RA'} lúc ${hai(t.hour)}:${hai(t.minute)}';
  }

  Map<String, dynamic> toJson() => {
        'maLuot': maLuot,
        'userId': userId,
        'actionType': actionType,
        'lucBam': lucBam.toUtc().toIso8601String(),
        'mocBam': mocBam?.toJson(),
        'lat': lat,
        'lng': lng,
        'address': address,
        'note': note,
        'anhPath': anhPath,
        'photoUrl': photoUrl,
        'soLanGui': soLanGui,
      };

  static LuotChamCong? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      return LuotChamCong(
        maLuot: j['maLuot'] as String,
        userId: (j['userId'] as num).toInt(),
        actionType: j['actionType'] as String,
        lucBam: DateTime.parse(j['lucBam'] as String),
        mocBam: MocMay.fromJson(j['mocBam']),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        address: (j['address'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        anhPath: j['anhPath'] as String,
        photoUrl: j['photoUrl'] as String?,
        soLanGui: (j['soLanGui'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Thân yêu cầu gửi máy chủ. [daChoGiay] null = không đo được (máy khởi động lại).
  Map<String, dynamic> thanYeuCau(int? daChoGiay) => {
        'latitude': lat,
        'longitude': lng,
        'address': address,
        'photoUrl': photoUrl,
        'note': note,
        'actionType': actionType,
        'lucBam': lucBam.toUtc().toIso8601String(),
        'daChoGiay': daChoGiay,
        'maLuot': maLuot,
      };
}

enum TrangThaiGui { daNhan, choGuiLai, biTuChoi }

class KetQuaGui {
  final TrangThaiGui trangThai;

  /// Phản hồi của máy chủ khi đã nhận.
  final Map<String, dynamic>? phanHoi;

  /// Lỗi khi chưa gửi được / bị từ chối.
  final ApiFailure? loi;

  const KetQuaGui._(this.trangThai, this.phanHoi, this.loi);
  const KetQuaGui.daNhan(Map<String, dynamic> p) : this._(TrangThaiGui.daNhan, p, null);
  const KetQuaGui.choGuiLai(ApiFailure f) : this._(TrangThaiGui.choGuiLai, null, f);
  const KetQuaGui.biTuChoi(ApiFailure f) : this._(TrangThaiGui.biTuChoi, null, f);

  /// Máy chủ nhận nhưng để chờ duyệt (ngoài văn phòng, hoặc gửi chậm quá 30 phút).
  bool get choDuyet => (phanHoi?['data'] is Map) && phanHoi!['data']['status'] == 'PENDING';
}

/// Chấm công khi mạng kẹt: ghi nhận tại chỗ, gửi khi có mạng.
///
/// 18/11/2026 nhiều người bấm chấm công sát 08:45 thì mạng kẹt, báo lỗi, phải
/// chụp lại — vài phút sau mới gửi được và bị tính đi muộn. Giờ mỗi lần bấm được
/// giữ trên máy (ảnh, GPS, giờ bấm, đồng hồ tính từ lúc bật máy). Không gửi được
/// thì app tự gửi lại; máy chủ tính giờ chấm công theo LÚC BẤM (gửi chậm tới 30
/// phút tự nhận, quá 30 phút thì chờ duyệt — xem CheckinService.xetGioBam).
class HangChoChamCong extends GetxService {
  HangChoChamCong({
    CheckinService? service,
    UploadService? upload,
    Future<Directory> Function()? thuMucLuu,
    Future<MocMay?> Function()? docDongHo,
    int? Function()? nguoiDung,
    void Function(String tieuDe, String noiDung, Color mau)? thongBao,
  })  : _service = service ?? CheckinService(),
        _upload = upload ?? UploadService(),
        _thuMucLuu = thuMucLuu ?? getApplicationDocumentsDirectory,
        _docDongHo = docDongHo ?? DongHoMay.doc,
        _nguoiDung = nguoiDung ?? _nguoiDangDangNhap,
        _thongBao = thongBao ?? _snack;

  static HangChoChamCong? get instance =>
      Get.isRegistered<HangChoChamCong>() ? Get.find<HangChoChamCong>() : null;

  static const _khoa = 'hang_cho_cham_cong_v1';

  final CheckinService _service;
  final UploadService _upload;
  final Future<Directory> Function() _thuMucLuu;
  final Future<MocMay?> Function() _docDongHo;
  final int? Function() _nguoiDung;
  final void Function(String tieuDe, String noiDung, Color mau) _thongBao;

  static void _snack(String tieuDe, String noiDung, Color mau) => snack(tieuDe, noiDung,
      backgroundColor: mau, colorText: Colors.white, duration: const Duration(seconds: 8));

  /// Các lượt chưa gửi được (mọi tài khoản từng đăng nhập trên máy này).
  final ds = <LuotChamCong>[].obs;

  /// Sau mỗi lần gửi hộ trong nền: báo cho màn hình đang mở tải lại.
  final lanCapNhat = 0.obs;

  Timer? _hen;
  bool _dangGui = false;
  bool _tamDung = false;

  static int? _nguoiDangDangNhap() {
    if (!Get.isRegistered<AuthController>()) return null;
    final id = Get.find<AuthController>().currentUser['userId'];
    return id is int ? id : (id is num ? id.toInt() : null);
  }

  /// Lượt đang chờ gửi của người đang đăng nhập.
  List<LuotChamCong> get cuaToi {
    final uid = _nguoiDung();
    return ds.where((l) => l.userId == uid).toList();
  }

  LuotChamCong? luotChoCua(String actionType) =>
      cuaToi.firstWhereOrNull((l) => l.actionType == actionType);

  @override
  void onInit() {
    super.onInit();
    napLai().then((_) => guiLaiTatCa());
  }

  @override
  void onClose() {
    _hen?.cancel();
    super.onClose();
  }

  Future<void> napLai() async {
    try {
      final p = await SharedPreferences.getInstance();
      final chu = p.getString(_khoa);
      if (chu == null) return;
      final j = jsonDecode(chu);
      if (j is List) {
        ds.assignAll(j.map(LuotChamCong.fromJson).whereType<LuotChamCong>());
      }
    } catch (_) {}
  }

  Future<void> _luu() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_khoa, jsonEncode(ds.map((l) => l.toJson()).toList()));
    } catch (_) {}
  }

  /// Gửi một lần bấm mới. Không gửi được vì mạng / máy chủ thì giữ lại để tự gửi sau.
  Future<KetQuaGui> guiNgay(LuotChamCong l) async {
    final kq = await _gui(l);
    if (kq.trangThai == TrangThaiGui.choGuiLai) {
      await _them(l);
    }
    return kq;
  }

  Future<void> _them(LuotChamCong l) async {
    // Chép ảnh ra thư mục riêng: ảnh tạm có thể bị hệ điều hành dọn trước khi gửi được
    try {
      final goc = File(l.anhPath);
      if (await goc.exists()) {
        final thuMuc = Directory('${(await _thuMucLuu()).path}/cham_cong_cho');
        await thuMuc.create(recursive: true);
        final dich = '${thuMuc.path}/${l.maLuot}.jpg';
        await goc.copy(dich);
        l.anhPath = dich;
      }
    } catch (_) {}
    l.soLanGui = max(l.soLanGui, 1);
    ds.removeWhere((x) => x.maLuot == l.maLuot);
    ds.add(l);
    await _luu();
    _henGuiLai();
  }

  Future<void> _bo(LuotChamCong l) async {
    ds.removeWhere((x) => x.maLuot == l.maLuot);
    await _luu();
    try {
      if (l.anhPath.contains('cham_cong_cho')) await File(l.anhPath).delete();
    } catch (_) {}
  }

  Future<KetQuaGui> _gui(LuotChamCong l) async {
    try {
      if (l.photoUrl == null) {
        final url = await _upload.uploadFile(File(l.anhPath));
        if (url == null) throw 'Không thể upload ảnh lên máy chủ';
        l.photoUrl = url;
        if (ds.any((x) => x.maLuot == l.maLuot)) await _luu();
      }
      final daCho = DongHoMay.daTroiQuaGiay(l.mocBam, await _docDongHo());
      final phanHoi = await _service.submitCheckin(l.thanYeuCau(daCho));
      return KetQuaGui.daNhan(phanHoi);
    } catch (e) {
      final f = describeApiFailure(e, action: 'chấm công');
      // Mạng, máy chủ lỗi, hết phiên đăng nhập → giữ lại gửi sau. Máy chủ từ chối
      // hẳn (sai dữ liệu, lượt của hôm trước) hay ảnh trên máy hỏng → bỏ, báo lại.
      final giuLai = f.worthRetrying || f.kind == ApiFailureKind.auth;
      return giuLai ? KetQuaGui.choGuiLai(f) : KetQuaGui.biTuChoi(f);
    }
  }

  /// Gửi lại các lượt đang chờ của người đang đăng nhập.
  ///
  /// [chuDong]: người dùng bấm "Gửi lại ngay" — vẫn chưa được thì báo lý do.
  Future<void> guiLaiTatCa({bool chuDong = false}) async {
    if (_dangGui) return;
    _dangGui = true;
    try {
      for (final l in cuaToi) {
        final kq = await _gui(l);
        switch (kq.trangThai) {
          case TrangThaiGui.daNhan:
            await _bo(l);
            _baoDaGui(l, kq);
            lanCapNhat.value++;
          case TrangThaiGui.biTuChoi:
            await _bo(l);
            _thongBao('Lượt chấm công ${l.moTa} không được nhận', kq.loi!.message, Colors.red.shade700);
            lanCapNhat.value++;
          case TrangThaiGui.choGuiLai:
            l.soLanGui++;
            await _luu();
            if (chuDong) {
              _thongBao('Vẫn chưa gửi được',
                  '${kq.loi!.message}\nLượt ${l.moTa} vẫn được giữ, app tự gửi lại.', Colors.orange.shade800);
            }
            return; // mạng vẫn kẹt — các lượt sau chờ lần tới
        }
      }
    } finally {
      _dangGui = false;
      _henGuiLai();
    }
  }

  /// Thông báo khi một lượt chờ đã gửi được.
  void _baoDaGui(LuotChamCong l, KetQuaGui kq) {
    if (Get.isRegistered<KpiController>()) Get.find<KpiController>().fetchKpiData();
    final cham = DateTime.now().difference(l.lucBam).inMinutes;
    if (kq.choDuyet) {
      final loi = kq.phanHoi?['message']?.toString() ?? 'Đang chờ Admin/Trưởng phòng duyệt.';
      _thongBao('Đã gửi chấm công ${l.moTa}', loi, Colors.orange.shade800);
    } else {
      _thongBao('Đã gửi chấm công ${l.moTa}',
          cham >= 1 ? 'Gửi chậm $cham phút do mạng — vẫn tính theo giờ bấm.' : 'Chấm công thành công.',
          Colors.green);
    }
  }

  /// App xuống nền: thôi tự gửi (đỡ tốn pin). Mở lại app: gửi lại ngay.
  void tamDung() {
    _tamDung = true;
    _hen?.cancel();
  }

  void tiepTuc() {
    _tamDung = false;
    guiLaiTatCa();
  }

  void _henGuiLai() {
    _hen?.cancel();
    if (_tamDung || cuaToi.isEmpty) return;
    // 20 giây một lần trong 5 phút đầu, sau đó 1 phút một lần
    final lan = cuaToi.map((l) => l.soLanGui).fold(0, max);
    _hen = Timer(Duration(seconds: lan < 15 ? 20 : 60), guiLaiTatCa);
  }
}
