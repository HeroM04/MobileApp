import 'package:flutter_test/flutter_test.dart';
import 'package:kpi_mobile/core/utils/dong_bo.dart';
import 'package:kpi_mobile/data/services/websocket_service.dart';

/// Trung tâm đồng bộ web → app.
///
/// Sai ở đây thì hỏng theo kiểu không ai thấy lỗi: Admin duyệt bài trên web,
/// app vẫn im lặng "chờ duyệt"; hoặc tác vụ đêm ghi vắng cho cả công ty làm app
/// tải lại hàng trăm lần một lúc.
Future<void> choGom() => Future.delayed(DongBo.gom + const Duration(milliseconds: 150));

void main() {
  setUp(DongBo.datLai);

  test('báo một loại → phiên bản loại đó tăng và việc đã đăng ký được gọi', () async {
    var soLan = 0;
    DongBo.dangKy(DongBo.baiDang, () => soLan++);

    DongBo.bao(DongBo.baiDang);
    await choGom();

    expect(DongBo.phienBan(DongBo.baiDang).value, 1);
    expect(soLan, 1);
  });

  test('tin dồn dập cùng loại được gom thành MỘT lần tải lại', () async {
    var soLan = 0;
    DongBo.dangKy(DongBo.chamCong, () => soLan++);

    for (var i = 0; i < 20; i++) {
      DongBo.bao(DongBo.chamCong); // Admin duyệt 20 bản ghi liền tay
    }
    await choGom();

    expect(soLan, 1);
    expect(DongBo.phienBan(DongBo.chamCong).value, 1);
  });

  test('báo loại này không làm tải lại loại khác', () async {
    var daoTao = 0;
    DongBo.dangKy(DongBo.daoTao, () => daoTao++);

    DongBo.bao(DongBo.chotCan);
    await choGom();

    expect(daoTao, 0);
    expect(DongBo.phienBan(DongBo.daoTao).value, 0);
  });

  test('loại lạ (máy chủ bản mới hơn app) bị bỏ qua, không ném lỗi', () async {
    DongBo.bao('LOAI_CHUA_CO');
    await choGom();
    expect(DongBo.phienBan('LOAI_CHUA_CO').value, 0);
  });

  test('hủy đăng ký rồi thì không bị gọi nữa (controller đã đóng)', () async {
    var soLan = 0;
    final huy = DongBo.dangKy(DongBo.donVang, () => soLan++);
    huy();

    DongBo.bao(DongBo.donVang);
    await choGom();

    expect(soLan, 0);
  });

  test('một chỗ tải lại ném lỗi không chặn các chỗ khác', () async {
    var chayDuoc = false;
    DongBo.dangKy(DongBo.phanHoi, () => throw Exception('mất mạng'));
    DongBo.dangKy(DongBo.phanHoi, () => chayDuoc = true);

    DongBo.bao(DongBo.phanHoi);
    await choGom();

    expect(chayDuoc, isTrue);
  });

  test('mở lại app → mọi loại đều được tải lại', () async {
    DongBo.baoTatCa();
    await choGom();
    for (final loai in DongBo.cacLoai) {
      expect(DongBo.phienBan(loai).value, 1, reason: loai);
    }
  });

  group('đọc tin từ WebSocket', () {
    test('tin đúng dạng → báo đúng loại', () async {
      WebSocketService.nhanTinDongBo('{"loai":"THUC_CHIEN","thaoTac":"SUA","id":"12"}');
      await choGom();
      expect(DongBo.phienBan(DongBo.thucChien).value, 1);
    });

    test('tin hỏng, rỗng hay thiếu loại → bỏ qua, không ném lỗi', () async {
      WebSocketService.nhanTinDongBo(null);
      WebSocketService.nhanTinDongBo('không phải json');
      WebSocketService.nhanTinDongBo('{"thaoTac":"SUA"}');
      WebSocketService.nhanTinDongBo('[1,2,3]');
      await choGom();
      for (final loai in DongBo.cacLoai) {
        expect(DongBo.phienBan(loai).value, 0, reason: loai);
      }
    });
  });

  test('tên loại khớp với máy chủ (DongBoListener.phanLoai)', () {
    // Đổi tên một bên mà quên bên kia là tin tới nơi nhưng bị coi là "loại lạ"
    expect(DongBo.cacLoai, containsAll(<String>[
      'CHAM_CONG', 'DON_VANG', 'THUC_CHIEN', 'CHOT_CAN', 'BAI_DANG',
      'PHAN_HOI', 'GIEO_HAT', 'DAO_TAO', 'HO_SO',
    ]));
  });
}
