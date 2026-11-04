import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'training_detail_view.dart';
import 'qr_token_display.dart';
import 'dao_tao_1_on_1_view.dart';
import 'training_archive_view.dart';
import '../../../shared/widgets/history_date_list_view.dart';
import '../../../data/services/lich_su_thang.dart';
import '../../../core/utils/dong_bo.dart';

class DaoTaoView extends StatefulWidget {
  const DaoTaoView({super.key});

  @override
  State<DaoTaoView> createState() => _DaoTaoViewState();
}

class _DaoTaoViewState extends State<DaoTaoView> {
  final TrainingController controller = Get.put(TrainingController());
  final AuthController authController = Get.find<AuthController>();

  // Dialog Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _presenterController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _presenterController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // Mở dialog tạo phòng học mới — dùng showDialog native thay Get.dialog để tránh freeze Windows
  void _showCreateRoomDialog() {
    _presenterController.text = authController.currentUser['fullName'] ?? '';
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    _codeController.text = "TL_TRAIN_ROOM_$uniqueSuffix";
    _titleController.clear();
    _descController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Tạo phòng đào tạo mới",
          style: TextStyle(
            color: Color(0xFF0F2C59),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TÊN PHÒNG ĐÀO TẠO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: "Ví dụ: Kỹ năng giao tiếp khách hàng",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập tên phòng học" : null,
                ),
                const SizedBox(height: 14),
                const Text("DIỄN GIẢ / NGƯỜI HƯỚNG DẪN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _presenterController,
                  decoration: InputDecoration(
                    hintText: "Nhập tên diễn giả",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập tên người hướng dẫn" : null,
                ),
                const SizedBox(height: 14),
                const Text("MÃ PHÒNG (TOKEN)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: "Mã phòng học điểm danh",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập mã phòng học" : null,
                ),
                const SizedBox(height: 14),
                const Text("MÔ TẢ NỘI DUNG", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Mô tả sơ lược về nội dung bài học...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập mô tả phòng" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("HỦY BỎ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              // Lưu giá trị vào local variable TRƯỚC khi đóng dialog
              final title = _titleController.text.trim();
              final desc = _descController.text.trim();
              final presenter = _presenterController.text.trim();
              final code = _codeController.text.trim();
              final now = DateTime.now();

              Navigator.of(ctx).pop(); // Đóng dialog bằng native navigator

              // Hiện loading indicator trên màn hình chính
              final room = await controller.createRoom(title, desc, presenter, code, now);

              if (!mounted) return;

              if (room != null) {
                _showQrAfterCreate(room);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Không thể tạo phòng học. Vui lòng thử lại."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2C59),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("TẠO PHÒNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Hiển thị QR của phòng vừa tạo — token xoay mỗi 10s đồng bộ Web Admin
  void _showQrAfterCreate(TrainingRoom room) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Phòng đã được tạo!",
                    style: TextStyle(
                      color: Color(0xFF0F2C59),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              QrTokenDisplay(
                roomCode: room.roomCode,
                roomTitle: room.title,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("ĐÓNG", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Get.to(() => TrainingDetailView(room: room));
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      label: const Text("VÀO PHÒNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2C59),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Color(0xFF0F2C59),
              labelColor: Color(0xFF0F2C59),
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  icon: Icon(Icons.school_rounded),
                  text: "PHÒNG HỌC",
                ),
                Tab(
                  icon: Icon(Icons.history_rounded),
                  text: "LỊCH SỬ",
                ),
                Tab(
                  icon: Icon(Icons.video_library_rounded),
                  text: "KHO VIDEO",
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSubmitTab(),
                _buildHistoryTab(),
                const TrainingArchiveView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Lịch sử có hai loại: buổi đào tạo chung đã điểm danh QR, và báo cáo đào
  // tạo 1-1 tự nộp. Trước đây chỉ có loại đầu — nộp 1-1 xong là mất dấu, không
  // biết báo cáo đang chờ duyệt, đã duyệt hay bị từ chối.
  bool _xem1Kem1 = false;

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _chonLoaiLichSu(),
        Expanded(child: _xem1Kem1 ? _lichSu1Kem1() : _lichSuBuoiHoc()),
      ],
    );
  }

  Widget _chonLoaiLichSu() {
    Widget nut(String chu, IconData icon, bool la1Kem1) {
      final chon = _xem1Kem1 == la1Kem1;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _xem1Kem1 = la1Kem1),
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
                Icon(icon, size: 16, color: chon ? const Color(0xFF0F2C59) : Colors.grey),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(chu,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: chon ? FontWeight.bold : FontWeight.w600,
                        color: chon ? const Color(0xFF0F2C59) : Colors.grey,
                      )),
                ),
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
        nut('Buổi học', Icons.school_rounded, false),
        nut('Đào tạo 1-1', Icons.people_alt_rounded, true),
      ]),
    );
  }

