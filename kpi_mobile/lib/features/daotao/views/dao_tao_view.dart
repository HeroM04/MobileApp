import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'training_detail_view.dart';
import 'qr_token_display.dart';
import 'dao_tao_1_on_1_view.dart';
import '../../../shared/widgets/history_date_list_view.dart';

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
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Color(0xFF0F2C59),
              labelColor: Color(0xFF0F2C59),
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  icon: Icon(Icons.school_rounded),
                  text: "PHÒNG ĐÀO TẠO",
                ),
                Tab(
                  icon: Icon(Icons.history_rounded),
                  text: "LỊCH SỬ HỌC",
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSubmitTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return HistoryDateListView(
      onFetchHistory: (date) => controller.fetchHistory(date),
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
                      const Text(
                        "Trung tâm Đào tạo Trí Long",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
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
                        backgroundColor: const Color(0xFFE11D48), // Red/Pink accent color
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Hãy lựa chọn phòng đào tạo đang diễn ra bên dưới để xem thông tin chi tiết, quét mã QR điểm danh chuyên cần (+5 điểm KPI tác phong).",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Danh sách phòng đào tạo
            const Text(
              "Phòng học đang diễn ra",
              style: TextStyle(
                color: Color(0xFF0F2C59),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (controller.rooms.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: const [
                        Icon(Icons.class_outlined, size: 50, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "Chưa có lớp đào tạo nào được tạo",
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F2C59).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Mã: ${room.roomCode}",
                                  style: const TextStyle(
                                    color: Color(0xFF0F2C59),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
                              Text(
                                "Thời gian: ${room.dateTime.hour.toString().padLeft(2, '0')}:${room.dateTime.minute.toString().padLeft(2, '0')} - ${room.dateTime.day}/${room.dateTime.month}/${room.dateTime.year}",
                                style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
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
}
