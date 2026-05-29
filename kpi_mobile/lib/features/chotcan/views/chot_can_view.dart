import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chot_can_controller.dart';
import '../../../shared/widgets/history_date_list_view.dart';

class ChotCanView extends StatefulWidget {
  const ChotCanView({super.key});

  @override
  State<ChotCanView> createState() => _ChotCanViewState();
}

class _ChotCanViewState extends State<ChotCanView> with SingleTickerProviderStateMixin {
  final ChotCanController controller = Get.put(ChotCanController());

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  late AnimationController _animationController;
  final List<ConfettiParticle> _particles = [];
  bool _isCelebrating = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller cho hiệu ứng Confetti
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        if (_isCelebrating) {
          _updateParticles();
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _projectController.dispose();
    _unitController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _initParticles() {
    final random = Random();
    _particles.clear();
    for (int i = 0; i < 100; i++) {
      _particles.add(ConfettiParticle(
        x: random.nextDouble() * 400, // Sẽ được scale khi vẽ
        y: -random.nextDouble() * 200,
        color: Colors.primaries[random.nextInt(Colors.primaries.length)],
        size: random.nextDouble() * 8 + 4,
        speedY: random.nextDouble() * 3 + 2,
        speedX: random.nextDouble() * 4 - 2,
        rotation: random.nextDouble() * 360,
        rotationSpeed: random.nextDouble() * 10 - 5,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var p in _particles) {
        p.y += p.speedY;
        p.x += p.speedX;
        p.rotation += p.rotationSpeed;
        if (p.y > 800) {
          // Reset lên đầu
          p.y = -20;
          p.x = Random().nextDouble() * 400;
        }
      }
    });
  }

  void _registerDeal() async {
    if (!_formKey.currentState!.validate()) return;
    
    double dealValue = double.tryParse(_valueController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    final success = await controller.submitDeal(
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      project: _projectController.text,
      unitCode: _unitController.text,
      dealValue: dealValue,
    );

    if (success) {
      Get.snackbar(
        "Thành công",
        "Hồ sơ giao dịch đã gửi lên Admin phê duyệt thành công.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      _customerNameController.clear();
      _customerPhoneController.clear();
      _projectController.clear();
      _unitController.clear();
      _valueController.clear();
    } else {
      Get.snackbar("Lỗi", "Không thể gửi hồ sơ, vui lòng thử lại!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Column(
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
                      icon: Icon(Icons.domain_verification_rounded),
                      text: "CHỐT CĂN",
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

          // Hiệu ứng pháo giấy Confetti
          if (_isCelebrating)
            IgnorePointer(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: ConfettiPainter(particles: _particles),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return HistoryDateListView(
      onFetchHistory: (date) => controller.fetchHistory(date),
      emptyMessage: 'Không có yêu cầu chốt căn nào trong ngày này.',
      itemBuilder: (item, index) {
        final submittedAt = item['submittedAt'];
        final dateStr = formatIsoDate(submittedAt?.toString());
        final projectName = item['projectName'] ?? 'Dự án';
        final customerName = item['customerName'] ?? '';
        final unit = item['unit'] ?? item['unitCode'] ?? '';
        final status = item['status'] ?? 'PENDING';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F2C59).withOpacity(0.08),
              child: const Icon(Icons.home_work_rounded, color: Color(0xFF0F2C59), size: 22),
            ),
            title: Text(projectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                if (customerName.isNotEmpty)
                  Text('Khách: $customerName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (unit.isNotEmpty)
                  Text('Căn: $unit', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Ngày: $dateStr',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F2C59), fontWeight: FontWeight.w600)),
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
              // Form đăng ký
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
                        "Đăng ký giao dịch chốt căn",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Khai báo thông tin khách hàng và mã căn hộ đã cọc giữ chỗ để gửi Admin kiểm duyệt và cập nhật KPI doanh số.",
                        style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                      ),
                      const Divider(height: 24),

                      // Tên khách hàng mua
                      const Text("TÊN KHÁCH HÀNG MUA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _customerNameController,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: Nguyễn Văn Khách...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập tên khách mua" : null,
                      ),
                      const SizedBox(height: 16),

                      // Số điện thoại khách hàng
                      const Text("SỐ ĐIỆN THOẠI KHÁCH HÀNG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: 0987654321...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập số điện thoại" : null,
                      ),
                      const SizedBox(height: 16),

                      // Tên Dự án
                      const Text("DỰ ÁN PHÂN PHỐI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _projectController,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: Trí Long Land Townhouse...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập tên dự án" : null,
                      ),
                      const SizedBox(height: 16),

                      // Mã căn hộ chốt
                      const Text("MÃ CĂN HỘ / BLOCK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: Block B - Căn B18-04...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập mã căn" : null,
                      ),
                      const SizedBox(height: 16),

                      // Giá trị giao dịch
                      const Text("GIÁ TRỊ GIAO DỊCH (VNĐ)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B3B6F))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Ví dụ: 1.800.000.000...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập giá trị hợp đồng" : null,
                      ),
                      const SizedBox(height: 24),

                      Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoading.value ? null : _registerDeal,
                        icon: controller.isLoading.value 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_outlined, color: Colors.white),
                        label: Text(
                          controller.isLoading.value ? "ĐANG GỬI..." : "ĐĂNG KÝ CHỐT CĂN",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2C59),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
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

// Particle Model
class ConfettiParticle {
  double x;
  double y;
  Color color;
  double size;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// Confetti Custom Painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      // Scale to current viewport width
      double drawX = p.x % size.width;
      
      canvas.save();
      canvas.translate(drawX, p.y);
      canvas.rotate(p.rotation * pi / 180);
      
      // Draw rectangular confetti piece
      canvas.drawRect(Rect.fromLTWH(-p.size / 2, -p.size / 2, p.size, p.size * 0.6), paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
