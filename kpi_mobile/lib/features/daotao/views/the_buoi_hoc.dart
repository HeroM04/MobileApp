import 'package:flutter/material.dart';
import '../../../shared/widgets/history_date_list_view.dart';
import '../../../shared/widgets/the_lich_su.dart';

/// Thẻ một dòng trong Lịch sử → Buổi học.
///
/// Trước đây thẻ chỉ ghi "Buổi đào tạo" (máy chủ không gửi tên buổi). Giờ hiện
/// đúng tên buổi, loại buổi (kỹ năng / dự án), người hướng dẫn, được tính điểm
/// danh theo cách nào, và ghi chú vắng nếu nhân sự có gửi.

const _navy = Color(0xFF0F2C59);

/// Tên buổi: máy chủ mới gửi `sessionTitle`; bản cũ có thể lồng trong `session`.
String tenBuoiHoc(Map<String, dynamic> item) {
  final s = item['session'];
  final ten = item['sessionTitle'] ?? (s is Map ? s['title'] : null);
  final chu = ten?.toString().trim() ?? '';
  return chu.isEmpty ? 'Buổi đào tạo' : chu;
}

/// Mốc thời gian để xếp vào ngày: lúc điểm danh, chưa được tính thì ngày buổi học.
String? thoiDiemBuoiHoc(Map<String, dynamic> item) =>
    (item['attendedAt'] ?? item['sessionStartTime'])?.toString();

/// Trạng thái hiển thị của một dòng lịch sử buổi học.
class TrangThaiBuoiHoc {
  final String chu;
  final Color mau;
  final IconData bieuTuong;

  /// Đã được tính điểm danh (có mặt, tự tính theo nhóm, hay được miễn).
  final bool daTinh;
  const TrangThaiBuoiHoc(this.chu, this.mau, this.bieuTuong, {required this.daTinh});
}

TrangThaiBuoiHoc trangThaiBuoiHoc(Map<String, dynamic> item) {
  final nguon = (item['source'] ?? 'REAL').toString();
  const xanh = Color(0xFF15803D);
  switch (nguon) {
    case 'EXEMPT':
      return const TrangThaiBuoiHoc('Được miễn: ghi chú đã được duyệt', xanh, Icons.verified_rounded, daTinh: true);
    case 'SKILL_GROUP':
      return const TrangThaiBuoiHoc('Tự tính: đã học nhóm kỹ năng này ở buổi khác', xanh,
          Icons.check_circle_rounded, daTinh: true);
    case 'NOTE':
      switch ((item['noteStatus'] ?? 'PENDING').toString()) {
        case 'REJECTED':
          return TrangThaiBuoiHoc('Ghi chú bị từ chối, buổi này chưa được tính', Colors.red.shade700,
              Icons.cancel_rounded, daTinh: false);
        case 'APPROVED':
          return const TrangThaiBuoiHoc('Ghi chú đã được duyệt', xanh, Icons.verified_rounded, daTinh: true);
        default:
          return const TrangThaiBuoiHoc('Ghi chú đang chờ Admin duyệt', Color(0xFFB45309),
              Icons.hourglass_top_rounded, daTinh: false);
      }
    default:
      return TrangThaiBuoiHoc('Có mặt lúc ${formatIsoDate(item['attendedAt']?.toString())}', _navy,
          Icons.check_circle_rounded, daTinh: true);
  }
}

class TheBuoiHoc extends StatelessWidget {
  final Map<String, dynamic> item;
  const TheBuoiHoc({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final tt = trangThaiBuoiHoc(item);
    final s = item['session'];
    final nguoiHuongDan = (item['presenter'] ?? (s is Map ? s['presenter'] : null) ?? '').toString().trim();
    final laDuAn = item['trainingType']?.toString() == 'PROJECT';
    final ghiChu = item['note']?.toString().trim() ?? '';
    final loiAdmin = item['noteReviewNote']?.toString().trim() ?? '';
    final biTuChoi = item['noteStatus']?.toString() == 'REJECTED';
    final mauIcon = tt.daTinh ? Colors.green : tt.mau;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _navy.withValues(alpha: 0.08),
              child: const Icon(Icons.school_rounded, color: _navy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenBuoiHoc(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: _navy)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item['trainingType'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: laDuAn ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(laDuAn ? 'Dự án' : 'Kỹ năng',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: laDuAn ? const Color(0xFF9A3412) : const Color(0xFF1D4ED8))),
                        ),
                      if (nguoiHuongDan.isNotEmpty)
                        Text('Giảng viên: $nguoiHuongDan',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tt.chu, style: TextStyle(fontSize: 12, color: tt.mau, fontWeight: FontWeight.w600)),
                  if (ghiChu.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('Ghi chú: “$ghiChu”',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3)),
                    ),
                  if (biTuChoi)
                    DongLyDoTuChoi(loiAdmin)
                  else if (loiAdmin.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('Admin ghi: “$loiAdmin”',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(tt.bieuTuong, color: mauIcon, size: 22),
          ],
        ),
      ),
    );
  }
}
