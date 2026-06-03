import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../home/controllers/kpi_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/thuc_chien_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';

class ThucChienView extends StatefulWidget {
  const ThucChienView({super.key});

  @override
  State<ThucChienView> createState() => _ThucChienViewState();
}

class _ThucChienViewState extends State<ThucChienView> {
  final KpiController kpiController = Get.put(KpiController());
  final AuthController authController = Get.find<AuthController>();
  final ThucChienController controller = Get.put(ThucChienController());
  final ImagePicker _picker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  
  File? _selectedImage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // Nếu chạy trên Desktop, chọn thẳng từ thư viện tệp
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await _executePick(ImageSource.gallery);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Chọn ảnh xác thực thực địa",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD4AF37)),
              title: const Text("Chụp ảnh từ Camera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _executePick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFD4AF37)),
              title: const Text("Chọn từ Thư viện ảnh (Khuyên dùng cho test)", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _executePick(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _executePick(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {

        // Lấy GPS & địa chỉ TRƯỚC khi vẽ watermark
        await controller.getCurrentLocationAndAddress();

        // Vẽ watermark timestamp + địa chỉ lên ảnh
        final watermarkedFile = await _addWatermark(File(image.path));

        setState(() {
          _selectedImage = watermarkedFile;
        });

        Get.snackbar(
          "Ảnh đã ghi nhận",
          "Đã gắn thời gian & địa điểm vào ảnh.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể chụp ảnh: $e");
    }
  }

  /// Vẽ watermark mô phỏng Timemark
  Future<File> _addWatermark(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Tối ưu dung lượng: Giảm độ phân giải ảnh xuống tối đa 1200px chiều rộng
      double scale = 1.0;
      if (originalImage.width > 1200) {
        scale = 1200 / originalImage.width;
        canvas.scale(scale, scale);
      }

      canvas.drawImage(originalImage, Offset.zero, Paint());

      final now = DateTime.now();
      final hourStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      
      final List<String> weekdays = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
      final weekdayStr = weekdays[now.weekday == 7 ? 0 : now.weekday];
      
      final address = controller.currentAddress.value.isNotEmpty ? controller.currentAddress.value : 'Đang xác định vị trí...';
      
      final user = authController.currentUser;
      final name = user['fullName'] ?? 'Không rõ';
      final dept = user['departmentName'] ?? 'Không rõ';

      final double startX = 24.0;
      // Anchor watermark near the bottom
      double startY = originalImage.height - 450.0;
      if (startY < 0) startY = 24.0;

      // 1. LOGO TRÍ LONG LAND
      final logoSpan = TextSpan(
        text: 'TRÍ LONG LAND\n',
        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
        children: const [
          TextSpan(text: 'KIẾN TẠO SỰ BỀN VỮNG', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
        ],
      );
      final logoPainter = TextPainter(text: logoSpan, textDirection: TextDirection.ltr);
      logoPainter.layout();
      logoPainter.paint(canvas, Offset(startX, startY));
      startY += logoPainter.height + 20;

      // 2. TIME | DATE
      final timeSpan = TextSpan(
        children: [
          TextSpan(text: '$hourStr ', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
          TextSpan(text: '| ', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 50, fontWeight: FontWeight.w300)),
          TextSpan(text: '$dateStr\n', style: const TextStyle(color: Colors.white, fontSize: 24)),
          TextSpan(text: '         $weekdayStr', style: const TextStyle(color: Colors.white, fontSize: 22)),
        ],
        style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 6)], height: 1.1),
      );
      final timePainter = TextPainter(text: timeSpan, textDirection: TextDirection.ltr);
      timePainter.layout();
      timePainter.paint(canvas, Offset(startX, startY));
      startY += timePainter.height + 20;

      // 3. ADDRESS
      final addressSpan = TextSpan(
        text: address,
        style: const TextStyle(color: Colors.white, fontSize: 22, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
      );
      final addressPainter = TextPainter(text: addressSpan, textDirection: TextDirection.ltr, maxLines: 3);
      addressPainter.layout(maxWidth: originalImage.width - 48.0);
      addressPainter.paint(canvas, Offset(startX, startY));
      startY += addressPainter.height + 20;

      // 4. GREY BOX (Company, Name, Room)
      final boxPaint = Paint()..color = Colors.white.withOpacity(0.25);
      final infoSpan = TextSpan(
        text: 'Công ty: Trí Long Land\nHọ tên: $name\nPhòng: $dept',
        style: const TextStyle(color: Colors.white, fontSize: 24, height: 1.6, shadows: [Shadow(color: Colors.black, blurRadius: 3)]),
      );
      final infoPainter = TextPainter(text: infoSpan, textDirection: TextDirection.ltr);
      infoPainter.layout();
      
      final boxRect = RRect.fromLTRBR(startX, startY, startX + infoPainter.width + 40, startY + infoPainter.height + 24, const Radius.circular(12));
      canvas.drawRRect(boxRect, boxPaint);
      infoPainter.paint(canvas, Offset(startX + 20, startY + 12));

      // 5. TIMEMARK (Bottom Right)
      final tmSpan = TextSpan(
        text: 'Timemark\n',
        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
        children: const [
          TextSpan(text: '100% Chân thực', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal)),
        ],
      );
      final tmPainter = TextPainter(text: tmSpan, textDirection: TextDirection.ltr, textAlign: TextAlign.right);
      tmPainter.layout();
      tmPainter.paint(canvas, Offset(originalImage.width - tmPainter.width - 30, originalImage.height - tmPainter.height - 30));

      final picture = recorder.endRecording();
      final img = await picture.toImage((originalImage.width * scale).toInt(), (originalImage.height * scale).toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      final dir = await getTemporaryDirectory();
      final outFile = File('${dir.path}/wm_${DateTime.now().millisecondsSinceEpoch}.png');
      await outFile.writeAsBytes(pngBytes!.buffer.asUint8List());
      return outFile;
    } catch (e) {
      print('[ThucChien] Lỗi watermark: $e');
      return originalFile;
    }
  }


  void _submitMeeting() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      Get.snackbar("Lỗi", "Vui lòng chụp ảnh gặp mặt khách hàng tại thực địa!");
      return;
    }

