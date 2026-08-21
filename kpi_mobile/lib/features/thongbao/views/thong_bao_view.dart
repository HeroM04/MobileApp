import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/thong_bao_controller.dart';

/// Màn hình Thông báo — lịch sử từng khoản điểm KPI được cộng và bị trừ.
///
/// Trước đây nhân sự chỉ thấy con số tổng trên Trang chủ mà không biết nó ghép
/// từ đâu. Ở đây mỗi biến động là một dòng kèm câu giải thích, xem được theo
/// tuần hoặc theo tháng và lật về các kỳ trước.
class ThongBaoView extends StatelessWidget {
  const ThongBaoView({super.key});

  static const Color _navy = Color(0xFF0F2C59);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _cong = Color(0xFF16A34A);
  static const Color _tru = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ThongBaoController());

    return Column(
      children: [
        _boChonCachXem(c),
        _thanhChuyenKy(c),
        Expanded(
          child: Obx(() {
            if (c.dangTai.value && c.khoanDiem.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (c.loi.value != null) {
              return _khungLoi(c);
            }
            return RefreshIndicator(
              onRefresh: c.tai,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _theTongKet(c),
                  const SizedBox(height: 14),
                  if (c.khoanDiem.isEmpty)
                    _khungTrong(c)
                  else
                    ...c.khoanDiem.map(_dongKhoanDiem),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Tuần / Tháng ──────────────────────────────────────────────────────────

  Widget _boChonCachXem(ThongBaoController c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Obx(() {
        final theoTuan = c.loai.value == 'week';
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _nutCachXem('Theo tuần', theoTuan, () => c.doiLoai('week')),
              _nutCachXem('Theo tháng', !theoTuan, () => c.doiLoai('month')),
            ],
          ),
        );
      }),
    );
  }

  Widget _nutCachXem(String nhan, bool dangChon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: dangChon ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: dangChon
                ? [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            nhan,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: dangChon ? FontWeight.w800 : FontWeight.w600,
              color: dangChon ? _navy : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ── ← Kỳ →  ───────────────────────────────────────────────────────────────

  Widget _thanhChuyenKy(ThongBaoController c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Obx(() => Row(
            children: [
              _nutLat(
                icon: Icons.chevron_left_rounded,
                bat: c.conKyCuHon.value,
                onTap: c.kyTruoc,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      c.nhanKy.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: _navy),
                    ),
                    if (c.laKyHienTai.value)
                      const Text('Kỳ hiện tại',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _nutLat(
                icon: Icons.chevron_right_rounded,
                bat: !c.laKyHienTai.value,
                onTap: c.kySau,
              ),
            ],
          )),
    );
  }

  Widget _nutLat({required IconData icon, required bool bat, required VoidCallback onTap}) {
    return IconButton(
      onPressed: bat ? onTap : null,
      icon: Icon(icon, size: 28),
      color: _navy,
      disabledColor: const Color(0xFFCBD5E1),
      tooltip: bat ? null : 'Không còn kỳ nào',
    );
  }

  // ── Tổng kết kỳ ───────────────────────────────────────────────────────────

  Widget _theTongKet(ThongBaoController c) {
    return Obx(() {
      final diem = c.diemKy.value;
      final tran = c.tranKy.value;
      final tyLe = tran > 0 ? (diem / tran).clamp(0.0, 1.0) : 0.0;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
          boxShadow: [
            BoxShadow(color: _navy.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$diem',
                    style: const TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w900, color: _navy, height: 1)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text('/ $tran điểm',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ),
                const Spacer(),
                _vienDiem('+${c.tongCong.value}', _cong),
                const SizedBox(width: 6),
                _vienDiem('${c.tongTru.value}', c.tongTru.value == 0 ? const Color(0xFF94A3B8) : _tru),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: tyLe,
                minHeight: 7,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(_gold),
              ),
            ),
            if (c.theoNhom.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: c.theoNhom.map((n) {
                  final d = (n['points'] as num?)?.toInt() ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${n['label']} ${d >= 0 ? '+' : ''}$d',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: _navy),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _vienDiem(String chu, Color mau) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: mau.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(chu,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: mau)),
    );
  }

  // ── Một khoản điểm ────────────────────────────────────────────────────────

  Widget _dongKhoanDiem(Map<String, dynamic> k) {
    final thuc = (k['effectivePoints'] as num?)?.toInt() ?? 0;
    final quyDinh = (k['points'] as num?)?.toInt() ?? 0;
    final chamTran = k['capped'] == true;
    final duong = thuc > 0;
    final mau = thuc > 0 ? _cong : (thuc < 0 ? _tru : const Color(0xFF94A3B8));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _mauNhom(k['category']?.toString()).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_bieuTuongNhom(k['category']?.toString()),
                size: 20, color: _mauNhom(k['category']?.toString())),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k['reason']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: _navy, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  '${k['categoryLabel'] ?? ''} · ${_gioNgay(k['occurredAt']?.toString())}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                if (chamTran) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      thuc == 0
                          ? 'Nhóm này đã đạt điểm tối đa của tuần nên khoản ${quyDinh}đ không được cộng thêm'
                          : 'Quy định ${quyDinh}đ, nhưng nhóm sắp đầy nên chỉ vào được ${thuc}đ',
                      style: const TextStyle(
                          fontSize: 11, height: 1.3, color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${duong ? '+' : ''}$thuc',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: mau),
          ),
        ],
      ),
    );
  }

  Color _mauNhom(String? c) {
    switch (c) {
      case 'attendance':
        return _navy;
      case 'meeting':
        return _gold;
      case 'post':
        return const Color(0xFF0EA5E9);
      case 'deal':
        return _tru;
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _bieuTuongNhom(String? c) {
    switch (c) {
      case 'attendance':
        return Icons.fingerprint_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'post':
        return Icons.campaign_rounded;
      case 'deal':
        return Icons.domain_verification_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _gioNgay(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('HH:mm · dd/MM').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }

  // ── Trạng thái rỗng và lỗi ────────────────────────────────────────────────

  Widget _khungTrong(ThongBaoController c) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 14),
          Text(
            c.laKyHienTai.value
                ? 'Kỳ này chưa có biến động điểm nào'
                : 'Kỳ này không có biến động điểm',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Chấm công, đi gặp khách, đăng bài hay đi học đều được ghi lại ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _khungLoi(ThongBaoController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 14),
            Text(
              c.loi.value ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: c.tai,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
