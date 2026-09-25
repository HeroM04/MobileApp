import 'dart:async';

import 'package:get/get.dart';

/// Tín hiệu "dữ liệu loại X vừa đổi trên máy chủ" — trung tâm đồng bộ web → app.
///
/// Web và app dùng chung một DB, nhưng app chỉ tải danh sách khi mở màn hình:
/// Admin duyệt bài trên web mà nhân sự vẫn thấy "chờ duyệt" cho tới khi tự
/// thoát ra vào lại. Máy chủ giờ nhắn một tin ngắn sau mỗi lần thêm/sửa/xóa
/// (xem DongBoListener bên backend); tin đó đi qua đây rồi tới đúng chỗ cần
/// tải lại:
///
/// * Danh sách lịch sử (chấm công, bài đăng, thực chiến, chốt căn, đào tạo,
///   phản hồi) dùng chung [HistoryDateListView] — widget đó nghe [phienBan]
///   của loại mình và tự tải lại.
/// * Các controller giữ danh sách riêng (đơn vắng, gieo hạt, phòng đào tạo…)
///   được gọi thẳng qua [dangKy].
///
/// Tên loại phải khớp `DongBoListener.phanLoai` bên máy chủ.
class DongBo {
  DongBo._();

  static const chamCong = 'CHAM_CONG';
  static const donVang = 'DON_VANG';
  static const thucChien = 'THUC_CHIEN';
  static const chotCan = 'CHOT_CAN';
  static const baiDang = 'BAI_DANG';
  static const phanHoi = 'PHAN_HOI';
  static const gieoHat = 'GIEO_HAT';
  static const daoTao = 'DAO_TAO';
  static const hoSo = 'HO_SO';
  static const kpi = 'KPI';

  static const cacLoai = [chamCong, donVang, thucChien, chotCan, baiDang, phanHoi, gieoHat, daoTao, hoSo, kpi];

  /// Gom các tin cùng loại tới dồn dập thành một lần tải: Admin duyệt 20 bài
  /// liền tay hay tác vụ đêm ghi vắng cho cả công ty thì app chỉ tải lại một lần.
  static const gom = Duration(milliseconds: 800);

  static final Map<String, RxInt> _phienBan = {};
  static final Map<String, Timer> _choGom = {};
  static final Map<String, List<void Function()>> _nguoiNghe = {};

  /// Số lần loại dữ liệu này đã đổi. Widget dùng `ever(DongBo.phienBan(loai), …)`.
  static RxInt phienBan(String loai) => _phienBan.putIfAbsent(loai, () => 0.obs);

  /// Đăng ký một việc cần làm khi loại dữ liệu này đổi. Trả về hàm để hủy —
  /// gọi trong onClose của controller, không thì controller đã đóng vẫn bị gọi.
  static void Function() dangKy(String loai, void Function() viec) {
    final ds = _nguoiNghe.putIfAbsent(loai, () => []);
    ds.add(viec);
    return () => ds.remove(viec);
  }

  /// Máy chủ báo loại [loai] vừa đổi. Loại lạ (máy chủ bản mới hơn app) thì bỏ qua.
  static void bao(String loai) {
    if (!cacLoai.contains(loai)) return;
    _choGom[loai]?.cancel();
    _choGom[loai] = Timer(gom, () => _phat(loai));
  }

  /// Mở lại app từ nền: WebSocket có thể đã rớt, tin trong lúc đó bị lỡ —
  /// coi như mọi thứ đều có thể đã đổi.
  static void baoTatCa() {
    for (final l in cacLoai) {
      bao(l);
    }
  }

  static void _phat(String loai) {
    _choGom.remove(loai);
    phienBan(loai).value++;
    for (final viec in List.of(_nguoiNghe[loai] ?? const <void Function()>[])) {
      try {
        viec();
      } catch (_) {
        // Một chỗ tải lại hỏng không được chặn các chỗ khác
      }
    }
  }

  /// Chỉ dùng trong kiểm thử: xóa sạch trạng thái giữa các test.
  static void datLai() {
    for (final t in _choGom.values) {
      t.cancel();
    }
    _choGom.clear();
    _phienBan.clear();
    _nguoiNghe.clear();
  }
}
