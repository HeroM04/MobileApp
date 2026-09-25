import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/dong_bo.dart';

/// Widget dùng chung cho tất cả History Tab - có DatePicker và danh sách lịch sử
class HistoryDateListView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String date) onFetchHistory;
  final Widget Function(Map<String, dynamic> item, int index) itemBuilder;
  final String emptyMessage;

  /// Loại dữ liệu để tự tải lại khi máy chủ báo đổi (xem [DongBo]). Có loại
  /// này thì Admin duyệt/sửa/xóa trên web là danh sách cập nhật ngay, nhân sự
  /// không phải thoát ra vào lại.
  final String? loaiDongBo;

  const HistoryDateListView({
    super.key,
    required this.onFetchHistory,
    required this.itemBuilder,
    this.emptyMessage = 'Không có dữ liệu trong ngày này.',
    this.loaiDongBo,
  });

  @override
  State<HistoryDateListView> createState() => _HistoryDateListViewState();
}

class _HistoryDateListViewState extends State<HistoryDateListView> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  Worker? _ngheDongBo;

  @override
  void initState() {
    super.initState();
    _fetchForDate(_selectedDate);
    final loai = widget.loaiDongBo;
    if (loai != null) {
      // Tải lại đúng ngày đang xem, không kéo người dùng về hôm nay
      _ngheDongBo = ever(DongBo.phienBan(loai), (_) => _fetchForDate(_selectedDate, imLang: true));
    }
  }

  @override
  void dispose() {
    _ngheDongBo?.dispose();
    super.dispose();
  }

  String _formatDateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _formatDateDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// [imLang]: tải lại do máy chủ báo đổi — không hiện vòng xoay che danh sách,
  /// và tải hỏng thì giữ danh sách cũ thay vì xóa trắng (mạng chập chờn một
  /// nhịp không được làm mất thứ người dùng đang xem).
  Future<void> _fetchForDate(DateTime date, {bool imLang = false}) async {
    if (!mounted) return;
    if (!imLang) setState(() => _isLoading = true);
    try {
      final result = await widget.onFetchHistory(_formatDateParam(date));
      // Người dùng đã chọn ngày khác trong lúc chờ → bỏ kết quả cũ
      if (!mounted || date != _selectedDate) return;
      setState(() => _items = result);
    } catch (e) {
      if (!mounted || imLang) return;
      setState(() => _items = []);
    } finally {
      if (mounted && !imLang) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F2C59),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F2C59),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- DatePicker Header ---
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2C59),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Ngày: ${_formatDateDisplay(_selectedDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),
        ),

        // --- Content ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F2C59)))
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            widget.emptyMessage,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: _items.length,
                      itemBuilder: (ctx, idx) => widget.itemBuilder(_items[idx], idx),
                    ),
        ),
      ],
    );
  }
}

/// Helper: Format ngày từ ISO string sang dd/MM/yyyy HH:mm
String formatIsoDate(String? iso) {
  if (iso == null || iso.isEmpty) return 'Không rõ';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year} $h:$m';
  } catch (_) {
    return iso;
  }
}

/// Helper: Màu trạng thái
Color statusColor(String? status) {
  switch (status?.toUpperCase()) {
    case 'APPROVED':
      return Colors.green;
    case 'PENDING':
      return Colors.orange;
    case 'REJECTED':
      return Colors.red;
    case 'UNREAD':
      return Colors.blue;
    case 'READ':
      return Colors.grey;
    case 'RESOLVED':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/// Helper: Label trạng thái tiếng Việt
String statusLabel(String? status) {
  switch (status?.toUpperCase()) {
    case 'APPROVED':
      return 'Đã duyệt';
    case 'PENDING':
      return 'Đang chờ';
    case 'REJECTED':
      return 'Từ chối';
    case 'UNREAD':
      return 'Chưa đọc';
    case 'READ':
      return 'Đã đọc';
    case 'RESOLVED':
      return 'Đã giải quyết';
    default:
      return status ?? 'Không rõ';
  }
}
