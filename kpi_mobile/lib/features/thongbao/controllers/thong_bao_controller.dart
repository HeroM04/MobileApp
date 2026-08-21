import 'package:get/get.dart';

import '../../../core/network/api_error.dart';
import '../../../data/services/kpi_service.dart';

/// Màn hình Thông báo: lịch sử từng khoản điểm KPI được cộng và bị trừ.
///
/// Xem theo tuần hoặc theo tháng, lật về các kỳ trước bằng [lui]. Mỗi lần mở
/// màn hình thì đánh dấu đã xem để huy hiệu đỏ về 0.
class ThongBaoController extends GetxController {
  final _kpiService = KpiService();

  /// 'week' hoặc 'month'.
  final loai = 'week'.obs;

  /// Số kỳ lùi về trước: 0 là kỳ hiện tại.
  final lui = 0.obs;

  final dangTai = false.obs;
  final loi = RxnString();

  final nhanKy = ''.obs;
  final laKyHienTai = true.obs;
  final conKyCuHon = false.obs;

  final tongCong = 0.obs;
  final tongTru = 0.obs;
  final diemKy = 0.obs;
  final tranKy = 0.obs;

  final theoNhom = <Map<String, dynamic>>[].obs;
  final khoanDiem = <Map<String, dynamic>>[].obs;

  /// Huy hiệu đỏ trên biểu tượng Thông báo.
  final soChuaDoc = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tai();
    danhDauDaXem();
  }

  Future<void> tai() async {
    dangTai.value = true;
    loi.value = null;
    try {
      final res = await _kpiService.layNhatKy(loai: loai.value, lui: lui.value);
      final d = res['data'] as Map<String, dynamic>? ?? {};

      nhanKy.value = d['periodLabel']?.toString() ?? '';
      laKyHienTai.value = d['isCurrent'] == true;
      conKyCuHon.value = d['hasOlder'] == true;
      tongCong.value = (d['totalPlus'] as num?)?.toInt() ?? 0;
      tongTru.value = (d['totalMinus'] as num?)?.toInt() ?? 0;
      diemKy.value = (d['periodScore'] as num?)?.toInt() ?? 0;
      tranKy.value = (d['periodMax'] as num?)?.toInt() ?? 0;

      theoNhom.assignAll(
          List<Map<String, dynamic>>.from(d['byCategory'] as List? ?? const []));
      khoanDiem.assignAll(
          List<Map<String, dynamic>>.from(d['items'] as List? ?? const []));
    } catch (e) {
      loi.value = describeApiFailure(e, action: 'tải lịch sử điểm KPI').message;
      khoanDiem.clear();
      theoNhom.clear();
    } finally {
      dangTai.value = false;
    }
  }

  void doiLoai(String moi) {
    if (loai.value == moi) return;
    loai.value = moi;
    lui.value = 0; // đổi cách xem thì quay về kỳ hiện tại
    tai();
  }

  /// Lùi về kỳ cũ hơn. Không cho lùi quá dữ liệu đang có.
  void kyTruoc() {
    if (!conKyCuHon.value) return;
    lui.value++;
    tai();
  }

  /// Tiến về kỳ gần hơn. Đến kỳ hiện tại thì dừng.
  void kySau() {
    if (lui.value == 0) return;
    lui.value--;
    tai();
  }

  Future<void> danhDauDaXem() async {
    try {
      await _kpiService.danhDauDaXem();
      soChuaDoc.value = 0;
    } catch (_) {
      // Không quan trọng tới mức phải báo lỗi cho người dùng.
    }
  }

  Future<void> capNhatSoChuaDoc() async {
    try {
      soChuaDoc.value = await _kpiService.demChuaDoc();
    } catch (_) {
      // Giữ nguyên con số cũ nếu không lấy được.
    }
  }
}
