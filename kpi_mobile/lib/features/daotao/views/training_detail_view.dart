import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'qr_token_display.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestData();
    });
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
        Get.snackbar(
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
        Get.snackbar(
          "Lỗi",
          "Không thể kết thúc buổi học, vui lòng kiểm tra kết nối!",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Có lỗi xảy ra: $e");
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  void _simulateScan() async {
    final user = authController.currentUser;
    final fullName = user['fullName'] ?? 'Nhân viên';
    final role = user['role'] ?? 'SALE';

    // Kiểm tra xem đã có tên trong phòng chưa
    final alreadyAttended = widget.room.participants.any((p) => p['name'] == fullName);
    if (alreadyAttended) {
      Get.snackbar(
        "Thông báo",
        "Bạn đã điểm danh thành công lớp học này rồi!",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    // Giả lập quét camera mất 1.5 giây
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isScanning = false;
    });

    final success = await controller.attendRoomByCode(widget.room.roomCode);
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
      Get.snackbar(
        "Thất bại", 
        "Điểm danh không thành công. Hãy chắc chắn bạn chưa điểm danh và lớp chưa đầy.", 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        duration: const Duration(seconds: 4)
      );
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
                          onPressed: _simulateScan,
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
