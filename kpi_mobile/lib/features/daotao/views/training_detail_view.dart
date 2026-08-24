import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'qr_token_display.dart';
import 'qr_scanner_view.dart';
import '../../../core/network/api_error.dart';
import '../../../core/widgets/thong_bao.dart';
import '../../../data/services/training_service.dart';

class TrainingDetailView extends StatefulWidget {
  final TrainingRoom room;

  const TrainingDetailView({super.key, required this.room});

  @override
  State<TrainingDetailView> createState() => _TrainingDetailViewState();
}

class _TrainingDetailViewState extends State<TrainingDetailView> {
  final TrainingController controller = Get.find<TrainingController>();
  final AuthController authController = Get.find<AuthController>();

  bool _isScanning = false;
  bool _isEnding = false;

  /// Câu trả lời tham gia / xin vắng của mình cho buổi đào tạo dự án này.
  /// null nghĩa là chưa trả lời.
  Map<String, dynamic>? _traLoi;
  bool _dangGuiTraLoi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestData();
      if (widget.room.laDaoTaoDuAn) _napTraLoi();
    });
  }

  Future<void> _napTraLoi() async {
    try {
      final r = await TrainingService().traLoiCuaToi(widget.room.id);
      if (mounted) setState(() => _traLoi = r);
    } catch (_) {
      // Không lấy được thì cứ hiện hai nút như chưa trả lời
    }
  }

  Future<void> _loadLatestData() async {
    await controller.reloadRoomDetails(widget.room.id);
    if (mounted) {
      try {
        final updatedRoom = controller.rooms.firstWhere((r) => r.id == widget.room.id);
        widget.room.participants.assignAll(updatedRoom.participants);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Đào tạo dự án: tham gia hay xin vắng ─────────────────────────────────

  Future<void> _chonThamGia() async {
    setState(() => _dangGuiTraLoi = true);
    try {
      await TrainingService().dangKyThamGia(widget.room.id);
      await _napTraLoi();
      snack('Đã ghi nhận', 'Nhớ quét mã điểm danh khi đến buổi học nhé.',
          backgroundColor: const Color(0xFF16A34A), colorText: Colors.white);
    } catch (e) {
      final f = describeApiFailure(e, action: 'đăng ký tham gia');
      snack(f.title, f.message,
          backgroundColor: f.isUserFixable ? Colors.orange.shade800 : Colors.red.shade700,
          colorText: Colors.white, duration: const Duration(seconds: 4));
    } finally {
      if (mounted) setState(() => _dangGuiTraLoi = false);
    }
  }

  Future<void> _chonKhongThamGia() async {
    final lyDoController = TextEditingController();
    final lyDo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lý do không tham gia',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F2C59))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đây là buổi đào tạo dự án, mặc định mọi người đều phải tham gia. '
              'Ghi rõ lý do để Admin xem xét.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: lyDoController,
              maxLines: 3,
              maxLength: 500,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Tôi không bán dự án này, đang phụ trách dự án khác',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final v = lyDoController.text.trim();
              if (v.isEmpty) return; // nút không ăn khi chưa nhập gì
              Navigator.of(ctx).pop(v);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2C59),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: const Text('Gửi cho Admin'),
          ),
        ],
      ),
    );
    lyDoController.dispose();
    if (lyDo == null || lyDo.isEmpty) return;

    setState(() => _dangGuiTraLoi = true);
    try {
      await TrainingService().xinVangDaoTao(widget.room.id, lyDo);
      await _napTraLoi();
      snack('Đã gửi lý do', 'Admin sẽ xem xét. Được duyệt thì bạn vẫn được tính điểm danh.',
          backgroundColor: const Color(0xFFD4AF37), colorText: const Color(0xFF0F2C59),
          duration: const Duration(seconds: 4));
    } catch (e) {
      final f = describeApiFailure(e, action: 'gửi lý do xin vắng');
      snack(f.title, f.message,
          backgroundColor: f.isUserFixable ? Colors.orange.shade800 : Colors.red.shade700,
          colorText: Colors.white, duration: const Duration(seconds: 4));
    } finally {
      if (mounted) setState(() => _dangGuiTraLoi = false);
    }
  }

  /// Khối đăng ký tham gia — chỉ hiện với buổi đào tạo DỰ ÁN.
  Widget _khoiDangKy() {
    final choice = _traLoi?['choice']?.toString();
    final status = _traLoi?['status']?.toString();

    Widget khung({required Color vien, required Color nen, required List<Widget> con}) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: nen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vien, width: 1.2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: con),
        );

    const nhan = Text('ĐÀO TẠO DỰ ÁN — BẮT BUỘC THAM GIA',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9A3412)));

    // Đã xin vắng
    if (choice == 'DECLINE') {
      final duyet = status == 'APPROVED';
      final tuChoi = status == 'REJECTED';
      return khung(
        vien: duyet ? const Color(0xFF86EFAC) : (tuChoi ? const Color(0xFFFCA5A5) : const Color(0xFFFED7AA)),
        nen: duyet ? const Color(0xFFF0FDF4) : (tuChoi ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED)),
        con: [
          Row(children: [
            Icon(duyet ? Icons.verified_rounded : (tuChoi ? Icons.cancel_rounded : Icons.hourglass_top_rounded),
                size: 16, color: duyet ? const Color(0xFF15803D) : (tuChoi ? const Color(0xFFB91C1C) : const Color(0xFF9A3412))),
            const SizedBox(width: 6),
            Text(
              duyet ? 'Đã được duyệt vắng' : (tuChoi ? 'Lý do bị từ chối' : 'Chờ Admin duyệt lý do'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: duyet ? const Color(0xFF15803D) : (tuChoi ? const Color(0xFFB91C1C) : const Color(0xFF9A3412))),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Lý do bạn gửi: “${_traLoi?['reason'] ?? ''}”',
              style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475569))),
          if (_traLoi?['reviewNote'] != null && '${_traLoi?['reviewNote']}'.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Admin ghi: “${_traLoi?['reviewNote']}”',
                style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 8),
          Text(
            duyet
                ? 'Bạn được tính có điểm danh buổi này, không mất điểm đào tạo.'
                : (tuChoi
                    ? 'Bạn vẫn cần tham gia và quét mã điểm danh, nếu không sẽ bị tính vắng.'
                    : 'Được duyệt thì bạn vẫn được tính điểm danh mà không phải dự buổi này.'),
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
          ),
          if (tuChoi) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _dangGuiTraLoi ? null : _chonKhongThamGia,
                child: const Text('Gửi lại lý do khác'),
              ),
            ),
          ],
        ],
      );
    }

    // Đã chọn tham gia
    if (choice == 'JOIN') {
      return khung(
        vien: const Color(0xFF93C5FD),
        nen: const Color(0xFFEFF6FF),
        con: [
          nhan,
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF1D4ED8)),
            SizedBox(width: 6),
            Text('Bạn đã đăng ký tham gia',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
          ]),
          const SizedBox(height: 6),
          const Text('Nhớ quét mã điểm danh khi đến buổi học — đăng ký thôi thì chưa được tính.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _dangGuiTraLoi ? null : _chonKhongThamGia,
              child: const Text('Đổi sang xin vắng'),
            ),
          ),
        ],
      );
    }

    // Chưa trả lời
    return khung(
      vien: const Color(0xFFFED7AA),
      nen: const Color(0xFFFFF7ED),
      con: [
        nhan,
        const SizedBox(height: 6),
        const Text('Bạn có tham gia buổi này không?',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F2C59))),
        const SizedBox(height: 4),
        const Text('Không bán dự án này thì chọn “Không tham gia” và ghi rõ lý do để Admin duyệt.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _dangGuiTraLoi ? null : _chonThamGia,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Tham gia'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2C59),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _dangGuiTraLoi ? null : _chonKhongThamGia,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Không tham gia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9A3412),
                side: const BorderSide(color: Color(0xFFFDBA74), width: 1.3),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // Xác nhận kết thúc phòng học — hiện dialog đẹp với tóm tắt buổi học
  void _confirmEndSession() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                "Kết thúc buổi học?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2C59),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.room.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Tóm tắt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Học viên tham gia:", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(
                          "${widget.room.participants.length} người",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C59), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Mã phòng:", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(
                          widget.room.roomCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sau khi kết thúc, học viên sẽ không thể điểm danh thêm.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEnding ? null : () async {
                        // pop dialog first
                        Navigator.of(ctx).pop();
                        await _doEndSession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "KẾT THÚC",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doEndSession() async {
    setState(() => _isEnding = true);
    try {
      final success = await controller.endRoom(widget.room.id);
      if (success) {
        snack(
          "Thành công",
          "Buổi học \"${widget.room.title}\" đã kết thúc!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
        // Chờ 1.5 giây để user thấy thông báo rồi tự động thoát ra màn hình trước (DaoTaoView)
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Get.back(); 
        }
      } else {
        snack(
          "Lỗi",
          "Không thể kết thúc buổi học, vui lòng kiểm tra kết nối!",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      snack("Lỗi", "Có lỗi xảy ra: $e");
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  void _startRealScan() async {
    final user = authController.currentUser;
    final fullName = user['fullName'] ?? 'Nhân viên';
    final role = user['role'] ?? 'SALE';

    // Kiểm tra xem đã có tên trong phòng chưa
    final alreadyAttended = widget.room.participants.any((p) => p['name'] == fullName);
    if (alreadyAttended) {
      snack(
        "Thông báo",
        "Bạn đã điểm danh thành công lớp học này rồi!",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Mở màn hình quét QR thực tế và đợi kết quả trả về
    final scannedCode = await Get.to(() => const QrScannerView());

    if (scannedCode != null && scannedCode.toString().isNotEmpty) {
      String scannedCodeStr = scannedCode.toString();
      String extractedRoomCode = scannedCodeStr;
      if (scannedCodeStr.contains(":")) {
        extractedRoomCode = scannedCodeStr.split(":")[0];
      }
      
      // Kiểm tra mã quét được có khớp với mã phòng không
      if (extractedRoomCode != widget.room.roomCode) {
        snack(
          "Lỗi mã QR",
          "Mã QR bạn quét không thuộc về lớp học này. Vui lòng quét đúng mã hiển thị trên màn hình giảng viên!",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      setState(() {
        _isScanning = true;
      });

      // Bắn API điểm danh với mã hợp lệ
      final success = await controller.attendRoomByCode(scannedCode.toString());
      if (success) {
        // Cập nhật lại UI lập tức
        await controller.reloadRoomDetails(widget.room.id);
        try {
          final updatedRoom = controller.rooms.firstWhere((r) => r.id == widget.room.id);
          widget.room.participants.assignAll(updatedRoom.participants);
        } catch (_) {}

        final hasKpi = role == 'SALE' || role == 'TRUONG_PHONG';
        Get.defaultDialog(
          title: "Điểm danh thành công",
          middleText: hasKpi
              ? "Mã QR hợp lệ: ${widget.room.roomCode}\nĐã ghi nhận bạn tham gia lớp học. Nhận +5 điểm KPI tác phong!"
              : "Mã QR hợp lệ: ${widget.room.roomCode}\nĐã ghi nhận bạn tham gia lớp học thành công.",
          textConfirm: "Xác nhận",
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xFF0F2C59),
          onConfirm: () => Get.back(),
        );
      } else {
        snack(
          "Thất bại", 
          "Điểm danh không thành công. Hãy chắc chắn bạn chưa điểm danh và lớp chưa đầy.", 
          backgroundColor: Colors.red, 
          colorText: Colors.white,
          duration: const Duration(seconds: 4)
        );
      }

      setState(() {
        _isScanning = false;
      });
    }
  }

  // Hiển thị mã QR phòng học — token xoay mỗi 10s đồng bộ Web Admin
  void _showQrCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mã QR lớp học",
                    style: TextStyle(
                      color: Color(0xFF0F2C59),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QrTokenDisplay(
                roomCode: widget.room.roomCode,
                roomTitle: widget.room.title,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2C59),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("ĐÓNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = authController.currentUser['role'] ?? 'SALE';
    final isAdminOrManager = role == 'ADMIN' || role == 'TRUONG_PHONG';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2C59)),
        title: Text(
          widget.room.title,
          style: const TextStyle(
            color: Color(0xFF0F2C59),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Đào tạo dự án: hỏi tham gia hay xin vắng, đặt trước cả thông tin
            // buổi học vì đây là việc nhân sự cần làm ngay khi mở màn hình.
            if (widget.room.laDaoTaoDuAn && !isAdminOrManager) _khoiDangKy(),

            // Thông tin chi tiết phòng đào tạo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2C59).withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Mã lớp: ${widget.room.roomCode}",
                          style: const TextStyle(
                            color: Color(0xFFB8860B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.room.dateTime.day}/${widget.room.dateTime.month}/${widget.room.dateTime.year}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.room.title,
                    style: const TextStyle(
                      color: Color(0xFF0F2C59),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 8),
                      Text(
                        "Người thuyết trình: ${widget.room.presenter}",
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text(
                    "MÔ TẢ LỚP HỌC",
                    style: TextStyle(
                      color: Color(0xFF0F2C59),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.room.description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Các nút hành động
            Row(
              children: [
                if (isAdminOrManager) ...[ 
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showQrCodeDialog,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                      label: const Text(
                        "HIỂN THỊ MÃ QR PHÒNG",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _isScanning
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F2C59)))
                      : ElevatedButton.icon(
                          onPressed: _startRealScan,
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                          label: const Text(
                            "QUÉT ĐIỂM DANH DỰ LỚP",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2C59),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ),
              ],
            ),

            // Nút Kết thúc — chỉ hiện với Admin/TruongPhong và khi chưa kết thúc
            if (isAdminOrManager && widget.room.status != 'COMPLETED' && widget.room.status != 'CANCELLED') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmEndSession,
                  icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626), size: 20),
                  label: const Text(
                    "KẾT THÚC PHÒNG HỌC",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFFDC2626).withOpacity(0.04),
                  ),
                ),
              ),
            ],

            // Badge "Đã kết thúc" nếu status là COMPLETED
            if (widget.room.status == 'COMPLETED') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Buổi học đã kết thúc",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Danh sách người tham gia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "Học viên đã tham gia",
                      style: TextStyle(
                        color: Color(0xFF0F2C59),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _loadLatestData(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.refresh, size: 18, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2C59).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${widget.room.participants.length} người",
                    style: const TextStyle(
                      color: Color(0xFF0F2C59),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (widget.room.participants.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "Chưa có ai điểm danh",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.room.participants.length,
                itemBuilder: (context, index) {
                  final participant = widget.room.participants[index];
                  final name = participant['name'] ?? '';
                  final roleStr = participant['role'] ?? 'SALE';
                  final timeStr = participant['time'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0F2C59).withOpacity(0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF0F2C59),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        roleStr,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