    // Optimistic UI: gọi hàm mới — phản hồi ngay, API chạy ngầm
    controller.submitMeetingOptimistic(
      name: "",
      phone: "",
      project: "",
      content: _contentController.text,
      imagePath: _selectedImage!.path,
      onSuccess: () {
        // Reset form NGAY LẬP TỨC (<200ms), không chờ API
        setState(() {
          _contentController.clear();
          _selectedImage = null;
        });
      },
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
                  icon: Icon(Icons.groups_rounded),
                  text: "THỰC CHIẾN",
                ),
                Tab(
                  icon: Icon(Icons.history_rounded),
                  text: "LỊCH SỬ GỬI",
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
      emptyMessage: 'Không có báo cáo thực chiến nào trong ngày này.',
      itemBuilder: (item, index) {
        final submittedAt = item['submittedAt'];
        final dateStr = formatIsoDate(submittedAt?.toString());
        final customer = item['customerName'] ?? 'Khách hàng';
        final project = item['project'] ?? 'Chưa rõ';
        final status = item['status'] ?? 'PENDING';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F2C59).withOpacity(0.08),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF0F2C59), size: 22),
            ),
            title: Text('Thực chiến $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Nội dung: ${item['content'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Ngày: $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF0F2C59), fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel(status),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor(status)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.offlineDrafts.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Đang lưu ngoại tuyến (${controller.offlineDrafts.length} cuộc gặp)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.isSyncing.value
                                ? "Đang tự động đồng bộ lên server..."
                                : "Hệ thống sẽ tự động đồng bộ khi phát hiện mạng ổn định.",
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isSyncing.value)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2C59).withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ghi nhận gặp khách hàng",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                  ),
                  const Divider(height: 24),

                  // Nội dung trao đổi
                  const Text("NỘI DUNG TRAO ĐỔI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Nội dung nhu cầu khách hàng, thời gian hẹn tiếp theo...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Vui lòng ghi nhận nội dung trao đổi" : null,
                  ),
                  const SizedBox(height: 20),

                  // Đính kèm ảnh thực tế
                  const Text("ẢNH CHỤP GẶP MẶT TẠI THỰC ĐỊA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 48, color: const Color(0xFFD4AF37).withOpacity(0.7)),
                                const SizedBox(height: 8),
                                const Text("Chạm chụp ảnh check-in thực tế", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                                const Text("(Yêu cầu xuất hiện cả Sale và khách)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            )
                          : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút submit — luôn hiển thị vì Optimistic UI không block màn hình
                  ElevatedButton.icon(
                    onPressed: _submitMeeting,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text(
                      "GỬI BÁO CÁO GẶP MẶT",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2C59),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
