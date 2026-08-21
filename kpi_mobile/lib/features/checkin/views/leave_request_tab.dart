import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/leave_controller.dart';
import '../../../core/widgets/thong_bao.dart';

/// Tab "XIN VẮNG" trong màn hình Điểm danh.
///
/// Nhân sự chọn ngày nghỉ + nhập lý do rồi gửi. Admin duyệt trên WebAdmin thì
/// ngày đó là vắng có phép (−10đ). Không gửi đơn mà cũng không chấm công thì
/// cuối ngày hệ thống tự chấm vắng không phép (−15đ).
class LeaveRequestTab extends StatefulWidget {
  const LeaveRequestTab({super.key});

  @override
  State<LeaveRequestTab> createState() => _LeaveRequestTabState();
}

class _LeaveRequestTabState extends State<LeaveRequestTab> {
  final LeaveController controller = Get.put(LeaveController());
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  static const Color _navy = Color(0xFF0F2C59);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final err = await controller.submit(date: _selectedDate, reason: _reasonController.text);
    if (!mounted) return;
    if (err == null) {
      _reasonController.clear();
      snack(
        'Đã gửi đơn',
        'Đơn xin vắng đã gửi tới Admin, chờ xét duyệt.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } else {
      snack('Không gửi được', err,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildForm(),
          const SizedBox(height: 20),
          const Text('ĐƠN ĐÃ GỬI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _navy)),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.myRequests.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text('Bạn chưa gửi đơn xin vắng nào.',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
              );
            }
            return Column(
              children: controller.myRequests.map(_buildRequestCard).toList(),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xin vắng có phép',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
          const SizedBox(height: 6),
          const Text(
            'Gửi trước để Admin xét duyệt. Đơn được duyệt tính là vắng có phép (−10đ KPI). '
            'Không gửi đơn mà cũng không chấm công sẽ bị tính vắng không phép (−15đ).',
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
          const Divider(height: 24),

          const Text('NGÀY XIN VẮNG',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Color(0xFF1B3B6F), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _formatVi(_selectedDate),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _navy),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_outlined, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('LÝ DO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Nghỉ khám sức khỏe định kỳ tại bệnh viện...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 4),

          Obx(() => ElevatedButton.icon(
                onPressed: controller.isSubmitting.value ? null : _submit,
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  controller.isSubmitting.value ? 'ĐANG GỬI...' : 'GỬI ĐƠN XIN VẮNG',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> r) {
    final status = (r['status'] ?? 'PENDING').toString();
    final meta = _statusMeta(status);
    final dateStr = _formatYmd(r['leaveDate']?.toString());
    final canCancel = status == 'PENDING';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(meta.icon, size: 20, color: meta.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(meta.label,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: meta.color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(r['reason']?.toString() ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35)),
            if ((r['reviewNote']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Ghi chú Admin: ${r['reviewNote']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            if (canCancel)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final err = await controller.cancel(r['id'] as int);
                    if (err != null) {
                      snack('Không hủy được', err,
                          backgroundColor: Colors.redAccent, colorText: Colors.white);
                    }
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('Hủy đơn',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tự đặt tên thứ tiếng Việt — app chưa nạp gói ngôn ngữ nên không dùng
  /// được DateFormat với locale 'vi'.
  static const List<String> _weekdayVi = [
    'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
  ];

  String _formatVi(DateTime d) =>
      '${_weekdayVi[d.weekday - 1]}, ${DateFormat('dd/MM/yyyy').format(d)}';

  String _formatYmd(String? ymd) {
    if (ymd == null || ymd.length < 10) return '—';
    try {
      return _formatVi(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  _StatusMeta _statusMeta(String status) {
    switch (status) {
      case 'APPROVED':
        return const _StatusMeta('Có phép (−10đ)', Colors.green, Icons.verified_rounded);
      case 'REJECTED':
        return const _StatusMeta('Bị từ chối', Colors.grey, Icons.cancel_outlined);
      case 'UNEXCUSED':
        return const _StatusMeta('Không phép (−15đ)', Colors.redAccent, Icons.report_gmailerrorred_rounded);
      default:
        return const _StatusMeta('Chờ duyệt', Colors.orange, Icons.hourglass_top_rounded);
    }
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusMeta(this.label, this.color, this.icon);
}
