import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/dong_bo.dart';

const _navy = Color(0xFF0F2C59);

/// Widget dùng chung cho tất cả History Tab - có DatePicker và danh sách lịch sử.
///
/// Truyền thêm [onFetchMonth] + [thoiDiemCua] thì có nút chuyển "Theo ngày /
/// Theo tháng": chế độ tháng tải cả tháng một lần rồi gom theo ngày, mỗi ngày
/// một tiêu đề, bên dưới là từng mục như khi xem theo ngày.
class HistoryDateListView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String date) onFetchHistory;
  final Widget Function(Map<String, dynamic> item, int index) itemBuilder;
  final String emptyMessage;

  /// Tải cả tháng, tham số dạng 'yyyy-MM'. Bỏ trống thì chỉ có xem theo ngày.
  final Future<List<Map<String, dynamic>>> Function(String month)? onFetchMonth;

  /// Mốc thời gian (chuỗi ISO) của một mục — để gom theo ngày ở chế độ tháng.
  final String? Function(Map<String, dynamic> item)? thoiDiemCua;
  final String emptyMessageThang;

  /// Loại dữ liệu để tự tải lại khi máy chủ báo đổi (xem [DongBo]). Có loại
  /// này thì Admin duyệt/sửa/xóa trên web là danh sách cập nhật ngay, nhân sự
  /// không phải thoát ra vào lại.
  final String? loaiDongBo;

  const HistoryDateListView({
    super.key,
    required this.onFetchHistory,
    required this.itemBuilder,
    this.emptyMessage = 'Không có dữ liệu trong ngày này.',
    this.onFetchMonth,
    this.thoiDiemCua,
    this.emptyMessageThang = 'Không có dữ liệu trong tháng này.',
    this.loaiDongBo,
  });

  @override
  State<HistoryDateListView> createState() => _HistoryDateListViewState();
}

class _HistoryDateListViewState extends State<HistoryDateListView> {
  DateTime _selectedDate = DateTime.now();
  DateTime _thangChon = DateTime(DateTime.now().year, DateTime.now().month);
  bool _theoThang = false;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  Worker? _ngheDongBo;

  bool get _coCheDoThang => widget.onFetchMonth != null && widget.thoiDiemCua != null;

  @override
  void initState() {
    super.initState();
    _taiLai();
    final loai = widget.loaiDongBo;
    if (loai != null) {
      // Tải lại đúng ngày/tháng đang xem, không kéo người dùng về hôm nay
      _ngheDongBo = ever(DongBo.phienBan(loai), (_) => _taiLai(imLang: true));
    }
  }

  @override
  void dispose() {
    _ngheDongBo?.dispose();
    super.dispose();
  }

  String _formatDateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _formatMonthParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  String _formatDateDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Khóa của thứ đang xem — kết quả về muộn mà khóa đã đổi thì bỏ.
  String get _khoaDangXem =>
      _theoThang ? 'm:${_formatMonthParam(_thangChon)}' : 'd:${_formatDateParam(_selectedDate)}';