  Widget _lichSu1Kem1() {
    return HistoryDateListView(
      key: const ValueKey('lich-su-1-kem-1'),
      onFetchHistory: (date) => controller.fetchLichSu1Kem1(date),
      onFetchMonth: (month) => taiLichSuThang('/training/1-on-1/my', month),
      thoiDiemCua: (item) => item['submittedAt']?.toString(),
      emptyMessageThang: 'Không có báo cáo đào tạo 1-1 nào trong tháng này.',
      loaiDongBo: DongBo.daoTao,
      emptyMessage: 'Không có báo cáo đào tạo 1-1 nào trong ngày này.',
      itemBuilder: (item, index) {
        final status = item['status']?.toString() ?? 'PENDING';
        final anh = item['photoUrl']?.toString() ?? '';
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _xemBaoCao1Kem1(item),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: anh.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(anh, width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.people_alt_rounded, color: Color(0xFF0F2C59))),
                  )
                : CircleAvatar(
                    backgroundColor: const Color(0xFF0F2C59).withOpacity(0.08),
                    child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0F2C59), size: 22),
                  ),
            title: Text(item['content']?.toString() ?? '',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              // Danh sách đã gom theo ngày (ô chọn ngày / tiêu đề ngày) nên chỉ cần giờ
              child: Text('Nộp lúc ${_gioNop(item['submittedAt'])}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F2C59), fontWeight: FontWeight.w600)),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel(status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor(status))),
            ),
          ),
        );
      },
    );
  }

  String _gioNop(Object? iso) {
    final dt = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Xem đủ nội dung, ảnh và trạng thái của một báo cáo 1-1 đã nộp.
  void _xemBaoCao1Kem1(Map<String, dynamic> item) {
    final status = item['status']?.toString().toUpperCase() ?? 'PENDING';
    final anh = item['photoUrl']?.toString() ?? '';
    final yNghia = switch (status) {
      'APPROVED' => 'Admin đã duyệt — điểm Thực chiến đã được cộng (xem khoản điểm ở mục Thông báo).',
      'REJECTED' => 'Admin không duyệt báo cáo này nên không được cộng điểm.',
      _ => 'Đang chờ Admin duyệt. Duyệt xong mới được cộng điểm Thực chiến.',
    };
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Báo cáo đào tạo 1-1',
          style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold, fontSize: 17)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nộp lúc: ${formatIsoDate(item['submittedAt']?.toString())}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(yNghia, style: TextStyle(fontSize: 12.5, height: 1.4, color: statusColor(status))),
            ),
            const SizedBox(height: 12),
            Text(item['content']?.toString() ?? '', style: const TextStyle(fontSize: 14, height: 1.45)),
            if (anh.isNotEmpty) ...[
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

  Widget _lichSuBuoiHoc() {
    return HistoryDateListView(
      key: const ValueKey('lich-su-buoi-hoc'),
      onFetchHistory: (date) => controller.fetchHistory(date),
      onFetchMonth: (month) => taiLichSuThang('/training-sessions/my-trainings', month),
      thoiDiemCua: (item) => item['attendedAt']?.toString(),
      emptyMessageThang: 'Không có buổi đào tạo nào trong tháng này.',
      loaiDongBo: DongBo.daoTao,
      emptyMessage: 'Không có buổi đào tạo nào trong ngày này.',
      itemBuilder: (item, index) {
        final attendedAt = item['attendedAt'];
        final dateStr = formatIsoDate(attendedAt?.toString());
        final session = item['session'] as Map<String, dynamic>? ?? {};
        final sessionTitle = session['title'] ?? item['sessionTitle'] ?? 'Buổi đào tạo';
        final presenter = session['presenter'] ?? item['presenter'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F2C59).withOpacity(0.08),
              child: const Icon(Icons.school_rounded, color: Color(0xFF0F2C59), size: 22),
            ),
            title: Text(sessionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (presenter.isNotEmpty)
                  Text('Giảng viên: $presenter', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Ngày tham gia: $dateStr',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F2C59), fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
          ),
        );
      },
    );
  }

  Widget _buildSubmitTab() {
    final role = authController.currentUser['role'] ?? 'SALE';
    final isAdminOrManager = role == 'ADMIN' || role == 'TRUONG_PHONG';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner giới thiệu mô-đun
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2C59), Color(0xFF1B3B6F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2C59).withOpacity(0.1),
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
                      const Icon(Icons.school, color: Color(0xFFD4AF37), size: 24),
                      const SizedBox(width: 8),
                      // Expanded thay Spacer: tiêu đề dài / chữ to thì xuống dòng, nút "Tạo phòng" vẫn trong khung
                      const Expanded(
                        child: Text(
                          "Trung tâm Đào tạo Trí Long",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isAdminOrManager)
                        ElevatedButton.icon(
                          onPressed: _showCreateRoomDialog,
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF0F2C59)),
                          label: const Text(
                            "TẠO PHÒNG",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => DaoTao1On1View()),
                      icon: const Icon(Icons.people_alt, size: 16, color: Colors.white),
                      label: const Text(
                        "BÁO CÁO ĐÀO TẠO 1-1 (+5 KPI)",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Hãy lựa chọn phòng đào tạo đang diễn ra bên dưới để xem thông tin chi tiết, quét mã QR để điểm danh. Dự đủ các buổi bắt buộc trong tuần được +15 điểm (chốt sau 23:00 Chủ nhật).",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Danh sách buổi đào tạo của tuần này
            const Text(
              "Lịch đào tạo tuần này",
              style: TextStyle(
                color: Color(0xFF0F2C59),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Đang diễn ra xếp trên, rồi tới sắp diễn ra, cuối cùng là đã kết thúc.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (controller.rooms.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: const [
                        Icon(Icons.event_available_outlined, size: 50, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "Tuần này chưa có buổi đào tạo nào",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.rooms.length,
                itemBuilder: (context, index) {
                  final room = controller.rooms[index];
                  return GestureDetector(
                    onTap: () => Get.to(() => TrainingDetailView(room: room)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2C59).withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _nhanTrangThai(room),
                              Row(
                                children: [
                                  const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${room.participants.length} học viên",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            room.title,
                            style: const TextStyle(
                              color: Color(0xFF0F2C59),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Người hướng dẫn: ${room.presenter}",
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            room.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _khoangGio(room),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: const [
                                  Text(
                                    "Xem chi tiết",
                                    style: TextStyle(
                                      color: Color(0xFF0F2C59),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF0F2C59)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Nhãn trạng thái của buổi học, thay cho mã phòng ở góc trái thẻ.
  ///
  /// Dùng `displayStatus` do máy chủ tính theo đồng hồ, nên đến giờ học là thẻ
  /// tự đổi sang "Đang diễn ra" mà không cần Admin bấm gì.
  static Widget _nhanTrangThai(TrainingRoom room) {
    late final String chu;
    late final Color nen;
    late final Color mucChu;
    late final IconData bieuTuong;

    if (room.dangDienRa) {
      chu = 'Đang diễn ra';
      nen = const Color(0xFF16A34A).withOpacity(0.12);
      mucChu = const Color(0xFF15803D);
      bieuTuong = Icons.play_circle_fill_rounded;
    } else if (room.daKetThuc) {
      chu = 'Đã kết thúc';
      nen = const Color(0xFF94A3B8).withOpacity(0.14);
      mucChu = const Color(0xFF64748B);
      bieuTuong = Icons.check_circle_outline_rounded;
    } else {
      chu = 'Sắp diễn ra';
      nen = const Color(0xFF0F2C59).withOpacity(0.08);
      mucChu = const Color(0xFF0F2C59);
      bieuTuong = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: nen, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(bieuTuong, size: 12, color: mucChu),
          const SizedBox(width: 5),
          Text(chu,
              style: TextStyle(color: mucChu, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  /// "Thứ Năm 20/08 · 09:00 – 11:00" — có giờ kết thúc thì hiện cả khoảng.
  static String _khoangGio(TrainingRoom room) {
    const thu = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];
    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final b = room.dateTime.toLocal();
    final ngay = '${thu[b.weekday - 1]} ${b.day.toString().padLeft(2, '0')}/${b.month.toString().padLeft(2, '0')}';
    final k = room.endTime == null
        ? hhmm(b)
        : '${hhmm(b)} – ${hhmm(room.endTime!.toLocal())}';
    return '$ngay · $k';
  }
}
