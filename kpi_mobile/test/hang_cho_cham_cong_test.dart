import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:kpi_mobile/core/utils/dong_ho_may.dart';
import 'package:kpi_mobile/data/services/checkin_service.dart';
import 'package:kpi_mobile/data/services/hang_cho_cham_cong.dart';
import 'package:kpi_mobile/data/services/upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chấm công khi mạng kẹt (18/11/2026): bấm sát 08:45, mạng kẹt, báo lỗi, phải
/// chụp lại và bị tính muộn. Giờ lần bấm được giữ trên máy, tự gửi lại, máy chủ
/// tính theo giờ bấm.

DioException _ket() => DioException(
    requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionTimeout);

DioException _maChu(int ma, String loi) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: ma, data: {'status': 'ERROR', 'message': loi}),
    type: DioExceptionType.badResponse,
  );
}

class _TaiAnhGia extends UploadService {
  int soLan = 0;
  Object? loi;
  @override
  Future<String?> uploadFile(File goc) async {
    soLan++;
    if (loi != null) throw loi!;
    return 'https://anh/${goc.uri.pathSegments.last}';
  }
}

class _MayChuGia extends CheckinService {
  final nhan = <Map<String, dynamic>>[];
  Object? loi;
  String trangThai = 'APPROVED';
  @override
  Future<Map<String, dynamic>> submitCheckin(Map<String, dynamic> data) async {
    if (loi != null) throw loi!;
    nhan.add(data);
    return {'status': 'SUCCESS', 'message': 'ok', 'data': {'id': nhan.length, 'status': trangThai}};
  }
}