  /// [imLang]: tải lại do máy chủ báo đổi — không hiện vòng xoay che danh sách,
  /// và tải hỏng thì giữ danh sách cũ thay vì xóa trắng (mạng chập chờn một
  /// nhịp không được làm mất thứ người dùng đang xem).
  Future<void> _taiLai({bool imLang = false}) async {
    if (!mounted) return;
    final khoa = _khoaDangXem;
    if (!imLang) setState(() => _isLoading = true);
    try {
      final result = _theoThang
          ? await widget.onFetchMonth!(_formatMonthParam(_thangChon))
          : await widget.onFetchHistory(_formatDateParam(_selectedDate));
      // Người dùng đã chọn ngày/tháng khác trong lúc chờ → bỏ kết quả cũ
      if (!mounted || khoa != _khoaDangXem) return;
      setState(() => _items = result);
    } catch (e) {
      if (!mounted || imLang || khoa != _khoaDangXem) return;
      setState(() => _items = []);
    } finally {
      if (mounted && !imLang && khoa == _khoaDangXem) {
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
              primary: _navy,
              onPrimary: Colors.white,
              onSurface: _navy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _taiLai();
    }
  }

  void _doiCheDo(bool theoThang) {
    if (theoThang == _theoThang) return;
    setState(() {
      _theoThang = theoThang;
      _items = [];
    });
    _taiLai();
  }

  bool get _laThangHienTai {
    final now = DateTime.now();
    return _thangChon.year == now.year && _thangChon.month == now.month;
  }

  void _luiThang(int buoc) {
    final moi = DateTime(_thangChon.year, _thangChon.month + buoc);
    final now = DateTime.now();
    if (moi.isAfter(DateTime(now.year, now.month)) || moi.isBefore(DateTime(2024))) return;
    setState(() => _thangChon = moi);
    _taiLai();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_coCheDoThang) _nutCheDo(),
        _theoThang ? _dauThang() : _dauNgay(),

        // --- Content ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _navy))
              : _items.isEmpty
                  ? _trong(_theoThang ? widget.emptyMessageThang : widget.emptyMessage)
                  : _theoThang
                      ? _danhSachThang()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: _items.length,
                          itemBuilder: (ctx, idx) => widget.itemBuilder(_items[idx], idx),
                        ),
        ),
      ],
    );
  }

  Widget _nutCheDo() {
    Widget nut(String chu, IconData icon, bool thang) {
      final chon = _theoThang == thang;
      return Expanded(
        child: GestureDetector(
          onTap: () => _doiCheDo(thang),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: chon ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: chon ? Border.all(color: const Color(0xFFE2E8F0)) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: chon ? _navy : Colors.grey),
                const SizedBox(width: 6),
                Text(chu,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: chon ? FontWeight.bold : FontWeight.w600,
                      color: chon ? _navy : Colors.grey,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        nut('Theo ngày', Icons.today_rounded, false),
        nut('Theo tháng', Icons.calendar_month_rounded, true),
      ]),
    );
  }

  Widget _dauNgay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _navy,
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
    );
  }

  Widget _dauThang() {
    final soNgay = nhomTheoNgay(_items, widget.thoiDiemCua!).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _luiThang(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            tooltip: 'Tháng trước',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Tháng ${_thangChon.month.toString().padLeft(2, '0')}/${_thangChon.year}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (!_isLoading && _items.isNotEmpty)
                  Text(
                    '$soNgay ngày · ${_items.length} lượt',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _laThangHienTai ? null : () => _luiThang(1),
            icon: Icon(Icons.chevron_right_rounded,
                color: _laThangHienTai ? Colors.white.withOpacity(0.3) : Colors.white),
            tooltip: 'Tháng sau',
          ),
        ],
      ),
    );
  }

  /// Danh sách tháng: mỗi ngày một tiêu đề, dưới là các mục của ngày đó
  /// (sớm → muộn). Ngày mới nhất ở trên cùng.
  Widget _danhSachThang() {
    final nhom = nhomTheoNgay(_items, widget.thoiDiemCua!);
    final dong = <Widget>[];
    for (final ngay in nhom) {
      dong.add(Padding(
        padding: EdgeInsets.only(top: dong.isEmpty ? 0 : 8, bottom: 8),
        child: Row(
          children: [
            Text(
              tenNgay(ngay.key),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _navy),
            ),
            const SizedBox(width: 8),
            Text('${ngay.value.length} lượt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            const Expanded(child: Divider(height: 1)),
          ],
        ),
      ));
      for (final item in ngay.value) {
        dong.add(widget.itemBuilder(item, _items.indexOf(item)));
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: dong,
    );
  }

  Widget _trong(String chu) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            chu,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Gom các mục theo NGÀY (giờ máy) của mốc thời gian: ngày mới nhất trước,
/// trong một ngày xếp sớm → muộn. Mục không đọc được thời gian thì bỏ qua.
List<MapEntry<DateTime, List<Map<String, dynamic>>>> nhomTheoNgay(
  List<Map<String, dynamic>> items,
  String? Function(Map<String, dynamic> item) thoiDiemCua,
) {
  final theoNgay = <DateTime, List<MapEntry<DateTime, Map<String, dynamic>>>>{};
  for (final item in items) {
    final s = thoiDiemCua(item);
    final t = s == null ? null : DateTime.tryParse(s)?.toLocal();
    if (t == null) continue;
    theoNgay.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(MapEntry(t, item));
  }
  final ngay = theoNgay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in ngay)
      MapEntry(d, ((theoNgay[d]!..sort((a, b) => a.key.compareTo(b.key))).map((e) => e.value).toList())),
  ];
}

/// "Thứ Hai, 05/10" — tiêu đề ngày trong danh sách tháng.
String tenNgay(DateTime d) {
  const thu = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];
  return '${thu[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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
