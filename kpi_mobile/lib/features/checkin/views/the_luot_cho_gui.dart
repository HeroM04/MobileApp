import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/hang_cho_cham_cong.dart';

/// Ô báo các lượt chấm công đã ghi nhận trên máy nhưng chưa gửi được vì mạng.
///
/// Nhân sự cần thấy ngay: lần bấm của mình KHÔNG mất, giờ chấm công vẫn là giờ
/// bấm, app đang tự gửi lại — để khỏi chụp lại liên tục hay hoảng vì sắp muộn.
class TheLuotChoGui extends StatelessWidget {
  const TheLuotChoGui({super.key});

  @override
  Widget build(BuildContext context) {
    final hang = HangChoChamCong.instance;
    if (hang == null) return const SizedBox.shrink();
    return Obx(() {
      hang.ds.length; // theo dõi thay đổi danh sách
      final ds = hang.cuaToi;
      if (ds.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 20, color: Color(0xFFC2410C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ds.length == 1 ? 'Chấm công ${ds.first.moTa} chưa gửi được' : '${ds.length} lượt chấm công chưa gửi được',
                    style: const TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (ds.length > 1)
              for (final l in ds)
                Padding(
                  padding: const EdgeInsets.only(left: 28, bottom: 2),
                  child: Text('• ${l.moTa}', style: const TextStyle(color: Color(0xFF9A3412), fontSize: 13)),
                ),
            const Padding(
              padding: EdgeInsets.only(left: 28, right: 6),
              child: Text(
                'Đã ghi nhận trên máy, app đang tự gửi lại khi có mạng — không cần chụp lại. '
                'Gửi được trong 30 phút vẫn tính đúng giờ bấm.',
                style: TextStyle(color: Color(0xFF9A3412), fontSize: 12.5, height: 1.4),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => hang.guiLaiTatCa(chuDong: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Gửi lại ngay'),
              ),
            ),
          ],
        ),
      );
    });
  }
}