void main() {
  late Directory thuMuc;
  late _TaiAnhGia taiAnh;
  late _MayChuGia mayChu;
  late HangChoChamCong hang;
  late List<String> thongBao;
  MocMay? dongHo;
  var uid = 7;

  Future<File> anh() async {
    final f = File('${thuMuc.path}/tam_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await f.writeAsBytes([1, 2, 3]);
    return f;
  }

  Future<LuotChamCong> luot({String loai = 'CHECK_IN', int? nguoi}) async => LuotChamCong(
        maLuot: LuotChamCong.taoMa(nguoi ?? uid),
        userId: nguoi ?? uid,
        actionType: loai,
        lucBam: DateTime(2026, 11, 18, 8, 44),
        mocBam: const MocMay(1000000, 5000),
        lat: 21.0,
        lng: 105.8,
        address: 'Văn phòng',
        note: '',
        anhPath: (await anh()).path,
      );

  HangChoChamCong taoHang() => HangChoChamCong(
        service: mayChu,
        upload: taiAnh,
        thuMucLuu: () async => thuMuc,
        docDongHo: () async => dongHo,
        nguoiDung: () => uid,
        thongBao: (tieuDe, noiDung, _) => thongBao.add('$tieuDe | $noiDung'),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    thuMuc = await Directory.systemTemp.createTemp('hang_cho_');
    taiAnh = _TaiAnhGia();
    mayChu = _MayChuGia();
    dongHo = const MocMay(1180000, 5000); // 180 giây sau lúc bấm, cùng lần bật máy
    uid = 7;
    thongBao = [];
    hang = taoHang();
  });

  tearDown(() async {
    hang.tamDung();
    Get.reset();
    try {
      await thuMuc.delete(recursive: true);
    } catch (_) {}
  });

  group('đo thời gian chờ bằng đồng hồ tính từ lúc bật máy', () {
    test('cùng lần bật máy → số giây thật', () {
      expect(DongHoMay.daTroiQuaGiay(const MocMay(1000000, 5000), const MocMay(1180500, 5100)), 180);
    });
    test('máy khởi động lại / giờ điện thoại bị chỉnh → không đo được (máy chủ bắt chờ duyệt)', () {
      expect(DongHoMay.daTroiQuaGiay(const MocMay(9000000, 5000), const MocMay(60000, 9000000)), isNull);
      expect(DongHoMay.daTroiQuaGiay(const MocMay(1000000, 5000), const MocMay(1180000, 5000 + 10 * 60000)), isNull);
    });
    test('thiếu một lần đọc → không đo được', () {
      expect(DongHoMay.daTroiQuaGiay(null, const MocMay(1, 1)), isNull);
    });
  });

  test('có mạng: gửi một lần, kèm giờ bấm, thời gian chờ và mã lượt', () async {
    final l = await luot();
    final kq = await hang.guiNgay(l);
    expect(kq.trangThai, TrangThaiGui.daNhan);
    expect(hang.ds, isEmpty);
    final than = mayChu.nhan.single;
    expect(than['daChoGiay'], 180);
    expect(than['maLuot'], l.maLuot);
    expect(than['lucBam'], DateTime(2026, 11, 18, 8, 44).toUtc().toIso8601String());
    expect(than['photoUrl'], startsWith('https://anh/'));
  });

  test('mạng kẹt: giữ lần bấm trên máy (cả ảnh), không bắt chụp lại', () async {
    mayChu.loi = _ket();
    final l = await luot();
    final kq = await hang.guiNgay(l);
    expect(kq.trangThai, TrangThaiGui.choGuiLai);
    expect(hang.cuaToi.single.maLuot, l.maLuot);
    expect(hang.luotChoCua('CHECK_IN'), isNotNull);
    expect(hang.luotChoCua('CHECK_OUT'), isNull);
    // Ảnh được chép vào thư mục riêng, không dựa vào ảnh tạm
    expect(hang.cuaToi.single.anhPath, contains('cham_cong_cho'));
    expect(File(hang.cuaToi.single.anhPath).existsSync(), isTrue);

    // Tắt app mở lại: vẫn còn
    final moLai = taoHang();
    await moLai.napLai();
    expect(moLai.cuaToi.single.maLuot, l.maLuot);
    moLai.tamDung();
  });

  test('có mạng lại: tự gửi đúng lần bấm cũ, ảnh đã tải thì không tải lại', () async {
    {
      mayChu.loi = _ket();
      final l = await luot();
      await hang.guiNgay(l);
      expect(taiAnh.soLan, 1);

      mayChu.loi = null;
      dongHo = const MocMay(1000000 + 600000, 5000); // 10 phút sau mới có mạng
      await hang.guiLaiTatCa();
      expect(hang.ds, isEmpty);
      expect(mayChu.nhan.single['maLuot'], l.maLuot);
      expect(mayChu.nhan.single['daChoGiay'], 600);
      expect(taiAnh.soLan, 1, reason: 'ảnh đã lên rồi, gửi lại chỉ gửi thông tin');
      expect(File(l.anhPath).existsSync(), isFalse, reason: 'gửi xong thì dọn ảnh đã chép vào thư mục riêng');
      expect(thongBao.single, contains('Gửi chậm'));
    }
  });

  test('máy chủ từ chối hẳn (4xx) → không giữ lại, báo lý do', () async {
    mayChu.loi = _maChu(400, 'Vui lòng nhập lý do chấm công ngoại tuyến.');
    final kq = await hang.guiNgay(await luot());
    expect(kq.trangThai, TrangThaiGui.biTuChoi);
    expect(kq.loi!.message, contains('lý do'));
    expect(hang.ds, isEmpty);
  });

  test('hết phiên đăng nhập (401) → vẫn giữ, đăng nhập lại là gửi', () async {
    mayChu.loi = _maChu(401, 'Hết hạn');
    final kq = await hang.guiNgay(await luot());
    expect(kq.trangThai, TrangThaiGui.choGuiLai);
    expect(hang.ds, hasLength(1));
  });

  test('tải ảnh lên cũng kẹt → giữ lại', () async {
    taiAnh.loi = _ket();
    final kq = await hang.guiNgay(await luot());
    expect(kq.trangThai, TrangThaiGui.choGuiLai);
    expect(hang.ds.single.photoUrl, isNull);
  });

  test('lượt của người khác (đã đăng xuất) → không gửi hộ', () async {
    {
      mayChu.loi = _ket();
      await hang.guiNgay(await luot(nguoi: 99));
      mayChu.loi = null;
      await hang.guiLaiTatCa();
      expect(mayChu.nhan, isEmpty);
      expect(hang.ds, hasLength(1));
      expect(hang.cuaToi, isEmpty);
    }
  });

  test('máy chủ nhận nhưng chờ duyệt (gửi chậm quá 30 phút) → KetQuaGui.choDuyet', () async {
    mayChu.trangThai = 'PENDING';
    final kq = await hang.guiNgay(await luot());
    expect(kq.trangThai, TrangThaiGui.daNhan);
    expect(kq.choDuyet, isTrue);
  });

  test('lưu / đọc lại một lần bấm giữ nguyên mọi thông tin', () async {
    final l = await luot(loai: 'CHECK_OUT');
    l.photoUrl = 'https://anh/x.jpg';
    final doc = LuotChamCong.fromJson(l.toJson())!;
    expect(doc.maLuot, l.maLuot);
    expect(doc.actionType, 'CHECK_OUT');
    expect(doc.lucBam.toUtc(), l.lucBam.toUtc());
    expect(doc.mocBam!.msTuLucBat, 1000000);
    expect(doc.photoUrl, 'https://anh/x.jpg');
    expect(doc.moTa, startsWith('RA lúc'));
  });
}
