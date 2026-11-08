import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'history_date_list_view.dart';

const _navy = Color(0xFF0F2C59);

/// Giờ "HH:mm" từ chuỗi ISO. Danh sách lịch sử đã gom theo ngày (ô chọn ngày /
/// tiêu đề ngày) nên mỗi dòng chỉ cần giờ.
String gioTuIso(Object? iso) {
  final dt = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Lý do Admin từ chối ghi trong bản ghi: `rejectReason` (bài đăng, thực
/// chiến, đào tạo 1-1, chốt căn, chấm công) hoặc `reviewNote` (xin vắng,
/// gieo hạt). Chỉ trả khi bản ghi đang bị từ chối.
String? lyDoTuChoiCua(Map<String, dynamic> item) {
  if (!laTuChoi(item)) return null;
  for (final k in ['rejectReason', 'reviewNote']) {
    final v = item[k]?.toString().trim() ?? '';
    if (v.isNotEmpty) return v;
  }
  return null;
}

/// Dòng đỏ "Lý do từ chối: …" dưới mỗi thẻ lịch sử bị từ chối.
class DongLyDoTuChoi extends StatelessWidget {
  final String? lyDo;
  final int? soDong;
  const DongLyDoTuChoi(this.lyDo, {super.key, this.soDong = 2});

  @override
  Widget build(BuildContext context) {
    final s = lyDo?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        s.isEmpty ? 'Admin chưa ghi lý do từ chối.' : 'Lý do từ chối: $s',
        maxLines: soDong,
        overflow: soDong == null ? null : TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600, height: 1.3),
      ),
    );
  }
}

/// Hộp xem một yêu cầu bị từ chối cho các thẻ không dùng [xemChiTietLichSu]
/// (chấm công, chốt căn): vài dòng thông tin và lý do Admin ghi.
void xemYeuCauBiTuChoi({
  required String tieuDe,
  List<MapEntry<String, String>> thongTin = const [],
  String? lyDo,
}) {
  final dong = thongTin.where((e) => e.value.trim().isNotEmpty).toList();
  Get.dialog(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(tieuDe, style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 17)),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in dong)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '${e.key}: ', style: const TextStyle(color: Color(0xFF64748B))),
                TextSpan(text: e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]), style: const TextStyle(fontSize: 13, height: 1.35)),
            ),
          const SizedBox(height: 8),
          _HopLyDo(lyDo),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Get.back(), child: const Text('Đóng'))],
  ));
}

/// Ô đỏ chứa lý do từ chối trong hộp chi tiết.
class _HopLyDo extends StatelessWidget {
  final String? lyDo;
  const _HopLyDo(this.lyDo);

  @override
  Widget build(BuildContext context) {
    final s = lyDo?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LÝ DO TỪ CHỐI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
          const SizedBox(height: 4),
          Text(s.isEmpty ? 'Admin chưa ghi lý do.' : s,
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

/// Một báo cáo đã nộp trong tab Lịch sử (Đào tạo 1-1, Thực chiến, Bài đăng):
/// ảnh thu nhỏ, tiêu đề, nội dung tóm tắt, giờ nộp, nhãn trạng thái. Bấm vào
/// mở [xemChiTietLichSu].
///
/// Trước đây Thực chiến và Bài đăng chỉ hiện "Thực chiến 04/11/2026" hay
/// "Bài đăng · Facebook" — nhân sự không xem lại được mình đã gửi ảnh gì,
/// ghi chú gì.
class TheLichSu extends StatelessWidget {
  final String? anh;
  final IconData bieuTuong;
  final String tieuDe;
  final String? phu;
  final String? noiDung;
  final Object? submittedAt;
  final String trangThai;
  final VoidCallback onTap;

  /// Lý do Admin từ chối — hiện thành dòng đỏ khi [trangThai] là REJECTED.
  final String? lyDoTuChoi;

  const TheLichSu({
    super.key,
    required this.anh,
    required this.bieuTuong,
    required this.tieuDe,
    this.phu,
    this.noiDung,
    required this.submittedAt,
    required this.trangThai,
    required this.onTap,
    this.lyDoTuChoi,
  });

  @override
  Widget build(BuildContext context) {
    final coAnh = anh != null && anh!.isNotEmpty;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: coAnh
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(anh!, width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(bieuTuong, color: _navy)),
              )
            : CircleAvatar(
                backgroundColor: _navy.withValues(alpha: 0.08),
                child: Icon(bieuTuong, color: _navy, size: 22),
              ),
        title: Text(tieuDe, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phu != null && phu!.isNotEmpty)
                Text(phu!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              if (noiDung != null && noiDung!.isNotEmpty)
                Text(noiDung!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
              const SizedBox(height: 2),
              Text('Nộp lúc ${gioTuIso(submittedAt)}',
                  style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w600)),
              if (trangThai.toUpperCase() == 'REJECTED') DongLyDoTuChoi(lyDoTuChoi),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor(trangThai).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(statusLabel(trangThai),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor(trangThai))),
        ),
      ),
    );
  }
}

/// Hộp xem đủ một báo cáo đã nộp: trạng thái kèm lời giải thích, các dòng
/// thông tin (loại, khách hàng, dự án…), nội dung nhân sự ghi, link và ảnh.
///
/// [nhomDiem] là nhóm điểm được cộng khi duyệt, ví dụ "Thực chiến", "Lan tỏa".
void xemChiTietLichSu({
  required String tieuDe,
  required Object? submittedAt,
  required String trangThai,
  required String nhomDiem,
  List<MapEntry<String, String>> thongTin = const [],
  String? noiDung,
  String? link,
  String? anh,
  String? lyDoTuChoi,
}) {
  final tt = trangThai.toUpperCase();
  final yNghia = switch (tt) {
    'APPROVED' => 'Admin đã duyệt — điểm $nhomDiem đã được cộng (xem khoản điểm ở mục Thông báo).',
    'REJECTED' => 'Admin không duyệt nên không được cộng điểm. Sửa theo lý do bên dưới rồi gửi lại.',
    _ => 'Đang chờ Admin duyệt. Duyệt xong mới được cộng điểm $nhomDiem.',
  };
  final dong = thongTin.where((e) => e.value.trim().isNotEmpty).toList();
  Get.dialog(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(tieuDe, style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 17)),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nộp lúc: ${formatIsoDate(submittedAt?.toString())}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor(tt).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(yNghia, style: TextStyle(fontSize: 12.5, height: 1.4, color: statusColor(tt))),
          ),
          if (tt == 'REJECTED') ...[
            const SizedBox(height: 8),
            _HopLyDo(lyDoTuChoi),
          ],
          if (dong.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final e in dong)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${e.key}: ', style: const TextStyle(color: Color(0xFF64748B))),
                  TextSpan(text: e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]), style: const TextStyle(fontSize: 13, height: 1.35)),
              ),
          ],
          if (noiDung != null && noiDung.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(noiDung, style: const TextStyle(fontSize: 14, height: 1.45)),
          ],
          if (link != null && link.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(link.trim());
                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(link.trim(),
                  style: const TextStyle(fontSize: 13, color: Colors.blue, decoration: TextDecoration.underline)),
            ),
          ],
          if (anh != null && anh.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(anh, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('Không tải được ảnh.',
                      style: TextStyle(fontSize: 12, color: Colors.grey))),
            ),
          ],
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Get.back(), child: const Text('Đóng'))],
  ));
}
